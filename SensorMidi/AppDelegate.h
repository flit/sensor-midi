//
//  AppDelegate.h
//  SensorMidi
//
//  Created by Chris Reed on 6/1/14.
//  Copyright (c) 2014 Immo Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#include "MIKMIDI/MIKMIDI.h"
#include "DEASensorTag.h"
#include "DEAAccelerometerService.h"
#include "DEAGyroscopeService.h"
#include "DEASimpleKeysService.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (assign) IBOutlet NSWindow *window;

@property IBOutlet NSTextField * connectionStatusField;

@property IBOutlet NSTextField * xField;
@property IBOutlet NSTextField * yField;
@property IBOutlet NSTextField * zField;

@property IBOutlet NSTextField * pitchField;
@property IBOutlet NSTextField * yawField;
@property IBOutlet NSTextField * rollField;

@property IBOutlet NSTextField * keysField;

@property DEASensorTag * sensorTag;
@property DEAAccelerometerService * accel;
@property DEAGyroscopeService * gyro;
@property DEASimpleKeysService * keys;

- (NSArray *)availableDestinations;

- (MIKMIDIDestinationEndpoint *)selectedDestination;
- (void)setSelectedDestination:(id)dest;

@end
