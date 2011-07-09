//
//  Tray.h
//  CommunicatingWithObjectsSample
//
//  Created by chenzefeng on 11-7-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Tray;

@protocol TrayProtocol <NSObject>
@required
- (void)trayHasRunoutofPaper:(Tray *)paramSender;
@end

@interface Tray : NSObject {
@public
    id<TrayProtocol> ownerDevice;
    
@private
    NSUInteger paperCount;
}

@property (nonatomic, assign) id<TrayProtocol> ownerDevice;
@property (nonatomic, assign) NSUInteger paperCount;

- (BOOL)givePaperToPrinter;

- (id)initWithOwnerDevice:(id<TrayProtocol>)paramOwnerDevice;

@end
