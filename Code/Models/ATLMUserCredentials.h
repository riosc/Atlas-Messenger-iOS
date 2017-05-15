//
//  ATLMUserCredentials.h
//  Atlas Messenger
//
//  Created by Daniel Maness on 11/10/16.
//  Copyright © 2016 Layer, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 @abstract The `ATLMUserCredentials` class is a model for a user's credentials, including email and password.
 */
@interface ATLMUserCredentials : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *deviceID;

/**
 @abstract Designated initializer for `ATLMUserCredentials`
 @param email The user's email
 @param email The user's password
 */
- (instancetype)initWithName:(NSString *)name deviceID:(NSString *)deviceID;

/**
 @abstract Returns the credentials as an NSDictionary
 */
- (NSDictionary *)asDictionary;

@end
NS_ASSUME_NONNULL_END
