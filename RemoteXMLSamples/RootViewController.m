#import "RootViewController.h"
#import "XMLElement.h"

@implementation RootViewController

@synthesize xmlDocument;

- (void) xmlDocumentDelegateParsingFinished:(XMLDocument *)paramSender {
  NSLog(@"Finished downloading and parsing the remote XML");
}

- (void) xmlDocumentDelegateParsingFailed:(XMLDocument *)parsender
				withError:(NSError *)paramError {
  NSLog(@"Falied to download/parse the remote XML.");
}

- (void)viewDidLoad {
  [super viewDidLoad];
  NSString *xmlPath = "";
  XMLDocument *newDocument = [[XMLDocument alloc] initWithDelegate:self];
  self.xmlDocument = newDocument;
  [newDocument release];
  [self.xmlDocument parseRemoteXMLWithURL:xmlPath];
}

- (void) viewDidUnload {
  [super viewDidUnload];
  self.xmlDocument = nil;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:
  (UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (void) dealloc {
  [xmlDocument release];
  [super dealloc];
}

@end
