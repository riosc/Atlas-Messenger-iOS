//
//  ATLMConfiguration.h
//  Atlas Messenger
//
//  Created by Andrew Mcknight on 5/12/17.
//  Copyright © 2017 Layer, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ATLMConfiguration : NSObject

/**
 @abstract The deserialized value of the `name` found in the input JSON configuration file.
 */
@property (nonatomic, readonly) NSString *name;

/**
 @abstract The deserialized value of the `appID` found in the input JSON configuration file.
 */
@property (nonatomic, readonly) NSURL *appID;

/**
 @abstract The deserialized value of the `identityProviderURL` found in the input JSON configuration file.
 */
@property (nonatomic, readonly) NSURL *identityProviderURL;

@property (nonatomic, readonly, nullable) NSURL *configurationEndpoint;
@property (nonatomic, readonly, nullable) NSURL *certificatesEndpoint;
@property (nonatomic, readonly, nullable) NSURL *authenticationEndpoint;
@property (nonatomic, readonly, nullable) NSURL *synchronizationEndpoint;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
