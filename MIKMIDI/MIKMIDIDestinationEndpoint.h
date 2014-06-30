//
//  MIKMIDIDestinationEndpoint.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEndpoint.h"

/**
 *  MIKMIDIDestinationEndpoint represents a source (input) MIDI endpoint.
 *  It is essentially an Objective-C wrapper for instances of CoreMIDI's MIDIEndpoint class
 *  which are kMIDIObjectType_Destination type endpoints.
 *
 *  MIDI destination endpoints are contained by MIDI entities, which are in turn contained by MIDI devices.
 *  MIDI messages can be outputed through a destination endpoint using MIKMIDIDeviceManager's
 *  -sendCommands:toEndpoint:error: method.
 *
 *  Note that MIKMIDIDestinationEndpoint does not declare any methods of its own. All its methods can be
 *  found on its superclasses: MIKMIDIEndpoint and MIKMIDIObject.
 *
 *  @see -[MIKMIDIDeviceManager sendCommands:toEndpoint:error:]
 */
@interface MIKMIDIDestinationEndpoint : MIKMIDIEndpoint

@end
