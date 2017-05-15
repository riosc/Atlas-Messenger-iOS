//
//  VTConferenceCollectionViewCell.h
//  Atlas Messenger
//
//  Created by Daniel Maness on 11/8/16.
//  Copyright © 2016 Layer, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Atlas/Atlas.h>

@interface VTConferenceCollectionViewCell : ATLBaseCollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *roundedBackgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *endedDataView;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;
@property (weak, nonatomic) IBOutlet UIView *avatarsContainerView;
@property (weak, nonatomic) IBOutlet UILabel *liveDurationLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonsViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *participantsContainerHeightConstraint;

@property (strong, nonatomic) NSString *conferenceId;
@property (assign, nonatomic) BOOL hasJoined;

+ (CGFloat)heightOfCellForConfWithState:(BOOL)state andParticipantsCount:(NSInteger)count;
- (void)loadConferenceData:(NSDictionary *)confData;
- (void)updateParticipantStatus:(NSString *)participantId newStatus:(NSString *)newStatus;

@end
