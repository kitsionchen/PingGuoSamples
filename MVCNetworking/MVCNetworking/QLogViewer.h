/*
 * File: QLogViewer.m
 * Contains:
 * Displays in-memory QLog entries, with options to copy and mail the log.
 */


@interface QLogViewer : UITableViewController {
    int _logEntriesDummy;
    UIActionSheet *_actionSheet;
    UIAlertView *_alertView;
}

// Present the view controller modally on the specified view controller.
- (void)presentMOdallyOn:(UIViewController *)controller animated:(BOOL)animated;
@end
