//
//  LSApplicationController.m
//  LayerSample
//
//  Created by Kevin Coleman on 6/30/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "ATLMApplicationController.h"
//#import "ATLMUtilities.h"
#import <SVProgressHUD/SVProgressHUD.h>

NSString *const ATLMLayerApplicationID = @"LAYER_APP_ID";

NSString *const ATLMConversationMetadataDidChangeNotification = @"LSConversationMetadataDidChangeNotification";
NSString *const ATLMConversationParticipantsDidChangeNotification = @"LSConversationParticipantsDidChangeNotification";
NSString *const ATLMConversationDeletedNotification = @"LSConversationDeletedNotification";

@interface ATLMApplicationController ()

@end

@implementation ATLMApplicationController

+ (instancetype)controllerWithPersistenceManager:(ATLMPersistenceManager *)persistenceManager
{
    NSParameterAssert(persistenceManager);
    return [[self alloc] initWithPersistenceManager:persistenceManager];
}

- (id)initWithPersistenceManager:(ATLMPersistenceManager *)persistenceManager
{
    self = [super init];
    if (self) {
        _layerClient.delegate = self;
        _persistenceManager = persistenceManager;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveLayerClientWillBeginSynchronizationNotification:)
                                                     name:LYRClientWillBeginSynchronizationNotification
                                                   object:_layerClient];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveLayerClientDidFinishSynchronizationNotification:)
                                                     name:LYRClientDidFinishSynchronizationNotification
                                                   object:_layerClient];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setLayerClient:(ATLMLayerClient *)layerClient
{
    _layerClient = layerClient;
    [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"Layer failled to connect with error: %@", error);
        } else {
            NSLog(@"Layer Client connected.");
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLayerClientWillBeginSynchronizationNotification:) name:LYRClientWillBeginSynchronizationNotification object:layerClient];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLayerClientDidFinishSynchronizationNotification:) name:LYRClientDidFinishSynchronizationNotification object:layerClient];
}

- (void)setAPIManager:(ATLMAPIManager *)APIManager
{
    _APIManager = APIManager;
    _APIManager.persistenceManager = self.persistenceManager;
}

#pragma mark - LYRClientDelegate

- (void)layerClient:(LYRClient *)client didReceiveAuthenticationChallengeWithNonce:(NSString *)nonce
{
    NSLog(@"Layer Client did recieve authentication challenge with nonce: %@", nonce);
    ATLMUser *user = self.APIManager.authenticatedSession.user;
    if (!user) return;
    //TODO - Handle Auth Challenge;
}

- (void)layerClient:(LYRClient *)client didAuthenticateAsUserID:(NSString *)userID
{
    NSLog(@"Layer Client did recieve authentication nonce");
}

- (void)layerClientDidDeauthenticate:(LYRClient *)client
{
    [self.APIManager deauthenticate];
    NSLog(@"Layer Client did deauthenticate");
}

- (void)layerClient:(LYRClient *)client objectsDidChange:(NSArray *)changes
{
    NSLog(@"Layer Client objects did change");
    for (NSDictionary *change in changes) {
        id changedObject = change[LYRObjectChangeObjectKey];
        if (![changedObject isKindOfClass:[LYRConversation class]]) continue;

        LYRObjectChangeType changeType = [change[LYRObjectChangeTypeKey] integerValue];
        NSString *changedProperty = change[LYRObjectChangePropertyKey];

        if (changeType == LYRObjectChangeTypeUpdate && [changedProperty isEqualToString:@"metadata"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ATLMConversationMetadataDidChangeNotification object:changedObject];
        }

        if (changeType == LYRObjectChangeTypeUpdate && [changedProperty isEqualToString:@"participants"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ATLMConversationParticipantsDidChangeNotification object:changedObject];
        }

        if (changeType == LYRObjectChangeTypeDelete) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ATLMConversationDeletedNotification object:changedObject];
        }
    }
}

- (void)layerClient:(LYRClient *)client didFailOperationWithError:(NSError *)error
{
    NSLog(@"Layer Client did fail operation with error: %@", error);
}

- (void)layerClient:(LYRClient *)client willAttemptToConnect:(NSUInteger)attemptNumber afterDelay:(NSTimeInterval)delayInterval maximumNumberOfAttempts:(NSUInteger)attemptLimit
{
    if (attemptNumber == 1) {
        [SVProgressHUD showWithStatus:@"Connecting to Layer"];
    } else {
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Connecting to Layer in %lus (%lu of %lu)", (unsigned long)ceil(delayInterval), (unsigned long)attemptNumber, (unsigned long)attemptLimit]];
    }
}

- (void)layerClientDidConnect:(LYRClient *)client
{
    [SVProgressHUD showSuccessWithStatus:@"Connected to Layer"];
}

- (void)layerClient:(LYRClient *)client didLoseConnectionWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Lost Connection: %@", error.localizedDescription]];
}

- (void)layerClientDidDisconnect:(LYRClient *)client
{
    [SVProgressHUD showSuccessWithStatus:@"Disconnected from Layer"];
}

#pragma mark - Notification Handlers

- (void)didReceiveLayerClientWillBeginSynchronizationNotification:(NSNotification *)notification
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didReceiveLayerClientDidFinishSynchronizationNotification:(NSNotification *)notification
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end