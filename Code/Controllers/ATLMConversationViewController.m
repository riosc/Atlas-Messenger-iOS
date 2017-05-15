//
//  ATLMConversationViewController.m
//  Atlas Messenger
//
//  Created by Kevin Coleman on 9/10/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
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

@import Atlas.ATLParticipantPresenting;
@import VoxeetSDK;
@import VoxeetConferenceKit;
#import "Atlas_Messenger-Swift.h"
#import "ATLMConversationViewController.h"
#import "ATLMConversationDetailViewController.h"
#import "ATLMMediaViewController.h"
#import "ATLMLocationViewController.h"
#import "ATLMUtilities.h"
#import "ATLMParticipantTableViewController.h"
#import "LYRIdentity+ATLParticipant.h"
#import "VTConferenceCollectionViewCell.h"

NSString *const VTMIMETypeConference = @"vt/conference";
NSString *const VTConferenceCollectionViewCellIdentifier = @"VTConferenceCollectionViewCell";

static NSDateFormatter *ATLMShortTimeFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return dateFormatter;
}

static NSDateFormatter *ATLMDayOfWeekDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"EEEE"; // Tuesday
    }
    
    return dateFormatter;
}

static NSDateFormatter *ATLMRelativeDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.doesRelativeDateFormatting = YES;
    }
    return dateFormatter;
}

static NSDateFormatter *ATLMThisYearDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"E, MMM dd,"; // Sat, Nov 29,
    }
    return dateFormatter;
}

static NSDateFormatter *ATLMDefaultDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"MMM dd, yyyy,"; // Nov 29, 2013,
    }
    return dateFormatter;
}

typedef NS_ENUM(NSInteger, ATLMDateProximity) {
    ATLMDateProximityToday,
    ATLMDateProximityYesterday,
    ATLMDateProximityWeek,
    ATLMDateProximityYear,
    ATLMDateProximityOther,
};

static ATLMDateProximity ATLMProximityToDate(NSDate *date)
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSCalendarUnit calendarUnits = NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitWeekOfMonth | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *dateComponents = [calendar components:calendarUnits fromDate:date];
    NSDateComponents *todayComponents = [calendar components:calendarUnits fromDate:now];
    if (dateComponents.day == todayComponents.day &&
        dateComponents.month == todayComponents.month &&
        dateComponents.year == todayComponents.year &&
        dateComponents.era == todayComponents.era) {
        return ATLMDateProximityToday;
    }

    NSDateComponents *componentsToYesterday = [NSDateComponents new];
    componentsToYesterday.day = -1;
    NSDate *yesterday = [calendar dateByAddingComponents:componentsToYesterday toDate:now options:0];
    NSDateComponents *yesterdayComponents = [calendar components:calendarUnits fromDate:yesterday];
    if (dateComponents.day == yesterdayComponents.day &&
        dateComponents.month == yesterdayComponents.month &&
        dateComponents.year == yesterdayComponents.year &&
        dateComponents.era == yesterdayComponents.era) {
        return ATLMDateProximityYesterday;
    }

    if (dateComponents.weekOfMonth == todayComponents.weekOfMonth &&
        dateComponents.month == todayComponents.month &&
        dateComponents.year == todayComponents.year &&
        dateComponents.era == todayComponents.era) {
        return ATLMDateProximityWeek;
    }

    if (dateComponents.year == todayComponents.year &&
        dateComponents.era == todayComponents.era) {
        return ATLMDateProximityYear;
    }

    return ATLMDateProximityOther;
}

@interface ATLMConversationViewController () <ATLMConversationDetailViewControllerDelegate, ATLParticipantTableViewControllerDelegate>

@property(nonatomic,strong) LYRMessage* voxeetLayerMessage;
@property(nonatomic, strong) NSString *conversationAlias;
@property(nonatomic, strong) NSString *currentLiveConferenceId;
@property(nonatomic, strong) NSMutableDictionary *currentLiveConferenceData;

@property(nonatomic, strong) NSMutableDictionary *conferenceDataCache;

@property(nonatomic,strong) NSArray<NSLayoutConstraint *>* conferenceVC_vertical_constraints;
@property(nonatomic,strong) NSArray<NSLayoutConstraint *>* conferenceVC_horizontal_constraints;
@property(nonatomic,strong) NSString *conferenceVCVerticalConstraintsMinimize;
@property(nonatomic,strong) NSString *conferenceVCHorizontalConstraintsMinimize;

@property(nonatomic) ATLConversationDataSource *conversationDataSource;

@property(nonatomic, strong) UITapGestureRecognizer *tap;
@property(nonatomic, assign) BOOL isRegisterToAliasEvents;

@property(nonatomic, assign) BOOL isProcessingRequest;
@property(nonatomic, assign) BOOL keyboardOpen;
@property(nonatomic, assign) BOOL keyboardResignBug;

@end

@implementation ATLMConversationViewController

@synthesize voxeetLayerMessage;
@synthesize conferenceDataCache;

NSString *const ATLMConversationViewControllerAccessibilityLabel = @"Conversation View Controller";
NSString *const ATLMDetailsButtonAccessibilityLabel = @"Details Button";
NSString *const ATLMDetailsButtonLabel = @"Details";

+ (instancetype)conversationViewControllerWithLayerController:(ATLMLayerController *)layerController
{
    NSAssert(layerController, @"Layer Controller cannot be nil");
    return [[self alloc] initWithLayerController:layerController];
}

- (instancetype)initWithLayerController:(ATLMLayerController *)layerController
{
    NSAssert(layerController, @"Layer Controller cannot be nil");
    self = [self initWithLayerClient:layerController.layerClient];
    if (self)  {
        _layerController = layerController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.accessibilityLabel = ATLMConversationViewControllerAccessibilityLabel;
    self.dataSource = self;
    self.delegate = self;
    
    if (self.conversation) {
        [self addDetailsButton];
    }
    
    [self.collectionView registerNib:([UINib nibWithNibName:@"VTConferenceCollectionViewCell" bundle:nil]) forCellWithReuseIdentifier:@"VTConferenceCollectionViewCell"];
    
    [self configureUserInterfaceAttributes];
    [self registerNotificationObservers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self configureTitle];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (![self isMovingFromParentViewController]) {
        [self.view resignFirstResponder];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI Configuration methods

- (NSString *)conversationViewController:(ATLConversationViewController *)conversationViewController reuseIdentifierForMessage:(nonnull LYRMessage *)message
{
    NSString *reuseIdentifier;
    if ([message.parts.firstObject.MIMEType isEqualToString:VTMIMETypeConference]) {
        reuseIdentifier = VTConferenceCollectionViewCellIdentifier;
    } else if ([self.layerClient.authenticatedUser.userID isEqualToString:message.sender.userID]) {
        reuseIdentifier = ATLOutgoingMessageCellIdentifier;
    } else {
        reuseIdentifier = ATLIncomingMessageCellIdentifier;
    }
    
    return reuseIdentifier;
}

#pragma mark - Voxeet Configuration

- (void)configureVoxeet
{
    [self.collectionView registerNib:[UINib nibWithNibName:VTConferenceCollectionViewCellIdentifier bundle:nil] forCellWithReuseIdentifier:VTConferenceCollectionViewCellIdentifier];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conferenceActionButtonTapped:) name:<#(nullable NSNotificationName)#> object:<#(nullable id)#>
}

#pragma mark - Accessors

- (void)setConversation:(LYRConversation *)conversation
{
    [super setConversation:conversation];
    [self configureTitle];
}

#pragma mark - ATLConversationViewControllerDelegate

/**
 Atlas - Informs the delegate of a successful message send. Atlas Messenger adds a `Details` button to the navigation bar if this is the first message sent within a new conversation.
 */
- (void)conversationViewController:(ATLConversationViewController *)viewController didSendMessage:(LYRMessage *)message
{
    [self addDetailsButton];
}

/**
 Atlas - Informs the delegate that a message failed to send. Atlas messeneger display an alert view to inform the user of the failure.
 */
- (void)conversationViewController:(ATLConversationViewController *)viewController didFailSendingMessage:(LYRMessage *)message error:(NSError *)error;
{
    NSLog(@"Message Send Failed with Error: %@", error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Messaging Error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

/**
 Atlas - Informs the delegate that a message was selected. Atlas messenger presents an `ATLImageViewController` if the message contains an image.
 */
- (void)conversationViewController:(ATLConversationViewController *)viewController didSelectMessage:(LYRMessage *)message
{
    LYRMessagePart *messagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeImageJPEG);
    if (messagePart) {
        [self presentMediaViewControllerWithMessage:message];
        return;
    }
    messagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeImagePNG);
    if (messagePart) {
        [self presentMediaViewControllerWithMessage:message];
        return;
    }
    messagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeImageGIF);
    if (messagePart) {
        [self presentMediaViewControllerWithMessage:message];
        return;
    }
    messagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeVideoMP4);
    if (messagePart) {
        [self presentMediaViewControllerWithMessage:message];
        return;
    }
    
    messagePart = ATLMessagePartForMIMEType(message, ATLMIMETypeLocation);
    if (messagePart) {
        [self presentLocationViewControllerWithMessage:message];
        return;
    }
}

- (void)presentLocationViewControllerWithMessage:(LYRMessage *)message
{
    ATLMLocationViewController *locationViewController = [[ATLMLocationViewController alloc] initWithMessage:message];
    [self showViewController:locationViewController sender:self];
    
    locationViewController.mapView.scrollEnabled = NO;
}

- (void)presentMediaViewControllerWithMessage:(LYRMessage *)message
{
    ATLMMediaViewController *imageViewController = [[ATLMMediaViewController alloc] initWithMessage:message];
    [self showViewController:imageViewController sender:self];
}

- (void)showViewController:(UIViewController *)viewController sender:(id)sender
{
    // If the `viewController` is a UINavigationController, present it.
    // Do not attempt to push a navigation controller
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        [sender presentViewController:viewController animated:true completion:nil];
        return;
    }
    
    // If `self` is in a navigation controller, push viewController
    // Otherwise present it in a navigation controller
    if (self.navigationController != nil) {
        [self.navigationController pushViewController:viewController animated:true];
    } else {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [sender presentViewController:navigationController animated:true completion:nil];
    }
}

- (void)conversationViewController:(ATLConversationViewController *)viewController didSelectCardsActionSheetIndex:(NSInteger)index
{
    switch (index) {
        case 4:
            [self sendVoxeetCard];
            break;
            
        default:
            break;
    }
}

#pragma mark - ATLConversationViewControllerDataSource

/**
 Atlas - Returns an object conforming to the `ATLParticipant` protocol whose `userID` property matches the supplied identity.
 */
- (id<ATLParticipant>)conversationViewController:(ATLConversationViewController *)conversationViewController participantForIdentity:(nonnull LYRIdentity *)identity
{
    return identity;
}

/**
 Atlas - Returns an `NSAttributedString` object for a given date. The format of this string can be configured to whatever format an application wishes to display.
 */
- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController attributedStringForDisplayOfDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter;
    ATLMDateProximity dateProximity = ATLMProximityToDate(date);
    switch (dateProximity) {
        case ATLMDateProximityToday:
        case ATLMDateProximityYesterday:
            dateFormatter = ATLMRelativeDateFormatter();
            break;
        case ATLMDateProximityWeek:
            dateFormatter = ATLMDayOfWeekDateFormatter();
            break;
        case ATLMDateProximityYear:
            dateFormatter = ATLMThisYearDateFormatter();
            break;
        case ATLMDateProximityOther:
            dateFormatter = ATLMDefaultDateFormatter();
            break;
    }

    NSString *dateString = [dateFormatter stringFromDate:date];
    NSString *timeString = [ATLMShortTimeFormatter() stringFromDate:date];
    
    NSMutableAttributedString *dateAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", dateString, timeString]];
    [dateAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(0, dateAttributedString.length)];
    [dateAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:11] range:NSMakeRange(0, dateAttributedString.length)];
    [dateAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:11] range:NSMakeRange(0, dateString.length)];
    return dateAttributedString;
}

/**
 Atlas - Returns an `NSAttributedString` object for given recipient state. The state string will only be displayed below the latest message that was sent by the currently authenticated user.
 */
- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController attributedStringForDisplayOfRecipientStatus:(NSDictionary *)recipientStatus
{
    NSMutableDictionary *mutableRecipientStatus = [recipientStatus mutableCopy];
    if ([mutableRecipientStatus valueForKey:self.layerClient.authenticatedUser.userID]) {
        [mutableRecipientStatus removeObjectForKey:self.layerClient.authenticatedUser.userID];
    }
    
    NSString *statusString = [NSString new];
    if (mutableRecipientStatus.count > 1) {
        __block NSUInteger readCount = 0;
        __block BOOL delivered = NO;
        __block BOOL sent = NO;
        __block BOOL pending = NO;
        [mutableRecipientStatus enumerateKeysAndObjectsUsingBlock:^(NSString *userID, NSNumber *statusNumber, BOOL *stop) {
            LYRRecipientStatus status = statusNumber.integerValue;
            switch (status) {
                case LYRRecipientStatusInvalid:
                    break;
                case LYRRecipientStatusPending:
                    pending = YES;
                    break;
                case LYRRecipientStatusSent:
                    sent = YES;
                    break;
                case LYRRecipientStatusDelivered:
                    delivered = YES;
                    break;
                case LYRRecipientStatusRead:
                    readCount += 1;
                    break;
            }
        }];
        if (readCount) {
            NSString *participantString = readCount > 1 ? @"Participants" : @"Participant";
            statusString = [NSString stringWithFormat:@"Read by %lu %@", (unsigned long)readCount, participantString];
        } else if (pending) {
            statusString = @"Pending";
        }else if (delivered) {
            statusString = @"Delivered";
        } else if (sent) {
            statusString = @"Sent";
        }
    } else {
        __block NSString *blockStatusString = [NSString new];
        [mutableRecipientStatus enumerateKeysAndObjectsUsingBlock:^(NSString *userID, NSNumber *statusNumber, BOOL *stop) {
            if ([userID isEqualToString:self.layerClient.authenticatedUser.userID]) return;
            LYRRecipientStatus status = statusNumber.integerValue;
            switch (status) {
                case LYRRecipientStatusInvalid:
                    blockStatusString = @"Not Sent";
                    break;
                case LYRRecipientStatusPending:
                    blockStatusString = @"Pending";
                    break;
                case LYRRecipientStatusSent:
                    blockStatusString = @"Sent";
                    break;
                case LYRRecipientStatusDelivered:
                    blockStatusString = @"Delivered";
                    break;
                case LYRRecipientStatusRead:
                    blockStatusString = @"Read";
                    break;
            }
        }];
        statusString = blockStatusString;
    }
    return [[NSAttributedString alloc] initWithString:statusString attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:11]}];
}

#pragma mark - ATLAddressBarControllerDelegate

/**
 Atlas - Informs the delegate that the user tapped the `addContacts` icon in the `ATLAddressBarViewController`. Atlas Messenger presents an `ATLParticipantPickerController`.
 */
- (void)addressBarViewController:(ATLAddressBarViewController *)addressBarViewController didTapAddContactsButton:(UIButton *)addContactsButton
{
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRIdentity class]];
    NSSet *selectedParticipantIDs = [addressBarViewController.selectedParticipants valueForKey:@"userID"];
    if (selectedParticipantIDs) {
        query.predicate = [LYRPredicate predicateWithProperty:@"userID" predicateOperator:LYRPredicateOperatorIsNotIn value:selectedParticipantIDs];
    }
    
    NSError *error;
    NSOrderedSet *identities = [self.layerClient executeQuery:query error:&error];
    if (error) {
        ATLMAlertWithError(error);
    }
    
    ATLMParticipantTableViewController *controller = [ATLMParticipantTableViewController participantTableViewControllerWithParticipants:identities.set sortType:ATLParticipantPickerSortTypeFirstName];
    controller.blockedParticipantIdentifiers = [self.layerClient.policies valueForKey:@"sentByUserID"];
    controller.delegate = self;
    controller.allowsMultipleSelection = NO;
    
    [self showViewController:controller sender:self];
}

/**
 Atlas - Informs the delegate that the user is searching for participants. Atlas Messengers queries for participants whose `fullName` property contains the given search string.
 */
- (void)addressBarViewController:(ATLAddressBarViewController *)addressBarViewController searchForParticipantsMatchingText:(NSString *)searchText completion:(void (^)(NSArray *participants))completion
{
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRIdentity class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"displayName" predicateOperator:LYRPredicateOperatorLike value:[searchText stringByAppendingString:@"%"]];
    [self.layerClient executeQuery:query completion:^(NSOrderedSet<id<ATLParticipant>> * _Nullable resultSet, NSError * _Nullable error) {
        if (resultSet) {
            completion(resultSet.array);
        } else {
            completion([NSArray array]);
        }
    }];
}

/**
 Atlas - Informs the delegate that the user tapped on the `ATLAddressBarViewController` while it was disabled. Atlas Messenger presents an `ATLConversationDetailViewController` in response.
 */
- (void)addressBarViewControllerDidSelectWhileDisabled:(ATLAddressBarViewController *)addressBarViewController
{
    [self detailsButtonTapped];
}

#pragma mark - ATLParticipantTableViewControllerDelegate

/**
 Atlas - Informs the delegate that the user selected an participant. Atlas Messenger in turn, informs the `ATLAddressBarViewController` of the selection.
 */
- (void)participantTableViewController:(ATLParticipantTableViewController *)participantTableViewController didSelectParticipant:(id<ATLParticipant>)participant
{
    [self.addressBarController selectParticipant:participant];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

/**
 Atlas - Informs the delegate that the user is searching for participants. Atlas Messengers queries for participants whose `fullName` property contains the give search string.
 */
- (void)participantTableViewController:(ATLParticipantTableViewController *)participantTableViewController didSearchWithString:(NSString *)searchText completion:(void (^)(NSSet *))completion
{
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRIdentity class]];
    LYRPredicate *searchPredicate = [LYRPredicate predicateWithProperty:@"displayName" predicateOperator:LYRPredicateOperatorLike value:[NSString stringWithFormat:@"%%%@%%", searchText]];
    
    if (self.conversation.participants) {
        LYRPredicate *selectedPredicate = [LYRPredicate predicateWithProperty:@"userID" predicateOperator:LYRPredicateOperatorIsNotIn value:[self.conversation.participants valueForKey:@"userID"]];
        query.predicate = [LYRCompoundPredicate compoundPredicateWithType:LYRCompoundPredicateTypeAnd subpredicates:@[ searchPredicate, selectedPredicate ]];
    } else {
        query.predicate = searchPredicate;
    }

    [self.layerClient executeQuery:query completion:^(NSOrderedSet<id<ATLParticipant>> * _Nullable resultSet, NSError * _Nullable error) {
        if (resultSet) {
            completion(resultSet.set);
        } else {
            completion([NSSet set]);
        }
    }];
}

#pragma mark - LSConversationDetailViewControllerDelegate

/**
 Atlas - Informs the delegate that the user has tapped the `Share My Current Location` button. Atlas Messenger sends a message into the current conversation with the current location.
 */
- (void)conversationDetailViewControllerDidSelectShareLocation:(ATLMConversationDetailViewController *)conversationDetailViewController
{
    [self sendLocationMessage];
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 Atlas - Informs the delegate that the conversation has changed. Atlas Messenger updates its conversation and the current view controller's title in response.
 */
- (void)conversationDetailViewController:(ATLMConversationDetailViewController *)conversationDetailViewController didChangeConversation:(LYRConversation *)conversation
{
    self.conversation = conversation;
    [self configureTitle];
}

#pragma mark - Details Button Actions

- (void)addDetailsButton
{
    if (self.navigationItem.rightBarButtonItem) return;

    UIBarButtonItem *detailsButtonItem = [[UIBarButtonItem alloc] initWithTitle:ATLMDetailsButtonLabel
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(detailsButtonTapped)];
    detailsButtonItem.accessibilityLabel = ATLMDetailsButtonAccessibilityLabel;
    self.navigationItem.rightBarButtonItem = detailsButtonItem;
}

- (void)detailsButtonTapped
{
    ATLMConversationDetailViewController *detailViewController = [ATLMConversationDetailViewController conversationDetailViewControllerWithConversation:self.conversation withLayerController:self.layerController];
    detailViewController.detailDelegate = self;
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - Notification Handlers

- (void)conversationMetadataDidChange:(NSNotification *)notification
{
    if (!self.conversation) return;
    if (!notification.object) return;
    if (![notification.object isEqual:self.conversation]) return;

    [self configureTitle];
}

- (void)conferenceActionButtonTapped:(NSNotification *)notification
{
    
}

#pragma mark - Voxeet methods

- (void)sendVoxeetCard
{
    [VoxeetBridge createWithCompletion:^(NSString * _Nullable conferenceID) {
        if (conferenceID) {
            NSDictionary *confIdDict = [NSDictionary dictionaryWithObject:conferenceID forKey:@"confId"];
            NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:confIdDict];
            LYRMessagePart *messagePart = [LYRMessagePart messagePartWithMIMEType:VTMIMETypeConference data:messageData];
            
            LYRPushNotificationConfiguration *defaultConfiguration = [LYRPushNotificationConfiguration new];
            defaultConfiguration.alert = @"You have a call";
            defaultConfiguration.sound = @"layerbell.caf";
            defaultConfiguration.category = ATLUserNotificationDefaultActionsCategoryIdentifier;
            
            LYRMessageOptions *messageOptions = [LYRMessageOptions new];
            messageOptions.pushNotificationConfiguration = defaultConfiguration;
            
            LYRMessage *messageLayer = [self.layerClient newMessageWithParts:@[ messagePart ] options:messageOptions error:nil];
            
            NSError *error = nil;
            BOOL success = [self.conversation sendMessage:messageLayer error:&error];
            if (success) {
                NSLog(@"Message enqueued for delivery");
            } else {
                NSLog(@"Message send failed with error: %@", error);
            }
        }
    }];
}

#pragma mark - Voxeet delegate methods

- (CGFloat)conversationViewController:(ATLConversationViewController *)viewController heightForMessage:(LYRMessage *)message withCellWidth:(CGFloat)cellWidth {
    if ([message.parts.firstObject.MIMEType isEqual: VTMIMETypeConference]) {
        NSString *confId = [self conferenceIdWithMessage:message];
        
        if ([confId isEqualToString:self.currentLiveConferenceId]) {
            NSDictionary *cachedConfData = self.currentLiveConferenceData;
            NSNumber *confState = cachedConfData[@"isLive"];
            NSArray *participants = cachedConfData[@"participants"];
            
            CGFloat cellHeight = 193;
            if (confState != nil && participants != nil) {
                cellHeight = [VTConferenceCollectionViewCell heightOfCellForConfWithState:confState.boolValue andParticipantsCount:self.conversation.participants.count];
            }
            
            return cellHeight;
        }
        else {
            return 193.0;
        }
    }
    return 0;
}
- (BOOL)updateLiveParticipantsState:(NSArray *)participantsData {
    if (self.currentLiveConferenceData != nil) {
        // Live conference is live and we have live cached data
        // Compare cached participants state to updated data
        
        NSMutableDictionary *userStateBuffer = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *userIdsBuffer = [[NSMutableDictionary alloc] init];
        
        
        if (participantsData != nil && participantsData.count > 0) {
            for (NSDictionary *part in participantsData) {
                NSString *userId = nil;
                NSDictionary *metaData = part[@"metadata"];
                if (metaData != nil) {
                    userId = [metaData objectForKey:@"AtlasId"];
                }
                
                NSString *status = part[@"status"];
                
                if (userId != nil && status != nil) {
                    [userStateBuffer setObject:status forKey:userId];
                }
                
                NSString *voxeetId = part[@"userId"];
                if (userId != nil && voxeetId != nil) {
                    [userIdsBuffer setObject:voxeetId forKey:userId];
                }
            }
        }
        
        NSArray *currentParticipants = [self.currentLiveConferenceData objectForKey:@"participants"];
        if (currentParticipants != nil && currentParticipants.count > 0) {
            for (NSMutableDictionary *part in currentParticipants) {
                NSString *status = part[@"status"];
                NSString *userId = part[@"id"];
                NSString *bufferStatus = userStateBuffer[userId];
                if (bufferStatus != nil && ![status isEqualToString:bufferStatus]) {
                    [part setObject:bufferStatus forKey:@"status"];
                    if ([userId isEqualToString:self.layerClient.authenticatedUser.userID]) {
                        [self.currentLiveConferenceData setObject:bufferStatus forKey:@"ownStatus"];
                    }
                }
                
                NSString *voxeetId = userIdsBuffer[userId];
                if (voxeetId != nil) {
                    [part setObject:voxeetId forKey:@"voxeetId"];
                }
            }
        }
        
        // Update conference view participants states
//        [_conferenceVC updateParticipants:currentParticipants];
        return YES;
    }
    return NO;
}

- (void)conversationViewController:(ATLConversationViewController *)conversationViewController configureCell:(UICollectionViewCell<ATLMessagePresenting> *)cell forMessage:(LYRMessage *)message {
    
    NSString *conferenceId = [self conferenceIdWithMessage:message];
    if (conferenceId != nil) {
        
        ((VTConferenceCollectionViewCell *)cell).conferenceId = conferenceId;
        if ([message.sender.userID isEqualToString:self.layerClient.authenticatedUser.userID]) {
            [((VTConferenceCollectionViewCell *)cell) configureCellForType:ATLOutgoingCellType];
        }
        else {
            [((VTConferenceCollectionViewCell *)cell) configureCellForType:ATLIncomingCellType];
        }
        
        // Checking cache for history info
        NSDictionary *cachedConfData = [self getCachedDataForConferenceId:conferenceId];
        if (cachedConfData == nil) {
            [VoxeetBridge statusWithConferenceID:conferenceId success:^(id json) {
                NSDictionary *jsonDict = (NSDictionary *)json;
                NSMutableDictionary *confData = [self confDataWithStatusData:jsonDict];
                NSNumber *isLive = [confData objectForKey:@"isLive"];
                
                if (isLive != nil && [isLive intValue] == 0) {
                    // If not live, check if previous conference state
                    if ([conferenceId isEqualToString:self.currentLiveConferenceId]) {
                        //                        [self clearCurrentLiveConference];
                    }
                    
                    [self loadHistoryDataForConfId:conferenceId completion:^(NSDictionary *data) {
                        if ([((VTConferenceCollectionViewCell *)cell).conferenceId isEqualToString:conferenceId]) {
                            [self refreshCell:(VTConferenceCollectionViewCell *)cell withConferenceData:data];
                            [self.collectionView.collectionViewLayout invalidateLayout];
                        }
                    }];
                } else {
                    self.currentLiveConferenceId = conferenceId;
                    self.messageInputToolbar.rightAccessoryImage = [UIImage imageNamed:@"AddCall"];
                    
//                    NSArray *participantsArray = confData[@"participants"];
                    //                    [_conferenceVC updateParticipants:participantsArray];
                    
                    self.currentLiveConferenceData = confData;
                    
                    [self refreshCell:(VTConferenceCollectionViewCell *)cell withConferenceData:confData];
                    [self.collectionView.collectionViewLayout invalidateLayout];
                }

            }];
        }
        else {
            [self refreshCell:(VTConferenceCollectionViewCell *)cell withConferenceData:cachedConfData];
        }
    }
}

- (NSMutableDictionary *)confDataWithStatusData:(NSDictionary *)rawData {
    NSMutableDictionary *confData = [[NSMutableDictionary alloc]init];
    
    NSString *conferenceId = rawData[@"conferenceId"];
    [confData setValue:conferenceId forKey:@"confId"];
    
    // Status message extraction
    NSNumber *isLive = [rawData objectForKey:@"isLive"];
    [confData setValue:isLive forKey:@"isLive"];
    
    
    if (isLive != nil && [isLive intValue] == 1) {
        NSString *ownStatus = nil;
        NSMutableArray *participantsArray = [[NSMutableArray alloc] init];
        [confData setObject:participantsArray forKey:@"participants"];
        
        // Creation of 2 buffers dictionary for VoxeetId and currentStatus
        NSMutableDictionary *userStateBuffer = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *userIdsBuffer = [[NSMutableDictionary alloc] init];
        NSArray *participants = [rawData objectForKey:@"participants"];
        if (participants != nil && participants.count > 0) {
            for (NSDictionary *part in participants) {
                NSString *userId = nil;
                NSDictionary *metaData = part[@"metadata"];
                if (metaData != nil) {
                    userId = [metaData objectForKey:@"AtlasId"];
                }
                NSString *voxeetId = part[@"userId"];
                if (userId != nil && voxeetId != nil) {
                    [userIdsBuffer setObject:voxeetId forKey:userId];
                }
                
                NSString *status = part[@"status"];
                
                if (userId != nil && status != nil) {
                    [userStateBuffer setObject:status forKey:userId];
                }
            }
        }
        
        // Creating a dictionary for each conference participant with buffered data
        for (LYRIdentity *lyrPart in self.conversation.participants) {
            NSString *status = userStateBuffer[lyrPart.userID];
            
            if (status == nil) {
                status = @"OUT";
            }
            
            NSString *voxeetId = userIdsBuffer[lyrPart.userID];
            
            NSMutableDictionary *userDict = [[NSMutableDictionary alloc] init];
            [userDict setObject:lyrPart.userID forKey:@"id"];
            [userDict setObject:lyrPart.displayName forKey:@"name"];
            [userDict setObject:status forKey:@"status"];
            [userDict setObject:lyrPart forKey:@"lyrUser"];
            if (voxeetId != nil) {
                [userDict setObject:voxeetId forKey:@"voxeetId"];
            }
            [participantsArray addObject:userDict];
            
            if ([lyrPart.userID isEqualToString:self.layerClient.authenticatedUser.userID]) {
                ownStatus = status;
            }
        }
        
        [confData setObject:ownStatus forKey:@"ownStatus"];
        
        // Starting timestamp management
        NSNumber *startTimestamp = rawData[@"startTimestamp"];
        if (startTimestamp != nil) {
            NSNumber *secondsStart = [NSNumber numberWithDouble:[startTimestamp doubleValue] / 1000.0];
            [confData setObject:secondsStart forKey:@"startTime"];
//            [_conferenceVC startTimestamp:[secondsStart doubleValue]];
        }
    }
    return confData;
}

- (void)loadHistoryDataForConfId:(NSString *)confId completion:(void (^ _Nullable)(NSDictionary *_Nonnull))completion {
    [VoxeetBridge historyWithConferenceID:confId success:^(id json) {
        NSMutableDictionary *confData = [[NSMutableDictionary alloc]init];
        confData[@"confId"] = confId;
        confData[@"isLive"] = [NSNumber numberWithBool:NO];
        
        NSArray *historyArray = (NSArray *)json;
        
        for (NSDictionary *userDict in historyArray) {
            NSNumber *duration = [userDict objectForKey:@"conferenceDuration"];
            if (duration != nil && [confData objectForKey:@"duration"] == nil) {
                [confData setValue:duration forKey:@"duration"];
            }
            
            NSDictionary *metaData = [userDict objectForKey:@"metadata"];
            if (metaData != nil) {
                NSString *userName = [metaData objectForKey:@"AtlasDisplayName"];
                if (userName != nil) {
                    NSMutableArray *users = [confData objectForKey:@"participants"];
                    
                    if (users == nil) {
                        users = [[NSMutableArray alloc]init];
                        [confData setObject:users forKey:@"participants"];
                    }
                    
                    [users addObject:userName];
                }
            }
        }
        
        [self cacheConferenceData:confData];
        completion(confData);
    }];
}

#pragma mark - Voxeet Error AlertView
- (void)callButtonAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Something went wrong with the call." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)refreshCell:(VTConferenceCollectionViewCell *)cell withConferenceData:(NSDictionary *)confData {
    [cell loadConferenceData:confData];
}

#pragma mark - Voxeet Data cache
- (void)cacheConferenceData:(NSDictionary *)conferenceData {
    if (conferenceData[@"confId"] == nil) {
        return;
    }
    
    if (self.conferenceDataCache == nil) {
        self.conferenceDataCache = [[NSMutableDictionary alloc] init];
    }
    
    [self.conferenceDataCache setObject:conferenceData forKey:conferenceData[@"confId"]];
}

- (NSDictionary *)getCachedDataForConferenceId:(NSString *)confId {
    return conferenceDataCache[confId];
}

- (void)clearCurrentLiveConference {
    self.currentLiveConferenceId = nil;
    self.currentLiveConferenceData = nil;
    self.messageInputToolbar.rightAccessoryImage = [UIImage imageNamed:@"AddCallOn"];
}

#pragma mark - Voxeet Conference updated event
- (void)conferenceStatusUpdated:(NSNotification *)notification
{
    NSData *jsonData = notification.userInfo.allValues.firstObject;
    NSError *error = nil;
    
    id object = [NSJSONSerialization JSONObjectWithData:jsonData
                                                options:0
                                                  error:&error];
    
    if (error == nil && [object isKindOfClass:[NSDictionary class]]) {
        id rawConfId = object[@"conferenceId"];
        NSLog(@"conf status updated : %@", object);
        if (rawConfId != nil && rawConfId != [NSNull null]) {
            NSString *confId = (NSString *)rawConfId;
            if (confId != nil && [confId isEqualToString:self.currentLiveConferenceId]) {
                
                // We have a conferenceId and it's the current live conference id
                VTConferenceCollectionViewCell *cell = [self cellForConferenceId:confId];
                
                NSNumber *isLive = object[@"isLive"];
                if (isLive != nil && [isLive boolValue] == NO) {
                    // If conference is no longer alive, clear and load / cache conference history
                    [self clearCurrentLiveConference];
                    
                    [self loadHistoryDataForConfId:confId completion:^(NSDictionary *confData) {
                        [self refreshCell:cell withConferenceData:confData];
                        [self.collectionView.collectionViewLayout invalidateLayout];
                    }];
                }
                else {
                    [self updateLiveParticipantsState:[object objectForKey:@"participants"]];
                    
                    if (cell != nil && self.currentLiveConferenceData != nil) {
                        [self refreshCell:cell withConferenceData:self.currentLiveConferenceData];
                    }
                }
            }
            else {
                NSLog(@"Error : no conferenceId provided on live conference status updated");
            }
        }
    } else {
        // Error.
        [self callButtonAlert];
    }
}

#pragma mark - Voxeet Helper methods

- (NSString *)confIdAtIndexPath:(NSIndexPath *)indexPath {
    LYRMessage *message = [self.conversationDataSource messageAtCollectionViewIndexPath:indexPath];
    if ([message.parts.firstObject.MIMEType isEqual: VTMIMETypeConference]) {
        NSData *messageData = message.parts.firstObject.data;
        if (messageData != nil) {
            NSDictionary *messageDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:messageData];
            if (messageDictionary.allKeys.count > 0) {
                NSString *confId = messageDictionary[@"confId"];
                return confId;
            }
        }
    }
    return nil;
}

- (VTConferenceCollectionViewCell *)cellForConferenceId:(NSString *)conferenceId {
    NSArray *visibleCells = self.collectionView.visibleCells;
    
    for (UICollectionViewCell *cell in visibleCells) {
        if ([cell isKindOfClass:[VTConferenceCollectionViewCell class]]) {
            if ([((VTConferenceCollectionViewCell *)cell).conferenceId isEqualToString:conferenceId]) {
                return (VTConferenceCollectionViewCell *)cell;
            }
        }
    }
    
    return nil;
}

- (NSString *)conferenceIdWithMessage:(LYRMessage *)message {
    if ([message.parts.firstObject.MIMEType isEqual: VTMIMETypeConference]) {
        NSData *messageData = message.parts.firstObject.data;
        if (messageData != nil) {
            NSDictionary *messageDictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:messageData];
            if (messageDictionary.allKeys.count > 0) {
                return messageDictionary[@"confId"];
            }
        }
    }
    
    return nil;
}

#pragma mark - Helpers

- (void)configureTitle
{
    if ([self.conversation.metadata valueForKey:ATLMConversationMetadataNameKey]) {
        NSString *conversationTitle = [self.conversation.metadata valueForKey:ATLMConversationMetadataNameKey];
        if (conversationTitle.length) {
            self.title = conversationTitle;
        } else {
            self.title = [self defaultTitle];
        }    } else {
        self.title = [self defaultTitle];
    }
}

- (NSString *)defaultTitle
{
    if (!self.conversation) {
        return @"New Message";
    }
    
    NSMutableSet *otherParticipants = [self.conversation.participants mutableCopy];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID != %@", self.layerClient.authenticatedUser.userID];
    [otherParticipants filterUsingPredicate:predicate];
    
    if (otherParticipants.count == 0) {
        return @"Personal";
    } else if (otherParticipants.count == 1) {
        LYRIdentity *otherIdentity = [otherParticipants anyObject];
        id<ATLParticipant> participant = [self conversationViewController:self participantForIdentity:otherIdentity];
        return participant ? participant.firstName : @"Message";
    } else if (otherParticipants.count > 1) {
        NSUInteger participantCount = 0;
        id<ATLParticipant> knownParticipant;
        for (LYRIdentity *identity in otherParticipants) {
            id<ATLParticipant> participant = [self conversationViewController:self participantForIdentity:identity];
            if (participant) {
                participantCount += 1;
                knownParticipant = participant;
            }
        }
        if (participantCount == 1) {
            return knownParticipant.firstName;
        } else if (participantCount > 1) {
            return @"Group";
        }
    }
    return @"Message";
}

#pragma mark - Link Tap Handler

- (void)userDidTapLink:(NSNotification *)notification
{
    [[UIApplication sharedApplication] openURL:notification.object];
}

- (void)configureUserInterfaceAttributes
{
    [[ATLIncomingMessageCollectionViewCell appearance] setBubbleViewColor:ATLLightGrayColor()];
    [[ATLIncomingMessageCollectionViewCell appearance] setMessageTextColor:[UIColor blackColor]];
    [[ATLIncomingMessageCollectionViewCell appearance] setMessageLinkTextColor:ATLBlueColor()];
    
    [[ATLOutgoingMessageCollectionViewCell appearance] setBubbleViewColor:ATLBlueColor()];
    [[ATLOutgoingMessageCollectionViewCell appearance] setMessageTextColor:[UIColor whiteColor]];
    [[ATLOutgoingMessageCollectionViewCell appearance] setMessageLinkTextColor:[UIColor whiteColor]];
}

- (void)registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTapLink:) name:ATLUserDidTapLinkNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversationMetadataDidChange:) name:ATLMConversationMetadataDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // Voxeet Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conferenceActionButtonTapped:) name:@"VTConferenceActionButtonTapped" object:nil];
}

#pragma mark - Device Orientation

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
