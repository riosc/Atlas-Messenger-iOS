//
//  ATLMUserCredentials.m
//  Atlas Messenger
//
//  Created by Daniel Maness on 11/10/16.
//  Copyright © 2016 Layer, Inc. All rights reserved.
//

#import "ATLMUserCredentials.h"

static NSString *defaultsNameKey = @"DEFAULTS_NAME";
static NSString *defaultsDeviceIDKey = @"DEFAULTS_DEVICEID";
// https://xkcd.com/221/

@implementation ATLMUserCredentials

- (instancetype)initWithName:(NSString *)name deviceID:(nonnull NSString *)deviceID
{
    self = [super init];
    self.name = name;
    self.deviceID = deviceID;
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Failed to call designated initializer. Call the designated initializer on the subclass instead."
                                 userInfo:nil];
}

- (NSDictionary *)asDictionary {
    return @{@"name": self.name, @"deviceID": self.deviceID};
}
@end
