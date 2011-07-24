/*
 * File: QHTTPOperation.h
 * Contains: An NSOperation that runs an HTTP request.
 */

#import "QRunLoopOperation.h"

@protocol QHTTPOperationAuthenticationDelegate;

@interface QHTTPOperation : QRunLoopOperation {
    NSURLRequest * _request;
    NSIndexSet * _acceptableStatusCodes;
    NSSet * _acceptableContentTypes;
    id <QHTTPOperationAuthenticationDelegate> _authenticationDelegate;
    NSOutputStream * _responseOutputStream;
    NSUInteger _defaultResponseSize;
    NSUInteger _maximumResponseSize;
    NSURLConnection * _connection;
    BOOL _firstData;
    NSMutableData * _dataAccumulator;
    NSURLRequest * _lastRequest;
    NSHTTPURLResponse * _lastResponse;
    NSData * _responseBody;
    
#if ! defined (NDEBUG)
    NSError * _debugError;
    NSTimeInterval _debugDelay;
    NSTimer * _debugDelayTimer;
#endif
}

- (id)initWithRequest:(NSURLRequest *)request;
- (id)initwithURL:(NSURL *)url;

@property (copy, readonly) NSURLRequest *request;
@property (copy, readonly) NSURL *URL;

@property (copy, readwrite) NSIndexSet *acceptableStatusCodes;
@property (copy, readwrite) NSSet *acceptableContentTypes;
@property (assign, readwrite) id<QHTTPOperationAuthenticationDelegate> 
authenticationDelegate;

#if ! defined (NDEBUG)
@property (copy, readwrite) NSError *debugError;
@property (assign, readwrite) NSTimeInterval debugDelay;
#endif

@property (retain, readwrite) NSOutputStream *responseOutputStream;
@property (assign, readwrite) NSUInteger defaultResponseSize;
@property (assign, readwrite) NSUInteger maximumResponseSize;

@property (copy, readonly) NSURLRequest *lastRequest;
@property (copy, readonly) NSHTTPURLResponse *lastResponse;
@property (copy, readonly) NSData *responseBody;

@end


/*
 * QHTTPOperation implements all of these methods. so if you override them
 * you must consider whether or not to call super.
 */

@interface QHTTPOperation (NSURLConnectionDelegate)

/*
 * Routes the request to the authentication delegate if it exists, otherwise
 * just return NO
 */
- (BOOL)connection:(NSURLConnection *)connection 
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;


/*
 * Routes the request to the authentication delegate if it exists, otherwise
 * just return NO
 */
- (void)connection:(NSURLConnection *)connection 
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

- (NSURLRequest *)connection:(NSURLConnection *)connection 
             willSendRequest:(NSURLRequest *)request 
            redirectResponse:(NSURLResponse *)response;

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error;

@end

@protocol QHTTPOperationAuthenticationDelegate<NSObject>
@required
- (BOOL)httpOperation:(QHTTPOperation *)operation 
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;

- (void)httpOperation:(QHTTPOperation *)operation
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end

extern NSString *kQHTTPOperationErrorDomain;

enum {
    kQHTTPOperationErrorResponseTooLarge = -1,
    kQHTTPOperationErrorOutputStream = -2,
    kQHTTPOperationErrorBadContentType = -3
};
