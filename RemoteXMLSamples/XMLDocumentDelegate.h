#import "XMLElement.h"

@class XMLDocument

@protocol XMLDocumentDelegate <NSObject>

@required
  - (void)xmlDocumentDelegateParsingFinished:(XMLDocument *)paramSender;
  - (void)xmlDocumentDelegateParsingFailed:(XMLDocument *)paramSender
                                 withError:(NSError *)paramError;
@end
