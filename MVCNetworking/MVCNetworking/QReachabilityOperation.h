/*
 * File: QReachabilityOperation.h
 * Contains: Runs until a host's reachability attains a certain value.
 */

#import "QRunLoopOperation.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface QReachabilityOperation : QRunLoopOperation {
    NSString *_hostName;
    NSUInteger _flagsTargetMask;
    NSUInteger _flagsTargetValue;
    NSUInteger _flags;
    SCNetworkReachabilityRef _ref;
}

// Initialises the operation to monitor the reachability of the specified host.
// The operation finishes (flags & flagsTargetMask) == flagsTargetValue.
- (id) initWithHostName:(NSString *)hostName;

@property (copy, readonly) NSString *hostName;
@property (assign, readwrite) NSUInteger flagsTargetMask;
@property (assign, readwrite) NSUInteger flagsTargetValue;
@property (assign, readonly) NSUInteger flags;

@end
