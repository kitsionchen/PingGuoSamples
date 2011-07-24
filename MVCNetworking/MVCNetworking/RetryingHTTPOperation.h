/*
 * Runs an HTTP request, with support for retries.
 */

#import "QRunLoopOperation.h"

/*
 * RetryingHTTPOperation is a run loop based concurrent operation that initiates.
 * an HTTP Request and handles retrying the request if it fails.
 */

@class QHTTPOperation;
@class QReachabilityOperation;

enum RetryingHTTPOperationState {
    kRetryingHTTPOperationStateNotStarted,
    kRetryingHTTPOperationStateGetting,
    kRetryingHTTPOperationStateWaitingToRetry,
    kRetryingHTTPOperationStateRetrying,
    kRetryingHTTPOperationStateFinished
};

typedef enum RetryingHTTPOperationState RetryingHTTPOperationState;

@interface RetryingHTTPOperation : QRunLoopOperation {
    NSUInteger _sequenceNumber;
    NSURLRequest * _request;
    NSSet * _acceptableContentTypes;
    
    NSString * _responseFilePath;
    NSHTTPURLResponse * _response;
    NSData * _responseContent;
    
    RetryingHTTPOperationState _retryState;
    RetryingHTTPOperationState _retryStateClient;
    
    QHTTPOperation * _networkOperation;
    
    BOOL _hasHadRetryableFailure;
    
    NSUInteger _retryCount;
    NSTimer * _retryTimer;
    QReachabilityOperation * _reachabilityOperation;
    BOOL _notificationInstalled;
}

/*
 * Initialise the operation to run the specified HTTP request.
 */
- (id)initWithRequest:(NSURLRequest *)request;

@property (copy, readonly) NSURLRequest *request;
@property (copy, readwrite) NSSet *acceptableContentTypes;
@property (retain, readwrite) NSString *responseFilePath;
@property (assign, readonly) RetryingHTTPOperationState retryState;
@property (assign, readonly) RetryingHTTPOperationState retryStateClient;
@property (assign, readonly) BOOL hasHadRetryableFailure;
@property (assign, readonly) NSUInteger retryCount;
@property (copy, readonly) NSString *responseMIMEType;
@property (copy, readonly) NSData *responseContent;


@end
