/*
 * File:        AppDelegate.h
 * Contains:    Main app controller.
 */

#import <UIKit/UIKit.h>

@class PhotoGallery;
@class PhotoGalleryViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *_window;
    UINavigationController *_navController;
    
    NSString *_galleryURLString;
    PhotoGallery *_photoGallery;
    PhotoGalleryViewController *_photoGalleryViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;


@end
