//
//  LSRegistrationViewController.m
//  QRCodeTest
//
//  Created by Kevin Coleman on 2/15/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import "ATLMRegistrationViewController.h"
#import "ATLLogoView.h"
#import <Atlas/Atlas.h>
#import "ATLMConstants.h"
#import "ATLMUtilities.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "ATLMConstants.h"
#import "ATLMErrors.h"
#import "ATLMUserCredentials.h"

@interface ATLMRegistrationViewController () <UITextFieldDelegate>

@property (nonatomic) ATLLogoView *logoView;
@property (nonatomic) UITextField *nameTextField;
@property (nonatomic) UIButton *loginButton;
@property (nonatomic) NSLayoutConstraint *nameTextFieldBottomConstraint;
@property (nonatomic) NSLayoutConstraint *loginButtonBottomConstraint;

@end

@implementation ATLMRegistrationViewController

CGFloat const ATLMLogoViewBCenterYOffset = 184;
CGFloat const ATLMNameTextFieldWidthRatio = 0.8;
CGFloat const ATLMNameTextFieldHeight = 52;
CGFloat const ATLMNameTextFieldBottomPadding = 20;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.logoView = [[ATLLogoView alloc] init];
    self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.logoView];
    
    self.nameTextField = [[UITextField alloc] init];
    self.nameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameTextField.delegate = self;
    self.nameTextField.placeholder = @"Name";
    self.nameTextField.textAlignment = NSTextAlignmentCenter;
    self.nameTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.nameTextField.layer.borderWidth = 0.5;
    self.nameTextField.layer.cornerRadius = 2;
    self.nameTextField.font = [UIFont systemFontOfSize:20];
    self.nameTextField.returnKeyType = UIReturnKeyNext;
    self.nameTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.nameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.nameTextField ];
    
    self.loginButton = [[UIButton alloc] init];
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loginButton setTitle:@"Start Messaging" forState:UIControlStateNormal];
    self.loginButton.titleLabel.textColor = UIColor.whiteColor;
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:20];
    self.loginButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.loginButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.loginButton.layer.borderWidth = 0.5;
    self.loginButton.layer.cornerRadius = 2;
    self.loginButton.backgroundColor = ATLBlueColor();
    [self.loginButton addTarget:self action:@selector(didTapLoginButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton ];
    
    [self configureLayoutConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.nameTextField becomeFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.loginButtonBottomConstraint.constant = -rect.size.height - ATLMNameTextFieldBottomPadding;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self registerAndAuthenticateUser];
    
    return YES;
}

- (void)registerAndAuthenticateUser
{
    [self.view endEditing:YES];
    
    NSString *name = self.nameTextField.text;
    NSString *deviceID = UIDevice.currentDevice.identifierForVendor.UUIDString;
    ATLMUserCredentials *credentials = [[ATLMUserCredentials alloc] initWithName:name deviceID:deviceID];
    
    if ([self.delegate respondsToSelector:@selector(registrationViewController:didSubmitCredentials:)]) {
        [self.delegate registrationViewController:self didSubmitCredentials:credentials];
    }
}

- (void)didTapLoginButton:(id)sender
{
    [self registerAndAuthenticateUser];
}

- (void)configureLayoutConstraints
{
    // Logo View
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.logoView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.logoView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-ATLMLogoViewBCenterYOffset]];
    
    // Registration View    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.nameTextField attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.nameTextField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:ATLMNameTextFieldWidthRatio constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.nameTextField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:ATLMNameTextFieldHeight]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.nameTextField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.loginButton attribute:NSLayoutAttributeTop multiplier:1.0 constant:-ATLMNameTextFieldBottomPadding]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:ATLMNameTextFieldWidthRatio constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:ATLMNameTextFieldHeight]];
    self.loginButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:self.loginButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-ATLMNameTextFieldBottomPadding];
    [self.view addConstraint:self.loginButtonBottomConstraint];
}

@end
