/*
 * File: Thumbnail.h
 * Contains: Model object for a thumbnail.
 */

#import <CoreData/CoreData.h>

// In constrast to the Photo class, the Thumbnail class is entirely passive.
// It is just a dumb container for the thumbnail data.
// Keep in mind that, by default, managed object properties are retained, not 
// copied, so clients of Thumbnail must be careful if they assign potentially 
// mutable data to the imageData property.

@class Photo;

@interface Thumbnail : NSManagedObject

// holds a PNG representation of the thumbnail
@property (nonatomic, retain, readwrite) NSData * imageData;
// a pointer back to the owning photo
@property (nonatomic, retain, readwrite) Photo * photo;

@end
