/* 
 * Invoking the Selectors of an Object Dynamically 
 * You want to be able to dynamically call any method in any object given the 
 * name of the method and its parameters.
 */
 
- (NSString *)myMethod:(NSString *)param1 withParam2:(NSNumber *)param2 {
	NSString *result = @"Objective-C";
	NSLog(@"Param 1 = %@", param1);
	NSLog(@"Param 2 = %@", param2);
	return result;
}

- (void)invokeMyMethodDynamically {
	SEL selector = @selector(myMethod:withParam2:);
	
	NSMethodSignature *methodSignature = 
	[[self class] instanceMethodSignatureForSelector:selector];
	
	NSInvocation *invocation = 
	[NSInvocation invocationWithMethodSignature:methodSignature];
	[invocation setTarget:self];
	[invocation setSelector:selector];
	
	NSString *returnValue = nil;
	NSString *argument1 = @"First Parameter";
	NSNumber *argument2 = [NSNumber numberWithInt:102];
	
	[invocation setArgument:&argument1 atIndex:2];
	[invocation setArgument:&argument2 atIndex:3];
	[invocation retainArguments];
	[invocation invoke];
	[invocation getReturnValue:&returnValue];
	NSLog(@"Return value = %@", returnValue);
}
