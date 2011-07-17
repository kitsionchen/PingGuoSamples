/*
 * File: NetworkManager.h
 * A singleton to manage the core network interactions.
 */

#import <Foundation/Foundation.h>


@interface NetworkManager : NSObject {
    NSThread *_networkRunLoopThread;
    NSOperationQueue *_queueForNetworkManagement;
    NSOperationQueue *_queueForNetworkTransfers;
    NSOperationQueue *_queueForCPU;
    CFMutableDictionaryRef _runningOperationToTargetMap;
    CFMutableDictionaryRef _runningOperationToActionMap;
    CFMutableDictionaryRef _runningOperationToThreadMap;
    NSUInteger _runningNetworkTransferCount;
}

// Returns the network manager singleton. can be called from any thread.
+ (NetworkManager *)shardManager;

// Returns a mutable request that's configured to do an HTTP GET operation.
// for the specified URL. This sets up any request properties that should be
// common to all network requests, most notably the user agent string.
- (NSMutableURLRequest *)requestToGetURL:(NSURL *)url;

// networkInUse is YES if any network transfer operations are in progress; 
// you can only call the getter from the main thread.
@property (nonatomic, assign, readonly) BOOL networkInUse;

// We have three operation queues to seperate our various operations;
// There are a bunch of important points here:
// 1. There are seperate network management, network transfer and cpu queues, so
// that network operations don't hold up cpu operations.
// 2. The width of network management queue (that is, 
// the maxConcurrentOperationCount value) is unbounded, so that network management
// operations always proceed. This is fine because network management operations
// are all run loop based and consume very few real resources.
// 3. The width of the network transfer queue is set to some fixed value, which
// controls the total number of network operations that we can be running 
// simultaneously.
// 4. The width of the CPU operation queue is left at the default value, which
// typically means we start one cpu operation per available core (which on iOS
// devices means one). This prevents us from starting lots of cpu operations 
// that just thrash the scheduler without getting any concurrency benefits.
// 5. When you queue an operation you must supply a target/action pair that is 
// called when the operation completes without being cancelled.
// 6. The target/action pair is called on the thread that added the operation to 
// the queue. you have to ensure that this thread runs its run loop.
// 7. If you queue a network operation and that network operation supports the 
// runLoopThread property and the value of that property is nil, this sets the 
// run loop thread of the operation to the above-metioned internal networking 
// thread. this means that, by default, all network run loop callbacks run on
// this internal netowking thread. The goal here is to minimise main thread 
// latency. 
// It is worth nothing that this is only true for network operation run looop
// callbacks, and is not true for target/action completions. These are called 
// on the thread that queued the operation, as described above.
// 8. If you cancel an operation you must do so using - cancelOperation:,
// lest things get very confused.
// 9. Both -adXxxOperation:finishedTarget:action: and -cancelOperation: can be
// called from any thread.
// 10. If you always cancel the operation on the same thread that you used to
// queue the operation(and therefore the same thread that will run the 
// target/action completion), you can be guaranteed that, after -cancellOperation;
// returns, the target/action completion will never be called.
// 11. To simplify clean up, -cancelOperation: does nothing if the supplied 
// operations is nil or if it is not currently queued.
// 12. We don't do any prioritsation of operations.

- (void)addNetworkManagementOperation:(NSOperation *)operation 
                       finishedTarget:(id)target
                               action:(SEL)action;

- (void)addNetworkTransferOperation:(NSOperation *)operation
                     finishedTarget:(id)target
                             action:(SEL)action;

- (void)addCPUOperation:(NSOperation *)operation 
         finishedTarget:(id)target 
                 action:(SEL)action;

- (void)cancelOperation:(NSOperation *)operation;
@end
