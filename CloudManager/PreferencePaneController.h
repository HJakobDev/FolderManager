//
//  PreferencePaneController.h
//  CloudManager
//
//  Created by Henri on 29.04.16.
//  Copyright © 2016 Henrik Jakob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface PreferencePaneController : NSObject

// View Connections

@property (weak) IBOutlet NSTextField *originalTextField;
@property (weak) IBOutlet NSTextField *cloudTextField;
@property (weak) IBOutlet NSTextField *infoTextField;
@property (weak) IBOutlet NSProgressIndicator *progressionBar;

// View Actions

- (IBAction)OriginalButtonPressed:(id)sender;
- (IBAction)cloudButtonPressed:(id)sender;
- (IBAction)loadButtonPressed:(id)sender;

- (IBAction)goButtonPressed:(id)sender;

// Objects To be Need

@property (nonatomic, strong) NSURL *originalURL;
@property (nonatomic, strong) NSURL *cloudURL;



@end
