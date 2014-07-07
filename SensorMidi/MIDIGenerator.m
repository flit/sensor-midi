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

#import "MIDIGenerator.h"
#import <mach/mach_time.h>
#import <math.h>

@implementation MIDIGenerator
{
    MIKMIDIDeviceManager * _midiManager;
    SignalSource * _signal;
    uint8_t _lastCC;
    BOOL _isNoteOn;
    uint8_t _noteNumber;
    float _lastNoteTriggerValue;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self.name = name;
        _midiManager = [MIKMIDIDeviceManager sharedDeviceManager];
        _midiChannel = 1;
        _mode = kGenerateCC;
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

    struct MIDIPacket packet;
    packet.timeStamp = mach_absolute_time();
    MIKMIDICommand * command = nil;
    NSError *error = nil;
    if (_mode == kGenerateCC)
    {
        if (fabsf(newValue) > 0.01f || source.previousValue > 0.01f)
        {
            float temp = (newValue + _min) * 127.0f / _max;
            uint32_t ccValue = MAX(0, MIN((int)temp, 127));

            if (ccValue == _lastCC)
            {
                return;
            }
            _lastCC = ccValue;

            packet.length = 3;
            packet.data[0] = 0xb0 | ((_midiChannel - 1) & 0xf);
            packet.data[1] = _midiCC & 0x7f;
            packet.data[2] = ccValue & 0x7f;

            command = [MIKMIDICommand commandWithMIDIPacket:&packet];
    //        NSLog(@"%@", command);
        }
    }
    else if (_mode == kGenerateNotes)
    {
        const float cutoff = 50.0f;
        const float max = 300.0f;
        
        if (_isNoteOn && fabsf(newValue) > (cutoff + _lastNoteTriggerValue))
        {
            // Turn the active note off.
            packet.length = 3;
            packet.data[0] = 0x90 | ((_midiChannel - 1) & 0xf);
            packet.data[1] = _noteNumber & 0x7f;
            packet.data[2] = 0;

            command = [MIKMIDICommand commandWithMIDIPacket:&packet];
            if (![_midiManager sendCommands:@[command] toEndpoint:_destination error:&error]) {
                NSLog(@"Unable to send command %@ to endpoint %@: %@", command, _destination, error);
            }

            _isNoteOn = NO;
        }

        if (!_isNoteOn && fabsf(newValue) >= cutoff)
        {
            float neg = newValue < 0.0f ? -1.0f : 1.0f;
            float temp = fabsf(newValue) - cutoff;
            temp = temp * (127 - 60) / max;
            _noteNumber = 60 + (int)(temp * neg);

            SignalSource * az = (SignalSource *)self.allSignals[@"az"];
            temp = (az.value + 0) * 127.0f / 180.0f;
            int velocity = MAX(0, MIN((int)temp, 127));

            packet.length = 3;
            packet.data[0] = 0x90 | ((_midiChannel - 1) & 0xf);
            packet.data[1] = _noteNumber & 0x7f;
            packet.data[2] = velocity & 0x7f;

            command = [MIKMIDICommand commandWithMIDIPacket:&packet];

            _isNoteOn = YES;
            _lastNoteTriggerValue = newValue;
        }
        else if (_isNoteOn && fabsf(newValue) < (_lastNoteTriggerValue / 2.0f))
        {
            // Turn the active note off.
            packet.length = 3;
            packet.data[0] = 0x90 | ((_midiChannel - 1) & 0xf);
            packet.data[1] = _noteNumber & 0x7f;
            packet.data[2] = 0;

            command = [MIKMIDICommand commandWithMIDIPacket:&packet];

            _isNoteOn = NO;
        }

        if (command)
        {
            NSLog(@"%@", command);
        }
    }

    // Send MIDI packet.
    if (command)
    {
        if (![_midiManager sendCommands:@[command] toEndpoint:_destination error:&error]) {
            NSLog(@"Unable to send command %@ to endpoint %@: %@", command, _destination, error);
        }
    }
}

@end

