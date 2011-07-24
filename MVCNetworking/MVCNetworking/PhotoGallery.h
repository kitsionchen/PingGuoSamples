/*
 * File: PhotoGallery.
 * Contains: A model object that represents a gallery of photos on the network.
 */

#import <CoreData/CoreData.h>

enum PhotoGallerySyncState {
    kPhotoGallerySyncStateStopped,
    kPhotoGallerySyncStateGetting,
    kPhotoGallerySyncStatePaseing,
    kPhotoGallerySyncStateCommitting
};

typedef enum PhotoGallerySyncState PhotoGallerySyncState;

@class PhotoGalleryContext;
@class RetryingHTTPOperation;
@class GalleryParserOperation;

@interface PhotoGallery : NSObject {
    NSString * _galleryURLString;
    NSUInteger * _sequenceNumber;

    PhotoGalleryContext * _galleryContext;
    NSEntityDescription * _photoEntity;
    NSTimer * _saveTimer;
    
    NSDate * _lastSyncDate;
    NSError * _lastSyncError;
    NSDateFormatter * _standardDateFormatter;
    PhotoGallerySyncState _syncState;
    RetryingHTTPOperation * _getOperation;
    GalleryParserOperation * _parserOperation;
}

#pragma mark * Start up and shut down

/*
 * Called by the application delegate at startup time. This takes care of various
 * bits of bookkeeping, including reseting the cache of photos if that debugging
 * option has been set.
 */
+ (void)applicationStartup;

- (id)initWithGalleryURLString:(NSString *)galleryURLString;

@property (nonatomic, copy, readonly) NSString *galleryURLString;

/*
 * Starts the gallery
 * (finds or creates a cache database and kicks off the initial sync)
 */
- (void)start;

- (void)save;

/*
 * Called by the application delegate at -applicationDidEnterBackground: and 
 * -applicationWillTerminate: and also called by the application delegate when 
 * it switches to a new gallery.
 */
- (void)stop;

#pragma mark * Core Data accessors

/*
 * These properties are exported for the benefit of the PhotoGalleryViewcontroller
 * class, which uses them to set up its fetched results controller.
 */

@property (nonatomic, retain, readonly) 
NSManagedObjectContext *managedObjectContext;

/*
 * Returns the entity description for the "Photo" entity in our database.
 */
@property (nonatomic, retain, readonly) 
NSEntityDescription *photoEntity;

#pragma mark * Syncing

/*
 * These properties allow user interface controllers to learn about and control 
 * the state of the syncing process.
 */

/*
 * observable, YES if syncState > kPhotoGallerySyncStateStopped.
 */
@property (nonatomic, assign, readonly, getter=isSyncing) BOOL syncing;
@property (nonatomic, assign, readonly) PhotoGallerySyncState syncState;

/*
 * observable, user-visible sync status
 */
@property (nonatomic, copy, readonly) NSString *syncStatus;

/*
 * observable, date of last successful sync.
 */
@property (nonatomic, copy, readonly) NSDate *lastSyncDate;

/*
 * observable, error for last sync
 */
@property (nonatomic, copy, readonly) NSError *lastSyncError;

/*
 * observable, date formatter for general purpose use
 */
@property (nonatomic, copy, readonly) NSDateFormatter *standardDateFormatter;

/*
 * Force a sync to start right now. Does nothing if a sync is already in progress.
 */
- (void)startSync;

/*
 * Force a sync to stop right now. Does nothing if a no sync is in progress.
 */
- (void)stopSync;
@end
