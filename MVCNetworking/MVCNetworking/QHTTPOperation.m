#import "QHTTPOperation.h"

@interface QHTTPOperation () 

@property (copy, readwrite) NSURLRequest *lastRequest;
@property (copy, readwrite) NSHTTPURLResponse *lastResponse;

@property (retain, readwrite) NSURLConnection *connection;
@property (assign, readwrite) BOOL firstData;
@property (retain, readwrite) NSMutableData *dataAccumulator;

#if ! defined (NDEBUG)
@property (retain, readwrite) NSTimer *debugDelayTimer;
#endif

@end

@implementation QHTTPOperation

#pragma mark * Initialise and finalise

- (id)initWithRequest:(NSURLRequest *)request {
    assert(request != nil);
    assert([request URL] != nil);
    assert([[[[request URL] scheme] lowercaseString] isEqual:@"http"] || 
           [[[[request URL] scheme] lowercaseString] isEqual:@"https"]);
    
    self = [super init];
    if (self != nil) {
        #if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
            static const NSUInteger kPlatformReductionFactor = 4;
        #else 
            static const NSUInteger kPlatformReductionFactor = 1;
        #endif
        self->_request = [request copy];
        self->_defaultResponseSize = 1 * 1024 * 1024 / kPlatformReductionFactor;
        self->_maximumResponseSize = 4 * 1024 * 1024 / kPlatformReductionFactor;
        self->_firstData = YES;
    }
    return self;
}

- (id)initwithURL:(NSURL *)url {
    assert(url != nil);
    return [self initWithRequest:[NSURLRequest requestWithURL:url]];
}

- (void)dealloc {
#if ! defined (NDEBUG)
    [self->_debugError release];
    [self->_debugDelayTimer invalidate];
    [self->_debugDelayTimer release];
#endif
    
    [self->_request release];
    [self->_acceptableStatusCodes release];
    [self->_acceptableContentTypes release];
    [self->_responseOutputStream release];
    
    assert(self->_connection == nil);
    [self->_dataAccumulator release];
    [self->_lastRequest release];
    [self->_lastResponse release];
    [self->_responseBody release];
    [super dealloc];
}

#pragma mark * Properties

/*
 * We write our own settings for many properties because we want to bounce
 * sets that occur in the wrong state. And, given that we have written the 
 * stter anyway, we also avoid KVO notification when the value doesn't change.
 */
@synthesize request = _request;
@synthesize authenticationDelegate = _authenticationDelegate;
+ (BOOL)automaticallyNOtifiesobserversOfAuthenticationDelegate {
    return NO;
}

- (id<QHTTPOperationAuthenticationDelegate>)authenticationDelegate {
    return self->_authenticationDelegate;
}

- (void)setAuthenticationDelegate:(id<QHTTPOperationAuthenticationDelegate>)v {
    if (self.state != kQRunLoopOperationStateInited) {
        assert(NO);
    } else {
        if (v != self->_authenticationDelegate) {
            [self willChangeValueForKey:@"authenticationDelegate"];
            self->_authenticationDelegate = v;
            [self didChangeValueForKey:@"authenticationDelegate"];
        }
    }
}

@synthesize acceptableStatusCodes = _acceptableStatusCodes;

+ (BOOL)automaticallyNotifiesObserversOfAcceptableStatusCodes {
    return NO;
}

- (NSIndexSet *)acceptableStatusCodes {
    return [[self->_acceptableStatusCodes retain] autorelease];
}

- (void)setAcceptableStatusCodes:(NSIndexSet *)v {
    if (self.state != kQRunLoopOperationStateInited) {
        assert(NO);
    } else {
        if (v != self->_acceptableStatusCodes) {
            [self willChangeValueForKey:@"acceptableStatusCodes"];
            [self->_acceptableStatusCodes autorelease];
            self->_acceptableStatusCodes = [v copy];
            [self didChangeValueForKey:@"acceptableStatusCodes"];
        }
    }
}

@synthesize acceptableContentTypes = _acceptableContentTypes;

+ (BOOL)automaticallyNotifiesObserversOfAcceptableContentTypes {
    return NO;
}

- (NSSet *)acceptableContentTypes {
    return [[self->_acceptableContentTypes retain] autorelease];
}

- (void)setAcceptableContentTypes:(NSSet *)v {
    if (self.state != kQRunLoopOperationStateInited) {
        assert(NO);
    } else {
        if (v != self->_acceptableContentTypes) {
            [self willChangeValueForKey:@"acceptableContentTypes"];
            [self->_acceptableContentTypes autorelease];
            self->_acceptableContentTypes = v;
            [self didChangeValueForKey:@"acceptableContentTypes"];
        }
    }
}

@synthesize responseOutputStream = _responseOutputStream;

+ (BOOL)automaticallyNotifiesObserversOfResponseOutputStream {
    return NO;
}

- (NSOutputStream *)responseOutputStream {
    return [[self->_responseOutputStream retain] autorelease];
}

- (void)setResponseOutputStream:(NSOutputStream *)v {
    if (self.dataAccumulator != nil) {
        assert(NO);
    } else {
        if (v != self->_responseOutputStream) {
            [self willChangeValueForKey:@"responseOutputStream"];
            [self->_responseOutputStream autorelease];
            self->_responseOutputStream = [v retain];
            [self didChangeValueForKey:@"responseOutputStream"];
        }
    }
}

@synthesize defaultResponseSize = _defaultResponseSize;

+ (BOOL)automaticallyNotifiesObserversOfDefaultResponseSize {
    return NO;
}

- (NSUInteger)defaultResponseSize {
    return self->_defaultResponseSize;
}

- (void)setDefaultResponseSize:(NSUInteger)v {
    if (self.dataAccumulator != nil) {
        assert(NO);
    } else {
        if (v != self->_defaultResponseSize) {
            [self willChangeValueForKey:@"defaultResponseSize"];
            self->_defaultResponseSize = v;
            [self didChangeValueForKey:@"defaultResponseSize"];
        }
    }
}

@synthesize maximumResponseSize = _maximumResponseSize;

+ (BOOL)automaticallyNotifiesObserversOfMaximumResponseSize {
    return NO;
}

- (NSUInteger)maximumResponseSize {
    return self->_maximumResponseSize;
}

- (void)setMaximumResponseSize:(NSUInteger)v {
    if (self.dataAccumulator != nil) {
        assert(NO);
    } else {
        if (v != self->_maximumResponseSize) {
            [self willChangeValueForKey:@"maximumResponseSize"];
            self->_maximumResponseSize = v;
            [self didChangeValueForKey:@"maximumResponseSize"];
        }
    }
}

@synthesize lastRequest = _lastRequest;
@synthesize lastResponse = _lastResponse;
@synthesize responseBody = _responseBody;
@synthesize connection = _connection;
@synthesize firstData = _firstData;
@synthesize dataAccumulator = _dataAccumulator;

- (NSURL *)URL {
    return [self.request URL];
}

- (BOOL)isStatusCodeAcceptable {
    NSIndexSet * asc;
    NSInteger sc;
    
    assert(self.lastResponse != nil);
    asc = self.acceptableStatusCodes;
    if (asc == nil) {
        asc = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    assert(asc != nil);
    
    sc = [self.lastResponse statusCode];
    return (sc >= 0) && [asc containsIndex:(NSUInteger)sc];
}

- (BOOL)isContentTypeAcceptable {
    NSString *contentType;
    assert(self.lastResponse != nil);
    contentType = [self.lastResponse MIMEType];
    return (self.acceptableContentTypes == nil) || 
        ((contentType != nil) && 
         [self.acceptableContentTypes containsObject:contentType]);
}

#pragma mark * Start and finish overrides

/*
 * Called by QRunLoopRunOperation when the operation starts. This kicks of an 
 * asynchronous NSURLConnection
 */
- (void)operationDidStart {
    assert(self.isActualRunLoopThread);
    assert(self.state == kQRunLoopOperationStateExecuting);
    assert(self.defaultResponseSize > 0);
    assert(self.maximumResponseSize > 0);
    assert(self.defaultResponseSize <= self.maximumResponseSize);
    assert(self.request != nil);
    
#if ! defined (NDEBUG)
    if (self.debugError != nil) {
        [self finishWithError:self.debugError];
        return;
    }
#endif

    assert(self.connection != nil);
    self.connection = [[NSURLConnection alloc] 
                       initWithRequest:self.request 
                       delegate:self 
                       startImmediately:NO];
    assert(self.connection != nil);
    
    for (NSString * mode in self.actualRunLoopModes) {
        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] 
                                   forMode:mode];
    }
    [self.connection start];
}

- (void)operationWillFinish {
    assert(self.isActualRunLoopThread);
    assert(self.state == kQRunLoopOperationStateExecuting);
#if ! defined (NDEBUG) 
    if (self.debugDelayTimer != nil) {
        [self.debugDelayTimer invalidate];
        self.debugDelayTimer = nil;
    }
#endif
    
    [self.connection cancel];
    self.connection = nil;
    
    if (self.responseOutputStream != nil) {
        [self.responseOutputStream close];
    }
}

- (void)finishWithError:(NSError *)error {
#if ! defined (NDEBUG)
    if (self.debugDelay > 0.0) {
        if ((error != nil) && 
            [[error domain] isEqual:NSCocoaErrorDomain] && 
            ([error code] == NSUserCancelledError)) {
            self.debugDelay = 0.0;
        } else {
            assert(self.debugDelayTimer == nil);
            self.debugDelayTimer = 
            [NSTimer timerWithTimeInterval:self.debugDelay
                                    target:self
                                  selector:@selector(debugDelayTimer) 
                                  userInfo:error 
                                   repeats:NO];
            assert(self.debugDelayTimer != nil);
            for (NSString * mode in self.actualRunLoopModes) {
                [[NSRunLoop currentRunLoop] addTimer:self.debugDelayTimer 
                                             forMode:mode];
            }
            self.debugDelay = 0.0;
            return;
        }
    }
#endif
    [super finishWithError:error];
}

#if ! defined (NDEBUG)

@synthesize debugError = _debugError;
@synthesize debugDelay = _debugDelay;
@synthesize debugDelayTimer = _debugDelayTimer;

- (void)debugDelayTimerDone:(NSTimer *)timer {
    NSError *error;
    assert(timer == self.debugDelayTimer);
    error = [[[timer userInfo] retain] autorelease];
    assert((error == nil) || [error isKindOfClass:[NSError class]]);
    [self.debugDelayTimer invalidate];
    self.debugDelayTimer = nil;
    [self finishWithError:error];
}
#endif

#pragma mark * NSURLConnection delegate callbacks

- (BOOL)connection:(NSURLConnection *)connection 
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    BOOL result;
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert(protectionSpace != nil);
    result = NO;
    if (self.authenticationDelegate != nil) {
        result = [self.authenticationDelegate httpOperation:self
                      canAuthenticateAgainstProtectionSpace:protectionSpace];        
    }
    return result;
}

- (void)connection:(NSURLConnection *)connection 
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert(challenge != nil);
    
    if (self.authenticationDelegate != nil) {
        [self.authenticationDelegate httpOperation:self
                 didReceiveAuthenticationChallenge:challenge];
    } else {
        if ([challenge previousFailureCount] == 0) {
            [[challenge sender] 
             continueWithoutCredentialForAuthenticationChallenge:challenge];
        } else {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection 
             willSendRequest:(NSURLRequest *)request 
            redirectResponse:(NSURLResponse *)response {
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert((response == nil) || [response 
                                 isKindOfClass:[NSHTTPURLResponse class]]);
    self.lastRequest = request;
    self.lastResponse = (NSHTTPURLResponse *)response;
    return request;
}

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response {
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert([response isKindOfClass:[NSHTTPURLResponse class]]);
    self.lastResponse = (NSHTTPURLResponse *)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    BOOL success;
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert(data != nil);
    success = YES;
    if (self.firstData) {
        assert(self.dataAccumulator == nil);
        if ((self.responseOutputStream == nil) || !self.isStatusCodeAcceptable){
            long long length;
            assert(self.dataAccumulator == nil);
            length = [self.lastResponse expectedContentLength];
            if (length == NSURLResponseUnknownLength) {
                length = self.defaultResponseSize;
            }
            if (length <= (long long)self.maximumResponseSize) {
                self.dataAccumulator = 
                [NSMutableData dataWithCapacity:(NSUInteger)length];
            } else {
                [self finishWithError:
                 [NSError errorWithDomain:kQHTTPOperationErrorDomain
                                     code:kQHTTPOperationErrorResponseTooLarge
                                 userInfo:nil]];
                success = NO;
            }
        }
        
        if (success) {
            if (self.dataAccumulator == nil) {
                assert(self.responseOutputStream != nil);
                [self.responseOutputStream open];
            }
        }
        
        self.firstData = NO;
    }
    
    if (success) {
        if (self.dataAccumulator != nil) {
            if (([self.dataAccumulator length] + [data length]) 
                <= self.maximumResponseSize) {
                [self.dataAccumulator appendData:data];
            } else {
                [self finishWithError:
                 [NSError errorWithDomain:kQHTTPOperationErrorDomain
                                     code:kQHTTPOperationErrorResponseTooLarge 
                                 userInfo:nil]];
            }
        } else {
            NSUInteger dataOffset;
            NSUInteger dataLength;
            const uint8_t * dataPtr;
            NSError *error;
            NSInteger bytesWritten;
            assert(self.responseOutputStream != nil);
            dataOffset = 0;
            dataLength = [data length];
            dataPtr = [data bytes];
            error = nil;
            
            do {
                if (dataOffset == dataLength) {
                    break;
                }
                
                bytesWritten = 
                [self.responseOutputStream write:&dataPtr[dataOffset]
                                       maxLength:dataLength - dataOffset];
                if (bytesWritten <= 0) {
                    error = [self.responseOutputStream streamError];
                    if (error == nil) {
                        error = 
                        [NSError 
                         errorWithDomain:kQHTTPOperationErrorDomain
                                    code:kQHTTPOperationErrorOutputStream
                                userInfo:nil];
                    }
                    break;
                } else {
                    dataOffset += bytesWritten;
                }
            } while (YES);
            
            if (error != nil) {
                [self finishWithError:error];
            }
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert(self.lastResponse != nil);
    
    if (self->_responseBody == nil) {
        self->_responseBody = [[NSData alloc] init];
        assert(self->_responseBody != nil);
    }
    
    if (!self.isStatusCodeAcceptable) {
        [self finishWithError:
         [NSError errorWithDomain:kQHTTPOperationErrorDomain
                             code:self.lastResponse.statusCode 
                         userInfo:nil]];
    } else if (!self.isContentTypeAcceptable) {
        [self finishWithError:
         [NSError errorWithDomain:kQHTTPOperationErrorDomain
                             code:kQHTTPOperationErrorBadContentType
                         userInfo:nil]];
        
    } else {
        [self finishWithError:nil];
    }
}

- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error {
    assert(self.isActualRunLoopThread);
    assert(connection == self.connection);
    assert(error != nil);
    [self finishWithError:error];
}

@end

NSString *kQHTTPOperationErrorDomain = @"kQHTTPOperationErrorDomain";

