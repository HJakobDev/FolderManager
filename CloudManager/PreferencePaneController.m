//
//  PreferencePaneController.m
//  CloudManager
//
//  Created by Henri on 29.04.16.
//  Copyright © 2016 Henrik Jakob. All rights reserved.
//

#import "PreferencePaneController.h"

@implementation PreferencePaneController

- (IBAction)OriginalButtonPressed:(id)sender {
    
    NSOpenPanel *openPanel = [self giveMeAOpenPanel];
   
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        
        self.originalURL = [openPanel directoryURL];
        [self saveURLToTextFieldAndInPreferences:self.originalURL typ:1];
    }
}

- (IBAction)cloudButtonPressed:(id)sender {
    
    NSOpenPanel *openPanel = [self giveMeAOpenPanel];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        
        self.cloudURL = [openPanel directoryURL];
        [self saveURLToTextFieldAndInPreferences:self.cloudURL typ:2];
    }
}

- (IBAction)loadButtonPressed:(id)sender {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.originalURL = [userDefaults URLForKey:@"FOLDER_1"];
    self.cloudURL = [userDefaults URLForKey:@"FOLDER_2"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.originalURL path]]) {
        self.originalURL = nil;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.cloudURL path]]) {
        self.cloudURL = nil;
    }
    
    self.originalTextField.stringValue = self.originalURL.lastPathComponent;
    self.cloudTextField.stringValue = self.cloudURL.lastPathComponent;
}

- (NSOpenPanel *)giveMeAOpenPanel {
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    
	return openPanel;
}

- (void)saveURLToTextFieldAndInPreferences:(NSURL *)url typ:(int)typ {
 
    //typ  -> 1 = originalFolder & 2 = cloudFolder
    
    NSUserDefaults *userDefaualts = [NSUserDefaults standardUserDefaults];
    
    NSString *theKey = [NSString stringWithFormat:@"FOLDER_%i", typ];
    [userDefaualts setURL:url forKey:theKey];
    
    NSString *displayName = [url lastPathComponent];
    if (typ == 1 ) {
        self.originalTextField.stringValue = displayName;
    } else {
        self.cloudTextField.stringValue = displayName;
    }
    [userDefaualts synchronize];
}

- (IBAction)goButtonPressed:(id)sender {
    
    if (!self.cloudURL || !self.cloudURL) {
        self.infoTextField.stringValue = @"Fehler: Keine 2 Ordner ausgewählt";
        return;
    }
    NSThread *newThread = [[NSThread alloc] initWithTarget:self selector:@selector(startWatchingFolder) object:nil];
    [newThread start];
}

- (void)startWatchingFolder {
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(watchOriginalFolder:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [timer fire];
}

- (void)watchOriginalFolder:(NSTimer *)timer {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *originalObjects = [fileManager contentsOfDirectoryAtPath:self.originalURL.path error:nil];
    
    
    
    for (NSString *string in originalObjects) {
        
        
        // Generate file Equivalents in CLoudFolder
        NSString *newPath = [self.cloudURL URLByAppendingPathComponent:string].path;
        
        BOOL isDirectory = NO;
        NSString *oldPath = [self.originalURL URLByAppendingPathComponent:string].path;
        [fileManager fileExistsAtPath:oldPath isDirectory:&isDirectory];
        
        if (isDirectory) {
            [self manageDirectoryWithOldPath:oldPath andNew:newPath];
            continue;
        }
        
        if ([fileManager fileExistsAtPath:newPath]) {
            continue;
        } else {
            NSString *originalPath = [self.originalURL URLByAppendingPathComponent:string].path;
            
            long long unsigned filesize = [[fileManager attributesOfItemAtPath:oldPath error:nil] fileSize];
            if (filesize > 1000000) {
                NSLog(@"Größe: %llu Name: %@", filesize, [[NSURL fileURLWithPath:oldPath] lastPathComponent]);
                
                NSDictionary *dict = @{@"filePath": newPath,
                                       @"size": @(filesize) };
                NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(calculateProgressOnFile:) object:dict];
                [thread start];
            }
             self.infoTextField.stringValue = [NSString stringWithFormat:@"Copy : %@", [[NSURL fileURLWithPath:newPath] lastPathComponent]];
            [fileManager copyItemAtPath:originalPath toPath:newPath error:nil];
            
           
    
        }
    }
    
    NSArray *cloudObjects = [fileManager contentsOfDirectoryAtPath:self.cloudURL.path error:nil];
    
    if (originalObjects.count == cloudObjects.count) {
        return;
    }
    if (originalObjects.count > cloudObjects.count) {
        //TODO There was an error
        return;
    }
    
    // This means there had been files deleted -> CloudObjects bigger than OriginalObjects
    
    for (NSString *string in cloudObjects) {
        
        NSString *cloudPath = [self.cloudURL URLByAppendingPathComponent:string].path;
        NSString *originalPath = [self.originalURL URLByAppendingPathComponent:string].path;
        
        if (![fileManager fileExistsAtPath:originalPath]) {
            // -> This file isn't existing in the Original FOolder any more
            [fileManager removeItemAtPath:cloudPath error:nil];
        }

    }
}


- (void)manageDirectoryWithOldPath:(NSString *)oldDirectoryPath andNew:(NSString *)newDirectoryPath {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    // Check weather the directory is existing -> if not create one
    
    if (![fileManager fileExistsAtPath:newDirectoryPath isDirectory:nil]) {
        [fileManager createDirectoryAtPath:newDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSArray *folderObjects = [fileManager contentsOfDirectoryAtPath:oldDirectoryPath error:nil];
    
    
    for (NSString *string in folderObjects) {
        
        
        // Generate file Equivalents in CLoudFolder
        NSString *newPath = [[NSURL fileURLWithPath:newDirectoryPath] URLByAppendingPathComponent:string].path;
        
        BOOL isDirectory = NO;
        
        NSString *oldPath = [[NSURL fileURLWithPath:oldDirectoryPath]  URLByAppendingPathComponent:string].path;

        [fileManager fileExistsAtPath:oldPath isDirectory:&isDirectory];
        
        if (isDirectory) {
            [self manageDirectoryWithOldPath:oldPath andNew:newPath];
            continue;
        }
        
        if ([fileManager fileExistsAtPath:newPath]) {
            continue;
        } else {
            long long unsigned filesize = [[fileManager attributesOfItemAtPath:oldPath error:nil] fileSize];
            if (filesize > 1000000) {
                NSLog(@"Größe: %llu Name: %@", filesize, [[NSURL fileURLWithPath:oldPath] lastPathComponent]);
                
                NSDictionary *dict = @{@"filePath": newPath,
                                       @"size": @(filesize) };
                NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(calculateProgressOnFile:) object:dict];
                [thread start];
            }
            self.infoTextField.stringValue = [NSString stringWithFormat:@"Copy : %@", [[NSURL fileURLWithPath:newPath] lastPathComponent]];
            [fileManager copyItemAtPath:oldPath toPath:newPath error:nil];
        }
    }
    
    NSArray *cloudObjects = [fileManager contentsOfDirectoryAtPath:newDirectoryPath error:nil];
    
    if (folderObjects.count == cloudObjects.count) {
        return;
    }
    if (folderObjects.count > cloudObjects.count) {
        //TODO There was an error
        return;
    }
    
    // This means there had been files deleted -> CloudObjects bigger than OriginalObjects
    
    for (NSString *string in cloudObjects) {
        
        NSString *cloudPath = [[NSURL fileURLWithPath:newDirectoryPath]  URLByAppendingPathComponent:string].path;
        NSString *originalPath = [[NSURL fileURLWithPath:oldDirectoryPath]  URLByAppendingPathComponent:string].path;
        
        if (![fileManager fileExistsAtPath:originalPath]) {
            // -> This file isn't existing in the Original FOolder any more
            [fileManager removeItemAtPath:cloudPath error:nil];
        }
        
    }
}

- (void)calculateProgressOnFile:(NSDictionary *)data {
    
    // Dic key filePath -> path & size
    self.progressionBar.doubleValue = 0.0;
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.001 target:self selector:@selector(calculateProgressOnFileTimer:) userInfo:data repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [timer fire];
    
}

- (void)calculateProgressOnFileTimer:(NSTimer *)timer {
    
    NSDictionary *data = [timer userInfo];
    
    NSString *filePath = data[@"filePath"];
    NSNumber *size = data[@"size"];
    
    double originalSize = [size doubleValue];
    long long unsigned currentSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    
    double ergebnis = (currentSize / originalSize);
    
    self.progressionBar.doubleValue = ergebnis;
    
    if (ergebnis == 1) {
        [timer invalidate];
    }
}






@end
