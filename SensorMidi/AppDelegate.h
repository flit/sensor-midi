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

/*!
 * Todo list:
 * - generate angles as signals
 * - rate limit CC generation
 * - add midi generators for all signals
 * - work out and create ui controls for all generators
 * - note generation with velocity
 */

/*!
 * @brief Application delegate.
 */
@interface SignalSource : NSObject

//! @brief Name of this signal.
@property (nonatomic, copy) NSString * name;

//! @brief Current value for this signal.
@property (nonatomic) float value;

@property (readonly, nonatomic) float previousValue;

//! @brief Block invoked when the signal value changes.
@property (nonatomic, copy) void (^updateBlock)(SignalSource * source, float newValue);

- (id)initWithName:(NSString *)name;

@end

/*!
 * @brief Generates MIDI from a signal.
 */
@interface MIDIGenerator : NSObject

@property (nonatomic, copy) NSString * name;
@property (nonatomic) MIKMIDIDestinationEndpoint * destination;
@property (nonatomic) SignalSource * signal;
@property (nonatomic) NSDictionary * allSignals;
@property (nonatomic, getter=isEnabled) BOOL enabled;

@property (nonatomic) uint8_t midiChannel;
@property (nonatomic) uint8_t midiCC;

- (id)initWithName:(NSString *)name;

- (void)processUpdatedSignal:(SignalSource *)source withNewValue:(float)newValue;

@end

/*!
 * @brief Application delegate.
 */
@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, NSComboBoxDataSource>

@property (assign) IBOutlet NSWindow *window;
@property IBOutlet NSTextField * connectionStatusField;
@property IBOutlet NSTextField * xField;
@property IBOutlet NSTextField * yField;
@property IBOutlet NSTextField * zField;
@property IBOutlet NSTextField * pitchField;
@property IBOutlet NSTextField * yawField;
@property IBOutlet NSTextField * rollField;
@property IBOutlet NSTextField * keysField;
@property IBOutlet NSComboBox * xMidiCCCombo;
@property IBOutlet NSButton * sendMidiCheckbox;

@property IBOutlet NSMutableArray * midiCCArray;

@property MIKMIDIDeviceManager * midiManager;

@property DEASensorTag * sensorTag;
@property DEAAccelerometerService * accel;
@property DEAGyroscopeService * gyro;
@property DEASimpleKeysService * keys;

@property NSNumber * sendMidi;

@property (readonly) NSDictionary * signals;
@property (readonly) NSDictionary * generators;
@property SignalSource * x;
@property SignalSource * y;
@property SignalSource * z;
@property SignalSource * pitch;
@property SignalSource * yaw;
@property SignalSource * roll;

- (NSArray *)availableDestinations;

- (MIKMIDIDestinationEndpoint *)selectedDestination;
- (void)setSelectedDestination:(id)dest;

- (IBAction)xMidiCCDidChange:(id)sender;

@end
