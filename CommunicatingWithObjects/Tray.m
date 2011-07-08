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
    ownerDevice = [paramOwnerDevice retain];
    paperCount = 10;
  }
  return self;
}

- (BOOL) givePaperToPrinter {
  BOOL result = NO;
  if (self.paperCount > 0) {
    result = YES;
    self.paperCount--;
  } else {
    [self.ownerDevice trayHasRunoutofPaper:self];
  }
  return self;
}

- (void)dealloc {
  [ownerDevice release];
  [super dealloc];
}

@end
