//
//  CommunicatingWithObjectsSampleAppDelegate.h
//  CommunicatingWithObjectsSample
//
//  Created by chenzefeng on 11-7-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
