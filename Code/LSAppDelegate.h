//
//  LSAppDelegate.h
//  LayerSample
//
//  Created by Kevin Coleman on 6/10/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSApplicationController.h"
#import "LSUIConversationListViewController.h"

@interface LSAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) LSApplicationController *applicationController;

@property (nonatomic) LSUIConversationListViewController *viewController;

//------------------------------------
// Conversation List VC Test Config
//------------------------------------

@property (nonatomic) BOOL allowsEditing;

@property (nonatomic) BOOL displaysConversationImage;

@property (nonatomic) BOOL displaysSettingsButton;

@property (nonatomic) Class<LYRUIConversationPresenting> cellClass;

@property (nonatomic, assign) CGFloat rowHeight;

@end
