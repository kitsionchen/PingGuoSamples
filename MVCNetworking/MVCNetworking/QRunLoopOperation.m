/*
 * File: QRunLoopOperation.m
 * An abstract subclass of NSOperation for async run loop based on operations.
 */
#import "QRunLoopOperation.h"

/*
 * Theory Of Operation
 * -------------------
 * Some critical points:
 * 1. By the time we are running on the run loop thread, we know that all 
 * further state transitions happen on the run loop thread. That is because
 * there are only three states(inited, executing, and finished) and run loop
 * thread code can only run in the last two states and the transition from 
 * executing to finished is always done on the run loop thread.
 * 2. -start can only be called once. So run loop thread code doesn't have to 
 * worry about racing with -start because, by the time the run loop thread code
 * runs, -start has already been called.
 * 3. -cancel can be called multiple times from any thread. Run loop thread code
 * must take a lot of care with do the right thing with cancellation.
 *
 * Some state transitions:
 * 1. init -> dealloc
 * 2. init -> cancel -> dealloc
 * 3. init -> cancel -> start -> finish -> dealloc (doesn't happen)
 * 4. init -> cancel -> start -> startOnRunLoopThreadThead -> finish dealloc
 * 
 * 5. init -> start -> cancel -> startOnRunLoopThreadThread -> finish -> 
 * cancelOnRunLoopThreadThread -> dealloc (interesting)
 *
 * 6. init -> start -> cancel -> cancelOnRunLoopThreadThread -> 
 * startOnRunLoopThreadThread -> finish -> dealloc (doesn't happen)
 *
 * 7. init -> start -> cancel -> startOnRunLoopThreadThread -> 
 * cancelOnRunLoopThreadThread -> finish -> dealloc (doesn't happen)
 *
 * 8. init -> start -> startOnRunLoopThreadThread -> finish -> dealloc
 * 9. init -> start -> startOnRunLoopThreadThread -> cancel -> 
 * cancelOnRunLoopThreadThread -> finish -> dealloc
 *
 * 10. init -> start -> startOnRunLoopThreadThread -> cancel -> finish ->
 * cancelOnRunLoopThreadThread -> dealloc (interesting)
 *
 * 11. init -> start -> startOnRunLoopThreadThread -> finish -> cancel -> dealloc
 * 
 * Described:
 */


@interface QRunLoopOperation () 
@property (assign, readwrite) QRunLoopOperationState state;
@property (copy, readwrite) NSError *error;
@end

@implementation QRunLoopOperation

- (id) init {
    self = [super init];
    if (self != nil) {
        assert(self->_state == kQRunLoopOperationStateInited);
    }
    return self;
}

- (void) dealloc {
    assert(self->_state != kQRunLoopOperationStateExecuting);
    
    [self->_runLoopModes release];
    [self->_runLoopThread release];
    [self->_error release];
    [super dealloc];
}

#pragma mark 
#pragma mark - Properties

@synthesize runLoopThread = _runLoopThread;
@synthesize runLoopModes = _runLoopModes;

// Returns the effective run loop thread, that is, the one set by the user.
// or, if that is not set, the main thread.
- (NSThread *)actualRunLoopThread {
    NSThread *result;
    result = self.runLoopThread;
    if (result == nil) {
        result = [NSThread mainThread];
    }
    return result;
}

// Returns YES if the current thread is the actual run loop thread.
- (BOOL) isActualRunLoopThread {
    return [[NSThread currentThread] isEqual:self.actualRunLoopThread];
}

- (NSSet *) actualRunLoopModes {
    NSSet *result;
    result = self.runLoopModes;
    
    if ((result == nil) || ([result count] == 0)) {
        result = [NSSet setWithObject:NSDefaultRunLoopMode];
    }
    return result;
}

@synthesize error = _error;

#pragma mark
#pragma mark - Core state transitions

- (QRunLoopOperationState)state {
    return self->_state;
}

// Change the state of the operation, sending the appropriate KVO notifications
- (void) setState:(QRunLoopOperationState)newState {
    @synchronized(self) {
        QRunLoopOperationState oldState;
        
        // The following check is important, The state can only go forward, 
        // and there should be no redundant changes to the state (that is, 
        // newState must never be eqaul to self->_state)
        assert(newState > self->_state);
        
        // Thransitions from executing to finished must be done on the run 
        // loop thread.
        assert((newState != kQRunLoopOperationStateFinished) || 
               self.isActualRunLoopThread);
        
        oldState = self->_state;
        if ((newState == kQRunLoopOperationStateExecuting) ||
            (oldState == kQRunLoopOperationStateExecuting)) {
            [self willChangeValueForKey:@"isExecuting"];
        }
        
        if ((newState == kQRunLoopOperationStateFinished)) {
            [self willChangeValueForKey:@"isFinished"];
        }
        
        self->_state = newState;
        if (newState == kQRunLoopOperationStateFinished) {
            [self didChangeValueForKey:@"isFinished"];
        }
        
        if ((newState == kQRunLoopOperationStateExecuting) ||
            (oldState == kQRunLoopOperationStateExecuting)) {
            [self didChangeValueForKey:@"isExecuting"];
        }
    }
}

// Starts the operation, The actual -start method is very simple.
// deferring all of the work to be done on the run loop thread by this method.
- (void) startOnRunLoopThread {
    assert(self.isActualRunLoopThread);
    assert(self.state == kQRunLoopOperationStateExecuting);
    
    if ([self isCancelled]) {
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain
                                                  code:NSUserCancelledError
                                              userInfo:nil]];
    } else {
        [self operationDidStart];
    }
}

- (void) cancelOnRunLoopThread {
    if (self.state == kQRunLoopOperationStateExecuting) {
        [self finishWithError:[NSError errorWithDomain:NSCocoaErrorDomain
                                                  code:NSUserCancelledError
                                              userInfo:nil]];
    }
}

- (void)finishWithError:(NSError *)error {
    assert(self.isActualRunLoopThread);
    if (self.error == nil) {
        self.error = error;
    }
    [self operationWillFinish];
    self.state = kQRunLoopOperationStateFinished;
}

#pragma mark
#pragma mark - Subclass override points 
- (void)operationDidStart {
    assert(self.isActualRunLoopThread);
}

- (void)operationWillFinish {
    assert(self.isActualRunLoopThread);
}

#pragma mark
#pragma mark - Overrides

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return self.state == kQRunLoopOperationStateExecuting;
}

- (BOOL) isFinished {
    return self.state == kQRunLoopOperationStateFinished;
}

- (void)start {
    assert(self.state == kQRunLoopOperationStateInited);
    
    self.state = kQRunLoopOperationStateExecuting;
    [self performSelector:@selector(startOnRunLoopThread) 
                 onThread:self.actualRunLoopThread
               withObject:nil
            waitUntilDone:NO
                    modes:[self.actualRunLoopModes allObjects]];
}

- (void)cancel {
    BOOL runCancelOnRunLoopThread;
    BOOL oldValue;
    @synchronized(self) {
        oldValue = [self isCancelled];
        [super cancel];
        runCancelOnRunLoopThread = !oldValue && 
        self.state == kQRunLoopOperationStateExecuting;
    }
    if (runCancelOnRunLoopThread) {
        [self performSelector:@selector(cancelOnRunLoopThread)
                     onThread:self.actualRunLoopThread
                   withObject:nil
                waitUntilDone:YES
                        modes:[self.actualRunLoopModes allObjects]];
    }
}
@end
