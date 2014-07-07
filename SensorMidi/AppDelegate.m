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

#import "AppDelegate.h"
#import "DEACentralManager.h"
#import "YMSCBPeripheral.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBDescriptor.h"
#import <mach/mach_time.h>
#import <math.h>

@implementation AppDelegate
{
    MIKMIDIDeviceManager * _midiManager;
    MIKMIDIDestinationEndpoint * _selectedDestination;
    float _r;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _x = [[SignalSource alloc] initWithName:@"x" units:@"g"];
    _y = [[SignalSource alloc] initWithName:@"y" units:@"g"];
    _z = [[SignalSource alloc] initWithName:@"z" units:@"g"];
    _ax = [[SignalSource alloc] initWithName:@"ax" units:@"°"];
    _ay = [[SignalSource alloc] initWithName:@"ay" units:@"°"];
    _az = [[SignalSource alloc] initWithName:@"az" units:@"°"];
    _pitch = [[SignalSource alloc] initWithName:@"pitch" units:@"°/s"];
    _yaw = [[SignalSource alloc] initWithName:@"yaw" units:@"°/s"];
    _roll = [[SignalSource alloc] initWithName:@"roll" units:@"°/s"];
    _signals = @{
            @"x" : _x,
            @"y" : _y,
            @"z" : _z,
            @"ax" : _ax,
            @"ay" : _ay,
            @"az" : _az,
            @"pitch" : _pitch,
            @"yaw" : _yaw,
            @"roll" : _roll
        };

    MIDIGenerator * genX = [[MIDIGenerator alloc] initWithName:@"x"];
    MIDIGenerator * genY = [[MIDIGenerator alloc] initWithName:@"y"];
    MIDIGenerator * genZ = [[MIDIGenerator alloc] initWithName:@"z"];
    MIDIGenerator * genAx = [[MIDIGenerator alloc] initWithName:@"ax"];
    MIDIGenerator * genAy = [[MIDIGenerator alloc] initWithName:@"ay"];
    MIDIGenerator * genAz = [[MIDIGenerator alloc] initWithName:@"az"];
    MIDIGenerator * genPitch = [[MIDIGenerator alloc] initWithName:@"pitch"];
    MIDIGenerator * genYaw = [[MIDIGenerator alloc] initWithName:@"yaw"];
    MIDIGenerator * genRoll = [[MIDIGenerator alloc] initWithName:@"roll"];
    genX.signal = _x;
    genX.allSignals = _signals;
    genX.min = -2.0f;
    genX.max = 2.0f;
    genY.signal = _y;
    genY.allSignals = _signals;
    genY.min = -2.0f;
    genY.max = 2.0f;
    genZ.signal = _z;
    genZ.allSignals = _signals;
    genZ.min = -2.0f;
    genZ.max = 2.0f;
    genAx.signal = _ax;
    genAx.allSignals = _signals;
    genAx.max = 180.0f;
    genAy.signal = _ay;
    genAy.allSignals = _signals;
    genAy.max = 180.0f;
    genAz.signal = _az;
    genAz.allSignals = _signals;
    genAz.max = 180.0f;
    genPitch.signal = _pitch;
    genPitch.allSignals = _signals;
    genPitch.mode = kGenerateNotes;
    genYaw.signal = _yaw;
    genYaw.allSignals = _signals;
    genYaw.mode = kGenerateNotes;
    genRoll.signal = _roll;
    genRoll.allSignals = _signals;
    genRoll.mode = kGenerateNotes;
    _generators = @{
            @"x" : genX,
            @"y" : genY,
            @"z" : genZ,
            @"ax" : genAx,
            @"ay" : genAy,
            @"az" : genAz,
            @"pitch" : genPitch,
            @"yaw" : genYaw,
            @"roll" : genRoll
        };

    self.midiCCArray = [NSMutableArray arrayWithArray:@[@(1), @(2), @(3), @(4)]];

    [_xMidiCCCombo setStringValue:@"1"];
    [_yMidiCCCombo setStringValue:@"1"];
    [_zMidiCCCombo setStringValue:@"1"];
    [_xAngleMidiCCCombo setStringValue:@"1"];
    [_yAngleMidiCCCombo setStringValue:@"1"];
    [_zAngleMidiCCCombo setStringValue:@"1"];

    _midiManager = [MIKMIDIDeviceManager sharedDeviceManager];

    self.autoConnect = @YES;
    DEACentralManager *centralManager = [DEACentralManager initSharedServiceWithDelegate:self];
    centralManager.delegate = self;
    [centralManager startScan];
    self.connectionStatusField.stringValue = @"Scanning";
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.sensorTag disconnect];
}

+ (NSSet *)keyPathsForValuesAffectingAvailableDestinations
{
	return [NSSet setWithObjects:@"midiManager.availableDevices", @"midiManager.virtualDestinations", nil];
}

- (NSArray *)availableDestinations
{
    MIKMIDIDeviceManager * deviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
    NSMutableArray * result = [NSMutableArray array];
    NSArray * devices = [deviceManager.availableDevices mutableCopy];
    for (MIKMIDIDevice * device in devices)
    {
        NSArray * destinations = [device.entities valueForKeyPath:@"@unionOfArrays.destinations"];
//        for (MIKMIDIDestinationEndpoint * dest in destinations)
//        {
//            [result addObject:[NSString stringWithFormat:@"%@: %@", device.name, dest.name]];
//        }
        [result addObjectsFromArray:destinations];
    }
    [result addObjectsFromArray:deviceManager.virtualDestinations];
    return result;
}

- (MIKMIDIDestinationEndpoint *)selectedDestination
{
    return _selectedDestination;
}

- (void)setSelectedDestination:(id)dest
{
    _selectedDestination = dest;
    NSLog(@"selected dest = %@", dest);

    // Update all the generators' destinations.
    [self.generators enumerateKeysAndObjectsUsingBlock:^(id key, id gen, BOOL * stop){
        [gen setDestination:dest];
    }];
}

- (IBAction)midiCCDidChange:(id)sender
{
    NSLog(@"midiCCDidChange:new selected value=[%d]%@", (int)[sender indexOfSelectedItem], [sender stringValue]);

    NSString * genName;
    if (sender == _xMidiCCCombo)
    {
        genName = @"x";
    }
    else if (sender == _yMidiCCCombo)
    {
        genName = @"y";
    }
    else if (sender == _zMidiCCCombo)
    {
        genName = @"z";
    }
    else if (sender == _xAngleMidiCCCombo)
    {
        genName = @"ax";
    }
    else if (sender == _yAngleMidiCCCombo)
    {
        genName = @"ay";
    }
    else if (sender == _zAngleMidiCCCombo)
    {
        genName = @"az";
    }
    MIDIGenerator * gen = _generators[genName];

    int cc = (int)[[sender stringValue] integerValue];
    gen.midiCC = cc;

    NSLog(@"set %@ to cc %d", genName, cc);
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
            break;

        case CBCentralManagerStatePoweredOff:
            break;
            
        case CBCentralManagerStateUnsupported:
            NSLog(@"ERROR: This system does not support Bluetooth 4.0 Low Energy communication. "
                  "Please run this app on a system that either has BLE hardware support or has a BLE USB adapter attached.");
            break;

        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = [centralManager findPeripheral:peripheral];
    yp.delegate = self;

    [yp connect];

    [centralManager stopScan];
    self.connectionStatusField.stringValue = @"Discovered";

}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    DEASensorTag *sensorTag = (DEASensorTag *)[centralManager findPeripheral:peripheral];
    sensorTag.delegate = self;
    self.sensorTag = sensorTag;
    NSLog(@"didConnectPeripheral:%@", sensorTag);
    NSLog(@"services=%@", sensorTag.serviceDict);
//    [sensorTag readRSSI];

    self.connectionStatusField.stringValue = @"Connected";
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.connectionStatusField.stringValue = @"Disconnected";

    if (self.autoConnect.boolValue)
    {
        DEACentralManager *centralManager = [DEACentralManager initSharedServiceWithDelegate:self];
        [centralManager startScan];

        self.connectionStatusField.stringValue = @"Scanning";
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
//    NSLog(@"didDiscoverSerices");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    DEASensorTag *sensorTag = (DEASensorTag *)[centralManager findPeripheral:peripheral];
    YMSCBService * yservice = [sensorTag findService:service];
//    NSLog(@"didDiscoverCharacteristicsForService:%@", yservice);

    if (yservice == sensorTag.accelerometer)
    {
//        NSLog(@"discovered accelerometer characteristics!");
        __weak DEAAccelerometerService * accel = sensorTag.accelerometer;
        self.accel = accel;
        [accel turnOn];
        [accel requestReadPeriod];
        [accel configPeriod:10];

        for (NSString *key in @[@"x", @"y", @"z", @"period"])
        {
            [accel addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
    else if (yservice == sensorTag.gyroscope)
    {
//        NSLog(@"discovered gyro characteristics!");
        DEAGyroscopeService * gyro = sensorTag.gyroscope;
        self.gyro = gyro;
        [gyro turnOn];

        for (NSString *key in @[@"pitch", @"yaw", @"roll"])
        {
            [gyro addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
    else if (yservice == sensorTag.simplekeys)
    {
//        NSLog(@"discovered simplekeys characteristics!");
        DEASimpleKeysService * keys = sensorTag.simplekeys;
        self.keys = keys; // already turned on
        [keys addObserver:self forKeyPath:@"keyValue" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
//    NSLog(@"didDiscoverDescriptorsForCharacteristic:%@", characteristic);
//
//    DEACentralManager *centralManager = [DEACentralManager sharedService];
//    DEASensorTag *sensorTag = (DEASensorTag *)[centralManager findPeripheral:peripheral];
//    YMSCBService * service = [sensorTag findService:characteristic.service];
//    YMSCBCharacteristic * ch = [service findCharacteristic:characteristic];
//    for (__weak YMSCBDescriptor * desc in ch.descriptors)
//    {
//        [desc readValueWithBlock:^(NSData * data, NSError * err){
//            NSLog(@"value for descriptor %@ = %@", desc, data);
//        }];
//    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _accel)
    {
        if ([keyPath isEqualToString:@"x"])
        {
            _x.value = _accel.x.floatValue;
            _xField.stringValue = _x.valueString;
        }
        else if ([keyPath isEqualToString:@"y"])
        {
            _y.value = _accel.y.floatValue;
            _yField.stringValue = _y.valueString;
        }
        else if ([keyPath isEqualToString:@"z"])
        {
            _z.value = _accel.z.floatValue;
            _zField.stringValue = _z.valueString;
        }
        else if ([keyPath isEqualToString:@"period"])
        {
            int pvalue = (int)([_accel.period floatValue] * 10.0);
            NSLog(@"accel period = %d ms", pvalue);
        }

        // Compute angles.
        _r = sqrtf(powf(_x.value, 2.0f) + powf(_y.value, 2.0f) + powf(_z.value, 2.0f));
        _ax.value = acosf(_x.value / _r) * 180.0f / M_PI;
        _ay.value = acosf(_y.value / _r) * 180.0f / M_PI;
        _az.value = acosf(_z.value / _r) * 180.0f / M_PI;

        _xAngleField.stringValue = _ax.valueString;
        _yAngleField.stringValue = _ay.valueString;
        _zAngleField.stringValue = _az.valueString;
    }
    else if (object == _gyro)
    {
        if ([keyPath isEqualToString:@"pitch"])
        {
            _pitch.value = _gyro.pitch.floatValue;
            _pitchField.stringValue = _pitch.valueString;
        }
        else if ([keyPath isEqualToString:@"yaw"])
        {
            _yaw.value = _gyro.yaw.floatValue;
            _yawField.stringValue = _yaw.valueString;
        }
        else if ([keyPath isEqualToString:@"roll"])
        {
            _roll.value = _gyro.roll.floatValue;
            _rollField.stringValue = _roll.valueString;
        }
    }
    else if (object == _keys)
    {
        _keysField.stringValue = [NSString stringWithFormat:@"%d", [_keys.keyValue intValue]];
    }
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return self.midiCCArray.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [self.midiCCArray[index] stringValue];
}

@end


