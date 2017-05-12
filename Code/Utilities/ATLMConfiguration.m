//
//  ATLMConfiguration.m
//  Atlas Messenger
//
//  Created by Andrew Mcknight on 5/12/17.
//  Copyright © 2017 Layer, Inc. All rights reserved.
//

#import "ATLMConfiguration.h"

NSString *const ATLMConfigurationNameKey = @"name";
NSString *const ATLMConfigurationAppIDKey = @"app_id";
NSString *const ATLMConfigurationIdentityProviderURLKey = @"identity_provider_url";

@implementation ATLMConfiguration

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (!dictionary) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because the `fileURL` argument was `nil`.", self.class] userInfo:nil];
    }

    self = [super init];
    if (self == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@`.", self.class] userInfo:nil];
    }



    _name = [self extractStringWithKey:ATLMConfigurationNameKey fromConfiguration:dictionary];
    _appID = [self extractURLWithKey:ATLMConfigurationAppIDKey fromConfiguration:dictionary];
    _identityProviderURL = [self extractURLWithKey:ATLMConfigurationIdentityProviderURLKey fromConfiguration:dictionary];

    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Do not use `-[init]. Call the designated initializer '%@' on the `%@` instead.", NSStringFromSelector(@selector(initWithDictionary:)), self.class]
                                 userInfo:nil];
}

+ (instancetype)new
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Do not use `+[new]. Call the designated initializer '%@' on the `%@` instead.", NSStringFromSelector(@selector(initWithDictionary:)), self.class]
                                 userInfo:nil];
}

#pragma mark - Helpers

- (NSString *)extractStringWithKey:(NSString *)key fromConfiguration:(NSDictionary *)configuration
{
    NSString *string = configuration[key];
    if (string == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key in the input file was not set.", self.class, key] userInfo:nil];
    }
    else if ((id)string == [NSNull null]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key value in the input file was `null`.", self.class, key] userInfo:nil];
    }
    else if (![string isKindOfClass:[NSString class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key in the input file was not an NSString.", self.class, key] userInfo:nil];
    }
    return string;
}

- (NSURL *)extractURLWithKey:(NSString *)key fromConfiguration:(NSDictionary *)configuration
{
    NSString *urlString = [self extractStringWithKey:key fromConfiguration:configuration];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key value (`%@`) in the input file was not a valid URL.", self.class, key, urlString] userInfo:nil];
    }
    return url;
}

@end
