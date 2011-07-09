//
//  Tray.m
//  CommunicatingWithObjectsSample
//
//  Created by chenzefeng on 11-7-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "Tray.h"

@implementation Tray

@synthesize paperCount;
@synthesize ownerDevice;

- (id) init {
    return [self initWithOwnerDevice:nil];
}

- (id) initWithOwnerDevice:(id<TrayProtocol>)paramOwnerDevice {
    self = [super init];
    if (self != nil) {
        ownerDevice = paramOwnerDevice;
        paperCount = 10;
    }
    return self;
}

- (BOOL)givePaperToPrinter {
    BOOL result = NO;
    
    if (self.paperCount > 0) {
        result = YES;
        self.paperCount--;
    } else {
        [self.ownerDevice trayHasRunoutofPaper:self];
    }
    return result;
}

- (void)dealloc {
    [super dealloc];
}

@end
