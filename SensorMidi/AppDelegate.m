//
//  AppDelegate.m
//  SensorMidi
//
//  Created by Chris Reed on 6/1/14.
//  Copyright (c) 2014 Immo Software. All rights reserved.
//

#import "AppDelegate.h"
#import "DEACentralManager.h"
#import "YMSCBPeripheral.h"
#import "DEASensorTag.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    
    DEACentralManager *centralManager = [DEACentralManager initSharedServiceWithDelegate:self];
    centralManager.delegate = self;
//    [self.peripheralTableView reloadData];
    
}

@end
