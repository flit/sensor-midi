//
//  AppDelegate.h
//  SensorMidi
//
//  Created by Chris Reed on 6/1/14.
//  Copyright (c) 2014 Immo Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (atomic) IBOutlet NSTextField * connectionStatusField;

@end
