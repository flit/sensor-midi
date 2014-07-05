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
    _generators = @{@"x" : genX, @"y" : genY, @"z" : genZ, @"ax" : genAx, @"ay" : genAy, @"az" : genAz};

    self.sendMidi = @NO;

    self.midiCCArray = [NSMutableArray arrayWithArray:@[@(1), @(2), @(3), @(4)]];

    [_xMidiCCCombo setStringValue:@"1"];
    [_yMidiCCCombo setStringValue:@"1"];
    [_zMidiCCCombo setStringValue:@"1"];
    [_xAngleMidiCCCombo setStringValue:@"1"];
    [_yAngleMidiCCCombo setStringValue:@"1"];
    [_zAngleMidiCCCombo setStringValue:@"1"];

    [_sendMidi addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];

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
    if (object == _sendMidi)
    {
        [self.generators enumerateKeysAndObjectsUsingBlock:^(id key, id gen, BOOL * stop){
            [gen setEnabled:_sendMidi.boolValue];
        }];
    }
    else if (object == _accel)
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

// --------------------------------------------------------------------------------

@implementation SignalSource
{
    float _value;
}

- (id)initWithName:(NSString *)name units:(NSString *)units
{
    self = [super init];
    if (self)
    {
        self.name = name;
        self.units = units;
        _value = 0.0f;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<SignalSource:%@=%f>", _name, _value];
}

- (float)value
{
    return _value;
}

- (void)setValue:(float)value
{
    if (isnan(value))
    {
        value = 0.0f;
    }

    if (value != _value)
    {
        [self willChangeValueForKey:@"value"];
        _previousValue = _value;
        _value = value;
        [self didChangeValueForKey:@"value"];

        if (_updateBlock)
        {
            __weak SignalSource * this = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                _updateBlock(this, value);
            });
        }
    }
}

- (NSString *)valueString
{
    if (_units)
    {
        return [NSString stringWithFormat:@"%0.2f %@", _value, _units];
    }
    else
    {
        return [NSString stringWithFormat:@"%0.2f", _value];
    }
}

+ (NSSet *)keyPathsForValuesAffectingValueString
{
    return [NSSet setWithObjects:@"value", nil];
}

@end

// --------------------------------------------------------------------------------

@implementation MIDIGenerator
{
    MIKMIDIDeviceManager * _midiManager;
    SignalSource * _signal;
    uint8_t _lastCC;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self.name = name;
        _midiManager = [MIKMIDIDeviceManager sharedDeviceManager];
        _midiChannel = 1;
        _midiCC = 1;
        _min = 0.0f;
        _max = 1.0f;
        _lastCC = 0;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<MIDIGenerator:%@>", _name];
}

- (SignalSource *)signal
{
    return  _signal;
}

- (void)setSignal:(SignalSource *)signal
{
    if (signal == _signal)
    {
        return;
    }

    _signal = signal;

//    NSLog(@"setting signal %@ on gen %@", signal, self);

    __weak id _self = self;
    _signal.updateBlock = ^(SignalSource * source, float newValue){
            [_self processUpdatedSignal:source withNewValue:newValue];
        };
}

- (void)processUpdatedSignal:(SignalSource *)source withNewValue:(float)newValue
{
//    NSLog(@"gen %@ processUpdatedSignal: %@", self, source);

    // Do nothing if output is disabled.
    if (!_destination)
    {
        return;
    }
    if (!_enabled)
    {
        return;
    }

    if (fabsf(newValue) > 0.01f || source.previousValue > 0.01f)
    {
//        float temp = 64.0f + (newValue * 2.0f * 127.0f);
        float temp = (newValue + _min) * 127.0f / _max;
        uint32_t ccValue = MAX(0, MIN((int)temp, 127));

        if (ccValue == _lastCC)
        {
            return;
        }
        _lastCC = ccValue;

        struct MIDIPacket packet;
        packet.timeStamp = mach_absolute_time();
        packet.length = 3;
        packet.data[0] = 0xb0 | ((_midiChannel - 1) & 0xf);
        packet.data[1] = _midiCC;
        packet.data[2] = ccValue;

        MIKMIDICommand * command = [MIKMIDICommand commandWithMIDIPacket:&packet];
//        NSLog(@"%@", command);

        NSError *error = nil;
        if (![_midiManager sendCommands:@[command] toEndpoint:_destination error:&error]) {
            NSLog(@"Unable to send command %@ to endpoint %@: %@", command, _destination, error);
        }
    }
}

@end


