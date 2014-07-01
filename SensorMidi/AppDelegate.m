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

@implementation AppDelegate
{
    MIKMIDIDestinationEndpoint * _selectedDestination;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    
    DEACentralManager *centralManager = [DEACentralManager initSharedServiceWithDelegate:self];
    centralManager.delegate = self;
//    [self.peripheralTableView reloadData];
    [centralManager startScan];
    self.connectionStatusField.stringValue = @"Scanning";
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.sensorTag disconnect];
}

- (NSArray *)availableDestinations
{
    MIKMIDIDeviceManager * deviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
    return [[deviceManager virtualDestinations] mutableCopy];
}

- (MIKMIDIDestinationEndpoint *)selectedDestination
{
    return _selectedDestination;
}

- (void)setSelectedDestination:(id)dest
{
    _selectedDestination = dest;
    NSLog(@"selected dest = %@", dest);
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

        _YMS_PERFORM_ON_MAIN_THREAD(^{
            [accel configPeriod:0];
        })

        for (NSString *key in @[@"x", @"y", @"z"])
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
    if (object == _accel)
    {
        if ([keyPath isEqualToString:@"x"])
        {
            _xField.stringValue = [NSString stringWithFormat:@"%0.2f", [_accel.x floatValue]];
        }
        else if ([keyPath isEqualToString:@"y"])
        {
            _yField.stringValue = [NSString stringWithFormat:@"%0.2f", [_accel.y floatValue]];
        }
        else if ([keyPath isEqualToString:@"z"])
        {
            _zField.stringValue = [NSString stringWithFormat:@"%0.2f", [_accel.z floatValue]];
        }
    }
    else if (object == _gyro)
    {
        if ([keyPath isEqualToString:@"pitch"])
        {
            _pitchField.stringValue = [NSString stringWithFormat:@"%0.2f", [_gyro.pitch floatValue]];
        }
        else if ([keyPath isEqualToString:@"yaw"])
        {
            _yawField.stringValue = [NSString stringWithFormat:@"%0.2f", [_gyro.yaw floatValue]];
        }
        else if ([keyPath isEqualToString:@"roll"])
        {
            _rollField.stringValue = [NSString stringWithFormat:@"%0.2f", [_gyro.roll floatValue]];
        }
    }
    else if (object == _keys)
    {
        _keysField.stringValue = [NSString stringWithFormat:@"%d", [_keys.keyValue intValue]];
    }
}

@end
