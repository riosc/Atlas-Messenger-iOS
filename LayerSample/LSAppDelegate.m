//
//  LSAppDelegate.m
//  LayerSample
//
//  Created by Kevin Coleman on 6/10/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "LSAppDelegate.h"

@implementation LSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initializeSDKs];
    
    LSHomeViewController *controller = [[LSHomeViewController alloc] init];
    
    LSNavigationController *navController = [[LSNavigationController alloc] initWithRootViewController:controller];
    
    navController.layerController = self.layerController;
    
    [self.window setRootViewController:navController];
    [self.window makeKeyAndVisible];
    
    return YES;
}

#pragma mark
#pragma mark SDK Initialization Classes
- (void)initializeSDKs
{
    [self setLayerController:[[LSLayerController alloc] init]];
    [self setParseController:[[LSParseController alloc] init]];
}

- (void)setLayerController:(LSLayerController *)layerController
{
    if (_layerController != layerController) {
        _layerController = layerController;
    }
}

- (void)setParseController:(LSParseController *)parseController
{
    if (_parseController != parseController) {
        _parseController = parseController;
    }
}

@end