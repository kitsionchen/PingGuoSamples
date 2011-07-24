#import "RetryingHTTPOperation.h"
#import "NetworkManager.h"
#import "logging.h"
#import "QHTTPOperation.h"
#import "QReachabilityOperation.h"

/*
 * When one operation completes it posts the following notification. Other 
 * operations listen for that notification and, if the host name matches, 
 * expendite their retry. This means that. if one request succeeds, subsequent
 * requests will retry quickly.
 */
static NSString * kRetryingHTTPOperationTransferDidSucceedNotifcation = 
@"com.apple.dts.kRetryingHTTPOperationTransferDidSucceedNotification";

static NSString * kRetryingHTTPOperationTransferDidSucceedHostKey = @"hostName";

@interface RetryingHTTPOperation () 

@property (assign, readwrite) RetryingHTTPOperationState retryState;
@property (assign, readwrite) RetryingHTTPOperationState retryStateClient;
@property (assign, readwrite) BOOL hasHadRetryableFailure;
@property (assign, readwrite) NSUInteger retryCount;
@property (copy, readwrite) NSData *responseContent;

@property (copy, readwrite) NSHTTPURLResponse *response;
@property (retain, readwrite) QHTTPOperation *networkOperation;
@property (retain, readwrite) NSTimer *retryTimer;
@property (retain, readwrite) QReachabilityOperation *reachabilityOperation;
@property (assign, readwrite) BOOL notificationInstalled;

- (void)startRequest;
- (void)startReachabilityReachable:(BOOL)reachable;
- (void)startRetryAfterTimeInterval:(NSTimeInterval)delay;

@end

@implementation RetryingHTTPOperation

- (id)initWithRequest:(NSURLRequest *)request {
    assert(request != nil);
#if ! defined (NDEBUG)
    static NSSet *sIdempotentHTTPMethods;
    
    if (sIdempotentHTTPMethods == nil) {
        @synchronized([self class]) {
            if (sIdempotentHTTPMethods == nil) {
                sIdempotentHTTPMethods = [[NSSet alloc] initWithObjects:@"GET",
                                          @"HEAD", @"PUT", @"DELETE", @"OPTIONS",
                                          @"TRACE", nil];
            }
        }
    }
    assert([sIdempotentHTTPMethods containsObject:[request HTTPMethod]]);
#endif
    
    self = [super init];
    if (self != nil) {
        @synchronized([self class]) {
            static NSUInteger sSequenceNumber;
            self->_sequenceNumber = sSequenceNumber;
            sSequenceNumber += 1;
        }
        self->_request = [request copy];
        assert(self->_retryState == kRetryingHTTPOperationStateNotStarted);
    }
    return self;
}

- (void)dealloc {
    [self->_request release];
    [self->_acceptableContentTypes release];
    [self->_responseFilePath release];
    [self->_response release];
    [self->_responseContent release];
    
    assert(self->_networkOperation == nil);
    assert(self->_retryTimer == nil);
    assert(self->_reachabilityOperation == nil);
    [super dealloc];
}

#pragma mark * Properties

@synthesize request = _request;

- (RetryingHTTPOperationState)retryState {
    return self->_retryState;
}

- (void)setRetryState:(RetryingHTTPOperationState)v {
    assert([self isActualRunLoopThread]);
    assert(v != self->_retryState);
    self->_retryState = v;
    [self performSelectorOnMainThread:@selector(syncRetryStateClient) 
                           withObject:nil 
                        waitUntilDone:NO];
    
}

@synthesize retryStateClient = retryStateClient;

- (void)syncRetryStateClient {
    assert([NSThread isMainThread]);
    self.retryStateClient = self.retryState;
}

@synthesize hasHadRetryableFailure = _hasHadRetryableFailure;
@synthesize acceptableContentTypes = _acceptableContentTypes;
@synthesize responseFilePath = _responseFilePath;
@synthesize response = _response;
@synthesize networkOperation = _networkOperation;
@synthesize retryTimer = _retryTimer;
@synthesize retryCount = _retryCount;
@synthesize reachabilityOperation = _reachabilityOperation;
@synthesize notificationInstalled = _notificationInstalled;

- (NSString *)responseMIMEType {
    NSString *result;
    NSHTTPURLResponse *aResponse;
    result = nil;
    aResponse = self.response;
    if (aResponse != nil) {
        result = [aResponse MIMEType];
    }
    return result;
}

@synthesize responseContent = _responseContent;

#pragma mark * Utilities

- (void)setHashadRetryableFailureOnMainThread {
    assert([NSThread isMainThread]);
    assert(!self.hasHadRetryableFailure);
    self.hasHadRetryableFailure = YES;
}

/*
 * Returns YES if the supplied error is fatal, that is, it can be meaningfully
 * retried.
 */
- (BOOL)shouldRetryAfterError:(NSError *)error {
    BOOL shouldRetry;
    
    if ([[error domain] isEqual:kQHTTPOperationErrorDomain]) {
        if ([error code] > 0) {
            shouldRetry = NO;
        } else {
            switch ([error code]) {
                case kQHTTPOperationErrorOutputStream:
                case kQHTTPOperationErrorResponseTooLarge:
                case kQHTTPOperationErrorBadContentType : {
                    shouldRetry = NO;
                }
                break;
            }
        }
    } else {
        shouldRetry = YES;
    }
    return shouldRetry;
}

#pragma mark * Core state transitions

- (void)operationDidStart {
    assert([self isActualRunLoopThread]);
    assert(self.retryState == kRetryingHTTPOperationStateNotStarted);
    
    [super operationDidStart];
    
    [[QLog log] logOption:kLogOptionSyncDetails withFormat:@"http %zu start %@",
     (size_t)self->_sequenceNumber, [self.request URL]];
    self.retryState = kRetryingHTTPOperationStateGetting;
    [self startRequest];
}

- (void)startRequest {
    assert([self isActualRunLoopThread]);
    assert((self.retryState == kRetryingHTTPOperationStateGetting) || 
           (self.retryState == kRetryingHTTPOperationStateRetrying));
    assert(self.networkOperation == nil);
    [[QLog log] logOption:kLogOptionNetworkDetails 
               withFormat:@"http %zu request start", (size_t)self->_sequenceNumber];
    
    self.networkOperation = [[[QHTTPOperation alloc] 
                              initWithRequest:self.request] autorelease];
    assert(self.networkOperation != nil);
    
    // copy our properties over to the network operation
    [self.networkOperation setQueuePriority:[self queuePriority]];
    self.networkOperation.acceptableContentTypes = self.acceptableContentTypes;
    self.networkOperation.runLoopThread = self.runLoopThread;
    self.networkOperation.runLoopModes = self.runLoopModes;
    
    if (self.responseFilePath != nil) {
        self.networkOperation.responseOutputStream = 
        [NSOutputStream outputStreamToFileAtPath:self.responseFilePath 
                                          append:NO];
        
        assert(self.networkOperation.responseOutputStream != nil);
    }
    
    [[NetworkManager shardManager] 
     addNetworkTransferOperation:self.networkOperation 
     finishedTarget:self
     action:@selector(networkOperationDone:)];
}

- (void)networkOperationDone:(QHTTPOperation *)operation {
    
}
@end
