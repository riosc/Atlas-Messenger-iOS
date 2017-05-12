//
//  ATLMConfiguration.m
//  Atlas Messenger
//
//  Created by Andrew Mcknight on 5/12/17.
//  Copyright © 2017 Layer, Inc. All rights reserved.
//

#import "ATLMConfiguration.h"

static NSString *const ATLMConfigurationNameKey = @"name";
static NSString *const ATLMConfigurationAppIDKey = @"app_id";
static NSString *const ATLMConfigurationIdentityProviderURLKey = @"identity_provider_url";
static NSString *const ATLMConfigurationKeyEndpoints = @"endpoint";
static NSString *const ATLMConfigurationKeyEndpointConfig = @"conf";
static NSString *const ATLMConfigurationKeyEndpointCertificates = @"cert";
static NSString *const ATLMConfigurationKeyEndpointAuthentication = @"auth";
static NSString *const ATLMConfigurationKeyEndpointSynchronization = @"sync";

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

    _name = [self extractStringWithKey:ATLMConfigurationNameKey fromDictionary:dictionary required:YES];
    _appID = [self extractURLWithKey:ATLMConfigurationAppIDKey fromDictionary:dictionary required:YES];
    _identityProviderURL = [self extractURLWithKey:ATLMConfigurationIdentityProviderURLKey fromDictionary:dictionary required:YES];

    NSDictionary *endpointsDict = dictionary[ATLMConfigurationKeyEndpoints];
    if (endpointsDict != nil) {
        _configurationEndpoint = [self extractURLWithKey:ATLMConfigurationKeyEndpointConfig fromDictionary:endpointsDict required:NO];
        _authenticationEndpoint = [self extractURLWithKey:ATLMConfigurationKeyEndpointAuthentication fromDictionary:endpointsDict required:NO];
        _certificatesEndpoint = [self extractURLWithKey:ATLMConfigurationKeyEndpointCertificates fromDictionary:endpointsDict required:NO];
        _synchronizationEndpoint = [self extractURLWithKey:ATLMConfigurationKeyEndpointSynchronization fromDictionary:endpointsDict required:NO];
    }

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

- (NSString *)extractStringWithKey:(NSString *)key fromDictionary:(NSDictionary *)dictionary required:(BOOL)required
{
    NSString *string = dictionary[key];
    if (required && string == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key in the input file was not set.", self.class, key] userInfo:nil];
    }
    else if (required && (id)string == [NSNull null]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key value in the input file was `null`.", self.class, key] userInfo:nil];
    }
    else if (![string isKindOfClass:[NSString class]]) {
        if (required) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key in the input file was not an NSString.", self.class, key] userInfo:nil];
        }
        else {
            return nil;
        }
    }
    return string;
}

- (NSURL *)extractURLWithKey:(NSString *)key fromDictionary:(NSDictionary *)dictionary required:(BOOL)required
{
    NSString *urlString = [self extractStringWithKey:key fromDictionary:dictionary required:required];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url && required) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because `%@` key value (`%@`) in the input file was not a valid URL.", self.class, key, urlString] userInfo:nil];
    }
    return url;
}

@end
