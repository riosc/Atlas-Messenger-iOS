//
//  ATLMAuthenticationProvider.m
//  Atlas Messenger
//
//  Created by Kevin Coleman on 5/26/16.
//  Copyright © 2016 Layer, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "ATLMAuthenticationProvider.h"
#import "ATLMHTTPResponseSerializer.h"
#import "ATLMConstants.h"
#import "ATLMConfiguration.h"
#import "ATLMUtilities.h"
#import "ATLMErrors.h"

NSString *const ATLMNameKey = @"ATLMNameKey";
NSString *const ATLMDeviceIDKey = @"ATLMDeviceIDKey";
NSString *const ATLMCredentialsKey = @"ATLMCredentialsKey";
static NSString *const ATLMAtlasIdentityTokenKey = @"identity_token";

NSString *const ATLMListUsersEndpoint = @"/users.json";
NSString *const ATLMSignInEndpoint = @"/sign_in";
NSString *const ATLMAuthenticateEndpoint = @"/authenticate";
NSString *const ATLMSessionsEndpoint = @"/session";

@interface ATLMAuthenticationProvider ();

@property (nonatomic) NSURL *baseURL;
@property (nonatomic) NSURLSession *URLSession;

@end

@implementation ATLMAuthenticationProvider

+ (nonnull instancetype)providerWithBaseURL:(nonnull NSURL *)baseURL layerAppID:(NSURL *)layerAppID
{
    return  [[self alloc] initWithBaseURL:baseURL layerAppID:layerAppID];
}

- (instancetype)initWithConfiguration:(ATLMConfiguration *)configuration
{
    NSURL *appIDURL = configuration.appID;
    NSURL *identityProviderURL = (configuration.identityProviderURL ?: ATLMRailsBaseURL(ATLMEnvironmentProduction));
    
    self = [self initWithBaseURL:identityProviderURL layerAppID:appIDURL];
    return self;
}

- (instancetype)initWithBaseURL:(nonnull NSURL *)baseURL layerAppID:(NSURL *)layerAppID;
{
    if (baseURL == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot initialize %@ with `baseURL` argument being nil", self.class];
    }
    if (layerAppID == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot initialize %@ with `layerAppID` argument being nil", self.class];
    }
    
    self = [super init];
    if (self) {
        _baseURL = baseURL;
        _layerAppID = layerAppID;
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        // X_LAYER_APP_ID is for Legacy Identity Provider
        configuration.HTTPAdditionalHeaders = @{ @"Accept": @"application/json",
                                                 @"X_LAYER_APP_ID": self.layerAppID.absoluteString.lastPathComponent };
        _URLSession = [NSURLSession sessionWithConfiguration:configuration];
    }
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Failed to call designated initializer. Call the designated initializer on the subclass instead."
                                 userInfo:nil];
}

- (void)loginUserWithName:(NSString *)name deviceID:(NSString *)deviceID completion:(void (^)(NSString *userID, NSError *error))completion
{
    NSPersonNameComponentsFormatter *nameFormatter = [[NSPersonNameComponentsFormatter alloc] init];
    NSPersonNameComponents *nameComps = [nameFormatter personNameComponentsFromString:name];
    NSString *givenName = nameComps.givenName;
    NSString *familyName = nameComps.familyName;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:deviceID forKey:@"device_id"];
    [params setObject:[NSUUID UUID].UUIDString forKey:@"password"];
    
    if (familyName) {
        [params setObject:familyName forKey:@"last_name"];
        [params setObject:familyName forKey:@"display_name"];
    }
    
    if (givenName) {
        [params setObject:givenName forKey:@"first_name"];
        [params setObject:givenName forKey:@"display_name"];
    }
    
    NSMutableDictionary *urlParams = [[NSMutableDictionary alloc] init];
    [urlParams setObject:params forKey:@"user"];
    
    NSURL *signInURL = [self.baseURL URLByAppendingPathComponent:ATLMSignInEndpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:signInURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:urlParams options:0 error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[self.URLSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        if (!data) {
            NSError *error = [NSError errorWithDomain:ATLMErrorDomain code:ATLMAuthenticationErrorNoDataTransmitted userInfo:@{NSLocalizedDescriptionKey: @"Expected identity information in the response from the server, but none was received."}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        // TODO: Basic response and content checks — status and length
        NSError *serializationError;
        NSDictionary *rawResponse = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
        if (serializationError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, serializationError);
            });
            return;
        }
        
        NSString *userID = rawResponse[@"user"];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(userID, nil);
        });
    }] resume];
}

- (void)authenticateWithCredentials:(NSDictionary *)credentials nonce:(NSString *)nonce completion:(void (^)(NSString *identityToken, NSError *error))completion
{
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload setObject:nonce forKey:@"nonce"];
    [payload setObject:[credentials objectForKey:@"deviceID"] forKey:@"device_id"];
    
    NSURL *authenticateURL = [self.baseURL URLByAppendingPathComponent:ATLMAuthenticateEndpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:authenticateURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[self.URLSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        if (!data) {
            NSError *error = [NSError errorWithDomain:ATLMErrorDomain code:ATLMAuthenticationErrorNoDataTransmitted userInfo:@{NSLocalizedDescriptionKey: @"Expected identity information in the response from the server, but none was received."}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:credentials forKey:ATLMCredentialsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // TODO: Basic response and content checks — status and length
        NSError *serializationError;
        NSDictionary *rawResponse = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
        if (serializationError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, serializationError);
            });
            return;
        }
        
        // Legacy identity provider uses layer_identity_token
        NSString *identityToken = rawResponse[@"identity_token"] ?: rawResponse[@"layer_identity_token"];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(identityToken, nil);
        });
    }] resume];
}

- (void)refreshAuthenticationWithNonce:(NSString *)nonce completion:(void (^)(NSString *identityToken, NSError *error))completion
{
    NSDictionary *credentials = [[NSUserDefaults standardUserDefaults] objectForKey:ATLMCredentialsKey];
    [self authenticateWithCredentials:credentials nonce:nonce completion:^(NSString * _Nonnull identityToken, NSError * _Nonnull error) {
        completion(identityToken, error);
    }];
}

- (void)getSessionForIdentityToken:(NSString *)identityToken completion:(void (^)(NSString *sessionToken, NSError *error))completion
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:identityToken forKey:@"identity_token"];
    [params setObject:self.layerAppID forKey:@"app_id"];
    
    NSMutableDictionary *urlParams = [[NSMutableDictionary alloc] init];
    [urlParams setObject:params forKey:@"user"];
    
    NSURL *sessionsURL = [self.baseURL URLByAppendingPathComponent:ATLMSessionsEndpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:sessionsURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[self.URLSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        if (!data) {
            NSError *error = [NSError errorWithDomain:ATLMErrorDomain code:ATLMAuthenticationErrorNoDataTransmitted userInfo:@{NSLocalizedDescriptionKey: @"Expected identity information in the response from the server, but none was received."}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        // TODO: Basic response and content checks — status and length
        NSError *serializationError;
        NSDictionary *rawResponse = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
        if (serializationError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, serializationError);
            });
            return;
        }
        
        NSString *sessionToken = rawResponse[@"session_token"];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(sessionToken, nil);
        });
    }] resume];
}

@end
