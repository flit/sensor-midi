//
//  MIKMIDICommand_SubclassMethods.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDICommand.h"

/**
 *  These methods can be called and/or overridden by subclasses of MIKMIDICommand, but are not
 *  otherwise part of the public interface to MIKMIDICommand. They should not be called directly
 *  except by subclasses of MIKMIDICommand.
 */
@interface MIKMIDICommand ()

/**
 *  Registers a subclass of MIKMIDICommand. Registered subclasses will be instantiated and returned
 *  by +[MIKMIDICommand commandWithMIDIPacket:] and +[MIKMIDICommand commandForCommandType:] for
 *  commands they support.
 *
 *  Typically this method should be called in the subclass's +load method.
 *
 *  @note If two subclasses support the same command type, as determined by calling +supportsMIDICommandType:
 *  which one is used is undefined.
 *
 *  @param subclass A subclass of MIKMIDICommand.
 */
+ (void)registerSubclass:(Class)subclass;

/**
 *  Subclasses of MIKMIDICommand must override this method, and return YES for any
 *  MIKMIDICommandType values they support. MIKMIDICommand uses this method to determine which
 *  subclass to use to represent a particular MIDI command type.
 *
 *  @param type An MIKMIDICommandType value.
 *
 *  @return YES if the subclass supports type, NO otherwise.
 */
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type;

/**
 *  The immutable counterpart class of the receiver.
 *
 *  @return A class object for the immutable counterpart class of the receiver, or self
 *  if the receiver is the immutable class in the pair.
 */
+ (Class)immutableCounterpartClass;

/**
 *  The mutable counterpart class of the receiver.
 *
 *  @return A class object for the mutable counterpart class of the receiver, or self
 *  if the receiver is the mutable class in the pair.
 */
+ (Class)mutableCounterpartClass;

/**
 *  Mutable subclasses of MIKMIDICommand must override this method and return YES.
 *  MIKMIDICommand itself implements this and returns NO, so *immutable* subclasses need
 *  not override this method.
 *
 *  @return YES if the receiver is a mutable MIKMIDICommand subclass, NO otherwise.
 */
+ (BOOL)isMutable;

/**
 *  This is provided for subclasses to override. This is the designated initializer
 *  for MIKMIDICommand. For commands created using +[MIKMIDICommand commandForCommandType:],
 *  the packet argument will be NULL.
 *
 *  @param packet A CoreMIDI MIDIPacket pointer. May be NULL.
 *
 *  @return An initialized MIKMIDICommand (or subclass) instance.
 */
- (id)initWithMIDIPacket:(MIDIPacket *)packet;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;

@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

/**
 *  This is the property used internally by MIKMIDICommand to store the raw data for
 *  a MIDI packet. It is essentially the mutable backing store for MIKMIDICommand's
 *  data property. Subclasses may set it. When mutating it, subclasses should manually
 *  call -will/didChangeValueForKey for the data key path.
 */
@property (nonatomic, strong, readwrite) NSMutableData *internalData;

/**
 *  Additional description string to be appended to basic description provided by
 *  -[MIKMIDICommand description]. Subclasses of MIKMIDICommand can override this
 *  to provide a additional description information.
 *
 *  @return A string to be appended to MIKMIDICommand's basic description.
 */
- (NSString *)additionalCommandDescription;

@end

// Subclasses of MIKMIDICommand can and should use this macro to raise an exception
// when the setter for a public property is called on an immutable object.
#define MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION ([NSException raise:NSInternalInconsistencyException format:@"Attempt to mutate immutable %@", NSStringFromClass([self class])])
