//
//  Printer.m
//  CommunicatingWithObjectsSample
//
//  Created by chenzefeng on 11-7-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "Printer.h"

@implementation Printer

@synthesize paperTray;

- (void)trayHasRunoutofPaper:(Tray *)paramSender {
    NSLog(@"No paper in the paper tray. Please load more paper.");
}

- (void)print {
    NSLog(@"print");
}

- (BOOL)printPaperWithText:(NSString *)paramText 
            numberOfCopies:(NSUInteger)paramNumberOfCopies {
    BOOL result = NO;
    if (paramNumberOfCopies > 0) {
        NSUInteger i = 0;
        for (i = 0; i < paramNumberOfCopies; i++) {
            if ([self.paperTray givePaperToPrinter] == YES) {
                NSLog(@"Print Job #%lu", (unsigned long)i + 1);
                [self print];
            } else {
                return NO;
            }
        }
        result = YES;
    }
    return result;
}

- (id) init {
    self = [super init];
    if (self != nil) {
        Tray *newTray = [[Tray alloc] initWithOwnerDevice:self];
        paperTray = [newTray retain];
        [newTray release];
    }
    return self;
}

- (void)dealloc {
    [paperTray release];
    [super dealloc];
}

@end
