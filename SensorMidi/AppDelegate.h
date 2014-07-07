/*
 * Copyright (c) 2014, Immo Software
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * o Redistributions of source code must retain the above copyright notice, this list
 *   of conditions and the following disclaimer.
 *
 * o Redistributions in binary form must reproduce the above copyright notice, this
 *   list of conditions and the following disclaimer in the documentation and/or
 *   other materials provided with the distribution.
 *
 * o Neither the name of Immo Software nor the names of its contributors may be used
 *   to endorse or promote products derived from this software without specific prior
 *   written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import "MIKMIDI/MIKMIDI.h"
#import "DEASensorTag.h"
#import "DEAAccelerometerService.h"
#import "DEAGyroscopeService.h"
#import "DEASimpleKeysService.h"
#import "SignalSource.h"
#import "MIDIGenerator.h"

/*!
 * Todo list:
 * √ generate angles as signals
 * - rate limit CC generation
 * - add midi generators for all signals?
 * - work out and create ui controls for all generators
 * √ note generation with velocity
 * - synthesize midi output in absence of signal update
 * - low pass filter signal data
 * - optional panic button via sensortag button
 */

/*!
 * @brief Application delegate.
 */
@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, NSComboBoxDataSource>

@property (assign) IBOutlet NSWindow *window;
@property IBOutlet NSTextField * connectionStatusField;
@property IBOutlet NSTextField * xField;
@property IBOutlet NSTextField * yField;
@property IBOutlet NSTextField * zField;
@property IBOutlet NSTextField * xAngleField;
@property IBOutlet NSTextField * yAngleField;
@property IBOutlet NSTextField * zAngleField;
@property IBOutlet NSTextField * pitchField;
@property IBOutlet NSTextField * yawField;
@property IBOutlet NSTextField * rollField;
@property IBOutlet NSTextField * keysField;
@property IBOutlet NSComboBox * xMidiCCCombo;
@property IBOutlet NSComboBox * yMidiCCCombo;
@property IBOutlet NSComboBox * zMidiCCCombo;
@property IBOutlet NSComboBox * xAngleMidiCCCombo;
@property IBOutlet NSComboBox * yAngleMidiCCCombo;
@property IBOutlet NSComboBox * zAngleMidiCCCombo;
@property IBOutlet NSButton * sendMidiCheckbox;
@property IBOutlet NSButton * autoConnectCheckbox;

@property IBOutlet NSMutableArray * midiCCArray;

@property MIKMIDIDeviceManager * midiManager;

@property DEASensorTag * sensorTag;
@property DEAAccelerometerService * accel;
@property DEAGyroscopeService * gyro;
@property DEASimpleKeysService * keys;

@property NSNumber * autoConnect;

@property (readonly) NSDictionary * signals;
@property (readonly) NSDictionary * generators;
@property SignalSource * x;
@property SignalSource * y;
@property SignalSource * z;
@property SignalSource * ax;
@property SignalSource * ay;
@property SignalSource * az;
@property SignalSource * pitch;
@property SignalSource * yaw;
@property SignalSource * roll;

- (NSArray *)availableDestinations;

- (MIKMIDIDestinationEndpoint *)selectedDestination;
- (void)setSelectedDestination:(id)dest;

- (IBAction)midiCCDidChange:(id)sender;

@end
