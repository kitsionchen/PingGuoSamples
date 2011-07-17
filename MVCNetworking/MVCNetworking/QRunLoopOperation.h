/*
 * An abstract subclass of NSOperation for async run loop based operations
 */
#import <Foundation/Foundation.h>


enum QRunLoopOperationState {
    kQRunLoopOperationStateInited,
    kQRunLoopOperationStateExecuting,
    kQRunLoopOperationStateFinished
};

typedef enum QRunLoopOperationState QRunLoopOperationState;

@interface QRunLoopOperation : NSOperation {
    QRunLoopOperationState _state;
    NSThread *_runLoopThread;
    NSSet *_runLoopModes;
    NSError *_error;
}

// Thinks you can configure before queuing the operation
// Import: Do not change these after queuing the operation; it is very likely
// that bad things will happen if you do.


@property (nonatomic, readwrite) NSThread *runLoopThread;
@property (nonatomic, readwrite) NSSet *runLoopModes;
@property (copy, readonly) NSError *error;
@property (assign, readonly) QRunLoopOperationState state;
@property (retain, readonly) NSThread *actualRunLoopThread;
@property (assign, readonly) BOOL isActualRunLoopThread;
@property (copy, readonly) NSSet *actualRunLoopModes;

@end

@interface QRunLoopOperation (SubClassSupport) 

// Override points
// A subclass will probably need to override -operationDidStart and 
// -operationWillFinish to set up and teer down its run loop sources, respectively
// These are always called on the actual run loop thread.
// Note that -operationWillFinish will be called even if the operation is
// cancelled. 
// -operationWillFinish can check the error property to see whether the operation
// was successful. error will be NSCocoaErrorDomain/NSUserCancelledError on 
// cancellation.
// -operationDidStart is allowed to call -finishWithError:

- (void)operationDidStart;
- (void)operationWillFinish;

// Support methods
// A subclass should call finishWithError: when the operation is complete, passing
// nil for no error and an error otherwise. It must call this on the actual
// run loop thread. 
// Note that this will call -operationWillFinish before returning.
- (void)finishWithError:(NSError *)error;

@end
