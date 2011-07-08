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
    NSUInteger copyCounter = 0;
    for (copyCounter = 0; copyCounter < paramNumberOfCopies; copyCounter++) {
      if ([self.paperTray givePaperToPrinter] == YES) {
	NSLog(@"Print Job #%lu", (unsigned long)copyCounter + 1);
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
    Tray *newTray = [[Tray alloc] initWithPrinter:self];
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
