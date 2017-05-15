//
//  ATLMLarryController.h
//  Atlas Messenger
//
//  Created by Daniel Maness on 5/10/17.
//  Copyright © 2017 Layer, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LayerKit/LYRClient.h>

NS_ASSUME_NONNULL_BEGIN

/*
 @abstract A key whose value should be the email address of an authenticating user.
 */
extern NSString * _Nonnull const ATLMEmailKey;

/*
 @abstract A key whose value should be the password of an authenticating user.
 */
extern NSString * _Nonnull const ATLMPasswordKey;

/**
 @abstract The `ATLMAuthenticationProvider` conforms to the `ATLMAuthenticating` protocol. It provides for making requests to the Layer Identity Provider in order to request identity tokens needed of LayerKit authentication.
 */
@interface ATLMLarryController : NSObject

@property (nonatomic, copy, readonly) NSURL *layerAppID;

/**
 @abstract Initializes a `ATLMAuthenticationProvider` with a `ATLMConfiguration`
 */
- (instancetype)initWithConfiguration:(ATLMConfiguration *)configuration;
- (instancetype)initWithBaseURL:(nonnull NSURL *)baseURL layerAppID:(NSURL *)layerAppID NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/**
 @abstract The initializer for the `ATLMAuthenticationProvider`.
 @param baseURL The base url for the Layer Identity provider.
 */
+ (nonnull instancetype)providerWithBaseURL:(nonnull NSURL *)baseURL layerAppID:(nonnull NSURL *)layerAppID;

@end

NS_ASSUME_NONNULL_END
