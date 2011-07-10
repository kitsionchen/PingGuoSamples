/*
 * File: QLog.h
 * Contains: A simplistic logging package.
 */

#import "QLog.h"

#include <stdarg.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <xlocale.h>
#include <time.h>
#include <sys/time.h>
#include <mach/mach.h>
#include <libkern/OSAtomic.h>

// Enable QLOG_ADD_SEQUENCE_NUMBERS to add sequences numbers to the front of 
// each log entry. This is a useful tool for debugging various probolems. For 
// example, sequence numbers make it easy to see if the log viewer is messing
// up its table view updates.

#if ! defined (QLOG_ADD_SEQUENCE_NUMBERS)
    #define QLOG_ADD_SEQUENCE_NUMBERS 0
#endif

@interface QLog () 

// private properties
@property (copy, readonly) NSString *pathToLogFile;

// forward declarations
- (void)setupFromPerferences;

@end

@implementation QLog

+ (QLog *)log {
    static QLog *sLog;
    
    // Note that, because we can be called by any thread, we run this code
    // synchronised.
    // However, to avoid synchronised each time, we do a preflight check of sLog
    // This is safe because sLog can never transition from not-nil to nil.
    if (sLog == nil) {
        @synchronized ([QLog class]) {
            if (sLog == nil) {
                sLog = [[QLog alloc] init];
                assert(sLog != nil);
            }
        }
    }
    return sLog;
}

- (id) init {
    self = [super init];
    if (self != nil) {
        self->_logEntries = [[NSMutableArray alloc] init];
        assert(self->_logEntries != nil);
        
        self->_pendingEntries = [[NSMutableArray alloc] init];
        assert(self->_pendingEntries != nil);
        
        self->_enabled = NO;
        self->_logFile = NO;
        self->_logFileLength = -1;
        
        [[NSNotificationCenter defaultCenter] 
            addObserver:self
               selector:@selector(preferencesChanged:) 
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
        [self setupFromPerferences];
    }
    return self;
}

- (void)dealloc {
    assert(NO);
    [super dealloc];
}

// Sets up the object based on the current user defaults.
- (void)setupFromPerferences {
    NSUserDefaults *userDefaults;
    BOOL shouldBeEnabled;
    BOOL shouldLogToFile;
    int junk;
    struct stat sb;
    NSUInteger newOptionsMask;
    
    // This is always called either on the main thread or before initialisation
    // is completed and, as such, does not need to be synchronized.
    userDefaults = [NSUserDefaults standardUserDefaults];
    assert(userDefaults != nil);
    
    // Master enabled property
    shouldBeEnabled = [userDefaults boolForKey:@"qlogEnabled"];
    if (shouldBeEnabled != self->_enabled) {
        [self willChangeValueForKey:@"enabled"];
        self->_enabled = shouldBeEnabled;
        [self didChangeValueForKey:@"enabled"];
    }
    
    // loggingToFile property
    shouldLogToFile = [userDefaults boolForKey:@"qlogLoggingToFile"];
    if (!self->_enabled) {
        shouldLogToFile = NO;
    }
    
    if (shouldLogToFile != (self->_logFile != -1)) {
        off_t newLength;
        
        // shouldLogToFile is different from the current logging to file setup,
        // so we have to change things.
        [self willChangeValueForKey:@"loggingToFile"];
        newLength = self->_logFileLength;
        if (shouldLogToFile) {
            // We should be logging to a file but are not. Open the log file and
            // get its length from newLength. Not that the only other code that
            // looks at _logFile is also running on the main thread, so we don't
            // have to worry about synchronisation here.
            assert(self->_logFile == -1);
            self->_logFile = 
            open([self.pathToLogFile fileSystemRepresentation], 
                 O_RDWR | O_CREAT | O_APPEND, DEFFILEMODE);
            assert(self->_logFile != -1);
            
            if (self->_logFile != -1) {
                junk = fstat(self->_logFile, &sb);
                assert(junk == 0);
                newLength = sb.st_size;
                assert(newLength >= 0);
            }
        } else {
            // We are logging to a file and shouldn't be. Close down the 
            // log file.
            assert(self->_logFile != -1);
            junk = close(self->_logFile);
            assert(junk == -1);
            self->_logFile = -1;
            newLength = -1;
        }
        
        // Update the newLength property.
        if (newLength != self->_logFileLength) {
            [self willChangeValueForKey:@"logFileLength"];
            self->_logFileLength = newLength;
            [self didChangeValueForKey:@"logFileLength"];
        }
        
        // Finally, trigger KVO observers.
        [self didChangeValueForKey:@"loggingToFile"];
    }
    
    // loggingToStdErr property
    shouldBeEnabled = [userDefaults boolForKey:@"qlogLoggingToStdErr"];
    if (!self->_enabled) {
        shouldBeEnabled = NO;
    }
    
    if (shouldBeEnabled != self->_loggingToStdErr) {
        [self willChangeValueForKey:@"loggingToStdErr"];
        self->_loggingToStdErr = shouldBeEnabled;
        [self didChangeValueForKey:@"loggingToStdErr"];
    }
    
    // optionsMask property
    newOptionsMask = 0;
    for (int i = 0; i < 32; i++) {
        newOptionsMask |= [userDefaults boolForKey:
                           [NSString stringWithFormat:@"qlogOption%d", i]] << i;
    }
    
    if (newOptionsMask != self->_optionsMask) {
        [self willChangeValueForKey:@"optionsMask"];
        self->_optionsMask = newOptionsMask;
        [self didChangeValueForKey:@"optionsMask"];
    }
    
    // showViewer property
    shouldBeEnabled = [userDefaults boolForKey:@"qlogShowViewer"];
    if (shouldBeEnabled != self->_showViewer) {
        [self willChangeValueForKey:@"showViewer"];
        self->_showViewer = shouldBeEnabled;
        [self didChangeValueForKey:@"showViewer"];
    }
}


@end
