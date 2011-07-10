/*
 * File: QLog.h
 * Contains: A simplistic logging package.
 */

#import <Foundation/Foundation.h>

@interface QLog : NSObject {
    // main thread write, any thread read.
    BOOL _enabled;
    
    // main thread write, any thread read.
    int _logFile;
    
    // main thread only, only valid if _logFile != -1
    off_t _logFileLength;
    
    // main thread write, any thread read.
    BOOL _loggingToStdErr;
    
    // main thead write, any thread read.
    NSUInteger _optionsMask;
    
    // main thread only.
    BOOL _showViewer;
    
    // main thread only.
    NSMutableArray *_logEntries;
    
    // any thread, protected by @sychronize(self)
    NSMutableArray *_pendingEntries;
}

// Returns the singleton logging object.
+ (QLog *)log;

// Flushes any pending log entries to the logEntries array and also, if 
// appropriate, to the log file or stderr.
- (void)flush;

// Empties the logEntries array and, if appropriate, the log file. Not
// much we can do about stderr.
- (void)clear;

// Preferences
@property (assign, readonly, getter=isEnabled) BOOL enabled;
@property (assign, readonly, getter=isLoggingToFile) BOOL loggingToFile;
@property (assign, readonly, getter=isLoggingToStdErr) BOOL loggingToStdErr;
@property (assign, readonly) NSUInteger optionMask;
@property (assign, readonly) BOOL showViewer;

- (void)logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void)logWithFormat:(NSString *)format arguments:(va_list)argList;
- (void)logOption:(NSUInteger)option 
       withFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);
- (void)logOption:(NSUInteger)option 
       withFormat:(NSString *)format
        arguments:(va_list)argList;

// In memory log entries
// New entries are added to the end of this array and, as there is an upper 
// limit number of entries that will be held in memory. ald entries are removed
// from the beginning.
@property (retain, readonly) NSMutableArray *logEntries;

// In file log entries.
- (NSInputStream *)streamForLogValidToLength:(off_t *)lengthPtr;

@end
