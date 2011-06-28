#import "XMLElement.h"

@implementation XMLElement

@synthesize name;
@synthesize test;
@synthesize parent;
@synthesize children;
@synthesize attributes;

- (id) init {
  self = [super init];
  if (self != nil) {
    NSMutableArray *childrenArray = [[NSMutableArray alloc] init];
    children = [childrenArray mutableCopy];
    [childrenArray release];

    NSMutableDictionary *newAttributes = [[NSMutableDictionary alloc] init];
    attributes = [newAttributes mutableCopy];
    [newAttributes release];
  }

  return self;
}

- (void) dealloc {
  NSLog(@"Deallocated Element");
  [name release];
  [text release];
  [children release];
  [attributes release];
  [super dealloc];
}

@end
