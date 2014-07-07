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

#import "SignalSource.h"

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

