//
//  Printer.h
//  CommunicatingWithObjectsSample
//
//  Created by chenzefeng on 11-7-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tray.h"

@interface Printer : NSObject<TrayProtocol> {
@public
    Tray *paperTray;
}

@property (nonatomic, retain) Tray *paperTray;

- (BOOL)printPaperWithText:(NSString *)paramText
            numberOfCopies:(NSUInteger)paramNumberOfCopies;

@end
