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
    _x = [[SignalSource alloc] initWithName:@"x"];
    _y = [[SignalSource alloc] initWithName:@"y"];
    _z = [[SignalSource alloc] initWithName:@"z"];
    _pitch = [[SignalSource alloc] initWithName:@"pitch"];
    _yaw = [[SignalSource alloc] initWithName:@"yaw"];
    _roll = [[SignalSource alloc] initWithName:@"roll"];
    _signals = @{@"x" : _x, @"y" : _y, @"z" : _z, @"pitch" : _pitch, @"yaw" : _yaw, @"roll" : _roll};

    MIDIGenerator * genX = [[MIDIGenerator alloc] initWithName:@"x"];
    MIDIGenerator * genY = [[MIDIGenerator alloc] initWithName:@"y"];
    MIDIGenerator * genZ = [[MIDIGenerator alloc] initWithName:@"z"];
    genX.signal = _x;
    genX.allSignals = _signals;
    genY.signal = _y;
    genY.allSignals = _signals;
    genZ.signal = _z;
    genZ.allSignals = _signals;
    _generators = @{@"x" : genX, @"y" : genY, @"z" : genZ};

//    __weak AppDelegate * _self = self;
//    _x.updateBlock = ^(SignalSource * source, float newValue){
//        NSLog(@"%@", source);
//    };

    self.sendMidi = @NO;

    self.midiCCArray = [NSMutableArray arrayWithArray:@[@(1), @(2), @(3), @(4)]];

    [_xMidiCCCombo setStringValue:@"1"];
//    [_xMidiCCCombo selectItemAtIndex:1];
//    [_xMidiCCCombo selectItemWithObjectValue:@(1)];

    [_sendMidi addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];

    _midiManager = [MIKMIDIDeviceManager sharedDeviceManager];
    
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

- (IBAction)xMidiCCDidChange:(id)sender
{
    NSLog(@"xMidiCCDidChange:new selected value=[%d]%@", (int)[_xMidiCCCombo indexOfSelectedItem], [_xMidiCCCombo stringValue]);

    MIDIGenerator * gen;
    if (sender == _xMidiCCCombo)
    {
        gen = _generators[@"x"];
    }

    int cc = (int)[[_xMidiCCCombo stringValue] integerValue];
    gen.midiCC = cc;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
//            [self.peripheralTableView reloadData];
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
//    DEACentralManager *centralManager = [DEACentralManager sharedService];
//    __weak DEASensorTag *sensorTag = (DEASensorTag *)[centralManager findPeripheral:peripheral];


    self.connectionStatusField.stringValue = @"Disconnected";
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
    NSLog(@"didDiscoverCharacteristicsForService:%@", yservice);

    if (yservice == sensorTag.accelerometer)
    {
        NSLog(@"discovered accelerometer characteristics!");
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
        NSLog(@"discovered gyro characteristics!");
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
        NSLog(@"discovered simplekeys characteristics!");
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
            float xAccel = _accel.x.floatValue;
            _xField.stringValue = [NSString stringWithFormat:@"%0.2f", xAccel];

            _x.value = _accel.x.floatValue;

//            if (_sendMidi.boolValue && (xAccel > 0.01f))
//            {
////                _xAccelDezipper = xAccel;
//                uint32_t ccNumber = (uint32_t)_xMidiCCCombo.stringValue.integerValue;
//                uint32_t ccValue = MIN((int)(64.0f + (xAccel * 2.0f * 127.0f)), 127);
//
//                struct MIDIPacket packet;
//                packet.timeStamp = mach_absolute_time();
//                packet.length = 3;
//                packet.data[0] = 0xb0;
//                packet.data[1] = ccNumber;
//                packet.data[2] = ccValue;
//    //            NSLog(@"x:cc=%d;v=%d", ccNumber, ccValue);
//
//    //            MIKMutableMIDIControlChangeCommand * command = [[MIKMutableMIDIControlChangeCommand alloc] init];
//    //            command.controllerNumber = _xMidiCCCombo.stringValue.integerValue;
//    //            command.controllerValue = MIN((int)(64.0f + (xAccel / 2.0f * 127.0f)), 127);
//
//                MIKMIDICommand * command = [MIKMIDICommand commandWithMIDIPacket:&packet];
//                NSLog(@"%@", command);
//
//                NSError *error = nil;
//                if (![_midiManager sendCommands:@[command] toEndpoint:_selectedDestination error:&error]) {
//                    NSLog(@"Unable to send command %@ to endpoint %@: %@", command, _selectedDestination, error);
//                }
//            }
        }
        else if ([keyPath isEqualToString:@"y"])
        {
            _yField.stringValue = [NSString stringWithFormat:@"%0.2f", [_accel.y floatValue]];
            _y.value = _accel.y.floatValue;
        }
        else if ([keyPath isEqualToString:@"z"])
        {
            _zField.stringValue = [NSString stringWithFormat:@"%0.2f", [_accel.z floatValue]];
            _z.value = _accel.z.floatValue;
        }
        else if ([keyPath isEqualToString:@"period"])
        {
            int pvalue = (int)([_accel.period floatValue] * 10.0);
            NSLog(@"accel period = %d ms", pvalue);
        }

        _r = sqrtf(powf(_x.value, 2.0f) + powf(_y.value, 2.0f) + powf(_z.value, 2.0f));

//        Axr = arccos(Rx/_r);
    }
    else if (object == _gyro)
    {
        if ([keyPath isEqualToString:@"pitch"])
        {
            _pitchField.stringValue = [NSString stringWithFormat:@"%0.2f", [_gyro.pitch floatValue]];
            _pitch.value = _gyro.pitch.floatValue;
        }
        else if ([keyPath isEqualToString:@"yaw"])
        {
            _yawField.stringValue = [NSString stringWithFormat:@"%0.2f", [_gyro.yaw floatValue]];
            _yaw.value = _gyro.yaw.floatValue;
        }
        else if ([keyPath isEqualToString:@"roll"])
        {
            _rollField.stringValue = [NSString stringWithFormat:@"%0.2f", [_gyro.roll floatValue]];
            _roll.value = _gyro.roll.floatValue;
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

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self.name = name;
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
    if (value != _value)
    {
        _previousValue = _value;
        _value = value;

        if (_updateBlock)
        {
            __weak SignalSource * this = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                _updateBlock(this, value);
            });
        }
    }
}

@end

// --------------------------------------------------------------------------------

@implementation MIDIGenerator
{
    MIKMIDIDeviceManager * _midiManager;
    SignalSource * _signal;
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

    __weak id _self = self;
    _signal.updateBlock = ^(SignalSource * source, float newValue){
            [_self processUpdatedSignal:source withNewValue:newValue];
        };
}

- (void)processUpdatedSignal:(SignalSource *)source withNewValue:(float)newValue
{
//    NSLog(@"%@", source);

    // Do nothing if output is disabled.
//    if (!_enabled)
//    {
//        return;
//    }

    if (fabsf(newValue) > 0.01f)// || source.previousValue > 0.01f)
    {
        uint32_t ccValue = MIN((int)(64.0f + (newValue * 2.0f * 127.0f)), 127);

        struct MIDIPacket packet;
        packet.timeStamp = mach_absolute_time();
        packet.length = 3;
        packet.data[0] = 0xb0 | ((_midiChannel - 1) & 0xf);
        packet.data[1] = _midiCC;
        packet.data[2] = ccValue;

        MIKMIDICommand * command = [MIKMIDICommand commandWithMIDIPacket:&packet];
        NSLog(@"%@", command);

        NSError *error = nil;
        if (![_midiManager sendCommands:@[command] toEndpoint:_destination error:&error]) {
            NSLog(@"Unable to send command %@ to endpoint %@: %@", command, _destination, error);
        }
    }
}

@end


