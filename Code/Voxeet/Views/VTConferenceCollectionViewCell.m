 //
//  VTConferenceCollectionViewCell.m
//  Atlas Messenger
//
//  Created by Daniel Maness on 11/8/16.
//  Copyright © 2016 Layer, Inc. All rights reserved.
//

#import "VTConferenceCollectionViewCell.h"

@interface VTConferenceCollectionViewCell ()
@property (nonatomic, strong) NSMutableDictionary *avatarsView;
@property (nonatomic, strong) NSMutableArray *avatarRowsView;
@property (nonatomic, strong) NSMutableArray *horizontalSpacers;
@property (nonatomic, strong) NSMutableArray *verticalSpacers;
@property (nonatomic, strong) NSTimer *stopwatchTimer;
@property (nonatomic, strong) NSDate *startingDate;
@end

@implementation VTConferenceCollectionViewCell
CGFloat const avatarWidth = 35;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.roundedBackgroundView removeFromSuperview];
    
    self.roundedBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.bubbleView addSubview:self.roundedBackgroundView];
    //self.roundedBackgroundView.frame = CGRectMake(0, 0, 250, 160);
    
    NSDictionary *constraintViewsDictionary = @{@"rd":self.roundedBackgroundView};
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[rd]|" options:NSLayoutFormatAlignAllTop metrics:nil views:constraintViewsDictionary];
    
    [NSLayoutConstraint activateConstraints:horizontalConstraints];
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rd]|" options:NSLayoutFormatAlignAllTop metrics:nil views:constraintViewsDictionary];
    
    [NSLayoutConstraint activateConstraints:verticalConstraints];
    
    
    
    [self configureCellForType:ATLIncomingCellType];

    
    self.roundedBackgroundView.layer.borderColor = [UIColor colorWithRed:0.862 green:0.862 blue:0.862 alpha:1.0].CGColor;
    self.roundedBackgroundView.layer.borderWidth = 1;
    self.actionButton.userInteractionEnabled = YES;
    [self.actionButton addTarget:self action:@selector(didTapActionButton:) forControlEvents:UIControlEventTouchUpInside];
    self.actionButton.hidden = YES;
    self.statusLabel.hidden = YES;
    self.statusImage.hidden = YES;
    self.endedDataView.hidden = YES;
    self.liveDurationLabel.hidden = YES;
}

+ (CGFloat)heightOfCellForConfWithState:(BOOL)state andParticipantsCount:(NSInteger)count {
    if (state == false) {
        return 193.0;
    }
    else {
        if (count > 5) {
            return 230.0;
        }
        else {
            return 160.0;
        }
    }
}

+ (void)initialize
{
//    VTConferenceCollectionViewCell *proxy = [self appearance];
//    proxy.bubbleViewColor =  ATLDarkGrayColor();
//    proxy.messageLinkTextColor = ATLRedColor();
}

//+ (CGSize)cellSizeForMessage:(LYRMessage *)message inView:(UIView *)view
//{
//    CGSize size = CGSizeZero;
//    size.width = 100;
//    size.height = 100;
//    return size;
//}
//
//+ (CGFloat)cellHeightForMessage:(LYRMessage *)message inView:(UIView *)view {
//    return 100;
//}
//
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    return CGSizeMake(collectionView.bounds.size.width, 150);
//}
//
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self lyr_incommingCommonInit];
//    }
//    return self;
//}
//
//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    self = [super initWithCoder:aDecoder];
//    if (self) {
//        [self lyr_incommingCommonInit];
//    }
//    return self;
//}
//
//- (void)lyr_incommingCommonInit
//{
//    [self configureCellForType:ATLIncomingCellType];
//}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.conferenceId = nil;
    self.hasJoined = NO;
    
    [self stopStopwatch];
    
    for (UIView *view in self.avatarRowsView) {
        [view removeFromSuperview];
    }
    
    for (UIView *view in self.verticalSpacers) {
        [view removeFromSuperview];
    }
    
    [self.avatarRowsView removeAllObjects];
    [self.avatarsView removeAllObjects];
    [self.horizontalSpacers removeAllObjects];
    [self.verticalSpacers removeAllObjects];
}

- (void)loadConferenceData:(NSDictionary *)confData {
    self.conferenceId = confData[@"confId"];
    
    if (self.conferenceId == nil) {
        self.conferenceId = confData[@"conferenceId"];
    }
    
    if (self.conferenceId != nil) {
        NSNumber *isLive = confData[@"isLive"];
        
        if (isLive != nil) {
            NSArray *participants = confData[@"participants"];
            int participantsCount = 0;
            
            if (participants != nil) {
                participantsCount = (int)participants.count;
            }
            
            [self updateViewWithConferenceState:[isLive boolValue] participantsCount:participantsCount];
            
            if ([isLive boolValue]) {
                NSString *ownStatus = confData[@"ownStatus"];
                if ([ownStatus isEqualToString:@"ON_AIR"] || [ownStatus isEqualToString:@"CONNECTING"]) {
                    // User is already in conf
                    self.statusLabel.text = @"On this call";
                    [self.actionButton setTitle:@"Leave Call" forState:UIControlStateNormal];
                    [self.actionButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:60.0/255.0 blue:60.0/255.0 alpha:1.0] forState:UIControlStateNormal];
                    [self.actionButton setImage:[UIImage imageNamed:@"LeaveCall"] forState:UIControlStateNormal];
                    self.hasJoined = YES;
                }
                else {
                    self.statusLabel.text = @"Call in progress";
                    [self.actionButton setTitle:@"Join Call" forState:UIControlStateNormal];
                    [self.actionButton setTitleColor:[UIColor colorWithRed:35.0/255.0 green:208.0/255.0 blue:116.0/255.0 alpha:1.0] forState:UIControlStateNormal];
                    [self.actionButton setImage:[UIImage imageNamed:@"JoinCall"] forState:UIControlStateNormal];
                    self.hasJoined = NO;
                }
                
                NSNumber *startTime = confData[@"startTime"];
                if (startTime != nil) {
                    // Display stopwatch
                    [self startStopwatchWithStartingTime:startTime.doubleValue];
                }
                [self loadParticipants:participants];
            }
            else {
                if (self.stopwatchTimer != nil) {
                    [self stopStopwatch];
                }

                self.statusLabel.text = @"Call has ended";
                [self.actionButton setTitle:@"New Call" forState:UIControlStateNormal];
                [self.actionButton setTitleColor:[UIColor colorWithRed:37.0/255.0 green:144.0/255.0 blue:237.0/255.0 alpha:1.0] forState:UIControlStateNormal];
                [self.actionButton setImage:[UIImage imageNamed:@"NewCall"] forState:UIControlStateNormal];
                
                NSNumber *duration = confData[@"duration"];
                
                if (duration != nil) {
                    NSTimeInterval doubleDuration = (NSTimeInterval)([duration doubleValue] / 1000.0);
                    self.durationLabel.text = [NSString stringWithFormat:@"Duration: %@", [self stringFromTimeInterval:doubleDuration]];
                }
                NSArray *participants = confData[@"participants"];
                
                self.participantsLabel.text = [self stringFromParticipantsList:participants];
                self.hasJoined = NO;
            }
            self.statusLabel.hidden = NO;
            self.actionButton.hidden = NO;
        }
    }
    else {
        NSLog(@"ERROR: nil conf id");
    }
}

- (void)startStopwatchWithStartingTime:(NSTimeInterval)startingTime {
    self.startingDate = [NSDate dateWithTimeIntervalSince1970:startingTime];
    if (self.stopwatchTimer == nil) {
        self.stopwatchTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(updateStopwatch)
                                                         userInfo:nil
                                                          repeats:YES];
    }
}

- (void)stopStopwatch {
    [self.stopwatchTimer invalidate];
    self.stopwatchTimer = nil;
    self.startingDate = nil;
}

- (void)updateStopwatch {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:self.startingDate];
    
    // Format the elapsed time and set it to the label
    NSString *timeString = [self stopWatchStringFromTimeInterval:timeInterval];
    self.liveDurationLabel.text = timeString;
}

- (void)updateViewWithConferenceState:(BOOL)isLive participantsCount:(int)participantsCount {
    
    if (isLive && self.avatarsContainerView.hidden) {
        self.liveDurationLabel.hidden = !isLive;
        self.statusImage.hidden = !isLive;
        self.avatarsContainerView.hidden = !isLive;
        self.endedDataView.hidden = isLive;
    }
    else if (!isLive && self.avatarsContainerView.hidden == false) {
        self.endedDataView.alpha = 0.0;
        self.endedDataView.hidden = isLive;
        [UIView animateWithDuration:0.3
                              delay:0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.liveDurationLabel.alpha = 0.3;
                             self.statusImage.alpha = 0.3;
                             self.avatarsContainerView.alpha = 0.3;
                             self.endedDataView.alpha = 1.0;
                         }
                         completion:^(BOOL finished){
                             self.liveDurationLabel.hidden = YES;
                             self.statusImage.hidden = YES;
                             self.avatarsContainerView.hidden = YES;
                             self.liveDurationLabel.alpha = 1.0;
                             self.statusImage.alpha = 1.0;
                             self.avatarsContainerView.alpha = 1.0;
                         }];
    }
    
    if (isLive) {
        CGFloat avatarContainerHeight = participantsCount > 5 ? 120 : 50;
        self.participantsContainerHeightConstraint.constant = avatarContainerHeight;
        
        [self.actionButton setTitle:@"Leave Call" forState:UIControlStateNormal];
        [self.actionButton setTitleColor:[UIColor colorWithRed:247.0/255.0 green:60.0/255.0 blue:60.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        self.hasJoined = YES;
    }
    else {
        
         [self.actionButton setTitle:@"New Call" forState:UIControlStateNormal];
         [self.actionButton setTitleColor:[UIColor colorWithRed:37.0/255.0 green:144.0/255.0 blue:237.0/255.0 alpha:1.0] forState:UIControlStateNormal];

         self.hasJoined = NO;
    }
}

- (void)updateParticipantStatus:(NSString *)participantId newStatus:(NSString *)newStatus {
    UIView *avatarView = self.avatarsView[participantId];
    [self updateParticipantView:avatarView withState:newStatus];
}

- (void)updateParticipantView:(UIView *)partView withState:(NSString *)status {
    BOOL boolStatus = NO;
    if ([status isEqualToString:@"CONNECTING"] || [status isEqualToString:@"ON_AIR"]) {
        boolStatus = YES;
    }
    partView.alpha = boolStatus ? 1.0 : 0.5;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    if (hours > 0) {
        return [NSString stringWithFormat:@"%ld hours %ld min %ld sec", (long)hours, (long)minutes, (long)seconds];
    }
    else if (minutes > 0) {
        return [NSString stringWithFormat:@"%ld min %ld sec", (long)minutes, (long)seconds];
    }
    else {
        return [NSString stringWithFormat:@"%ld sec", (long)seconds];
    }
}

- (NSString *)stopWatchStringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    }
    else {
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
}

- (NSString *)stringFromParticipantsList:(NSArray *)participants {
    NSMutableString *participantsList = [[NSMutableString alloc] init];
    [participantsList appendString:@"Participants: "];
    for (int i = 0; i < participants.count; i++) {
        NSString *participant = participants[i];
        [participantsList appendString:participant];
        
        if (i < (int)(participants.count) - 2) {
            [participantsList appendString:@", "];
        }
        else if (i == (int)(participants.count) - 2) {
            [participantsList appendString:@" & "];
        }
    }
    return participantsList;
}

- (void)loadParticipants:(NSArray *)participantsData {
    if (participantsData.count == 0) {
        return;
    }
    if (self.avatarRowsView.count > 0) {
        for (NSDictionary *partData in participantsData) {
            NSString *partId = partData[@"id"];
            NSString *status = partData[@"status"];
            
            if (partId != nil && status != nil) {
                [self updateParticipantStatus:partId newStatus:status];
            }
        }
    }
    else {
        if (self.verticalSpacers == nil) {
            self.verticalSpacers = [[NSMutableArray alloc]init];
        }
        
        int rowCount = 1;
        int firstRowUserCount = (int)participantsData.count;
        
        if (participantsData.count > 5) {
            rowCount = 2;
            firstRowUserCount = (int)(participantsData.count - (participantsData.count / 2));
        }
        
        self.avatarRowsView = [[NSMutableArray alloc]init];
        
        [self.avatarRowsView addObject:[self buildAvatarRowWithAvatars:[participantsData subarrayWithRange:NSMakeRange(0, firstRowUserCount)]]];
        
        if (rowCount == 2) {
            [self.avatarRowsView addObject:[self buildAvatarRowWithAvatars:[participantsData subarrayWithRange:NSMakeRange(firstRowUserCount - 1, participantsData.count - firstRowUserCount)]]];
        }
        
        NSMutableDictionary *constraintViewsDictionary = [[NSMutableDictionary alloc] init];
        
        for (int rowInd = 0; rowInd < self.avatarRowsView.count; rowInd++) {
            UIView *avatarsRowContainer = self.avatarRowsView[rowInd];
            [self.avatarsContainerView addSubview:avatarsRowContainer];
            [constraintViewsDictionary setObject:avatarsRowContainer forKey:[NSString stringWithFormat:@"avc%i", rowInd]];
            
            NSArray *avatarRowContainerSizeConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat: @"H:|[avc%i]|", rowInd] options:NSLayoutFormatAlignAllTop metrics:nil views:constraintViewsDictionary];
            
            [NSLayoutConstraint activateConstraints:avatarRowContainerSizeConstraints];
        }
        
        for (int j = 0; j < rowCount + 1; j++) {
            UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, avatarWidth)];
            spacer.translatesAutoresizingMaskIntoConstraints = NO;
            [self.avatarsContainerView addSubview:spacer];
            [self.verticalSpacers addObject:spacer];
            [constraintViewsDictionary setObject:spacer forKey:[NSString stringWithFormat:@"vs%i", j]];
            
            NSArray *horizontalSpacerPositionningConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|[vs%i]|", j] options:NSLayoutFormatAlignAllTop metrics:nil views:constraintViewsDictionary];
            
            [NSLayoutConstraint activateConstraints:horizontalSpacerPositionningConstraints];
        }
        
        
        NSMutableString *v2Format = [[NSMutableString alloc]init];
        [v2Format appendString:@"V:|[vs0]"];
        for (int rowInd = 0; rowInd < rowCount; rowInd++) {
            [v2Format appendFormat:@"[avc%i(==%f)][vs%i(==vs0)]", rowInd, avatarWidth, rowInd + 1];
        }
        
        [v2Format appendString:@"|"];
        
        NSArray *verticalPositionning2Constraints = [NSLayoutConstraint constraintsWithVisualFormat:v2Format options:NSLayoutFormatAlignAllLeft metrics:nil views:constraintViewsDictionary];
        
        [NSLayoutConstraint activateConstraints:verticalPositionning2Constraints];
    }
}

- (UIView *)buildAvatarRowWithAvatars:(NSArray *)avatarData {
    if (self.avatarsView == nil) {
        self.avatarsView = [[NSMutableDictionary alloc]init];
    }
    if (self.horizontalSpacers == nil) {
        self.horizontalSpacers = [[NSMutableArray alloc]init];
    }
    
    NSMutableDictionary *constraintViewsDictionary = [[NSMutableDictionary alloc]init];
    UIView *avatarsRowContainer = [[UIView alloc]init];
    avatarsRowContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.avatarsContainerView addSubview:avatarsRowContainer];
    
    int ind = 0;
    // Avatar views
    for (NSDictionary *partData in avatarData) {
        /*UIView *avatarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, avatarWidth, avatarWidth)];
        avatarView.backgroundColor = [UIColor darkGrayColor];*/
        UIView *avatarView = nil;
        LYRIdentity *partIdentity = partData[@"lyrUser"];
        if (partIdentity != nil) {
            avatarView = [[ATLAvatarImageView alloc] init];
            avatarView.translatesAutoresizingMaskIntoConstraints = NO;
            ((ATLAvatarImageView *)avatarView).initialsFont = ATLLightFont(17);
            ((ATLAvatarImageView *)avatarView).initialsColor = ATLGrayColor();
            avatarView.backgroundColor = ATLLightGrayColor();
            ((ATLAvatarImageView *)avatarView).avatarItem = (id<ATLAvatarItem>)partIdentity;
        }
        else {
            avatarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, avatarWidth, avatarWidth)];
            avatarView.backgroundColor = [UIColor darkGrayColor];
        }
        avatarView.layer.cornerRadius = avatarWidth / 2.0;
        avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        NSString *partStatus = partData[@"status"];
        if (partStatus != nil) {
            [self updateParticipantView:avatarView withState:partStatus];
        }
        [avatarsRowContainer addSubview:avatarView];
        [self.avatarsView setObject:avatarView forKey:partData[@"id"]];
        [constraintViewsDictionary setObject:avatarView forKey:[NSString stringWithFormat:@"av%i", ind]];
        ind++;
    }
    
    // Spacers
    
    NSUInteger avatarsCount = avatarData.count;
    for (int i = 0; i < avatarsCount + 1; i++) {
        UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, avatarWidth)];
        spacer.translatesAutoresizingMaskIntoConstraints = NO;
        [avatarsRowContainer addSubview:spacer];
        [self.horizontalSpacers addObject:spacer];
        [constraintViewsDictionary setObject:spacer forKey:[NSString stringWithFormat:@"hs%i", i]];
    }
    
    // Constraints
    NSMutableString *hFormat = [[NSMutableString alloc]init];
    NSMutableString *vFormat = [[NSMutableString alloc]init];
    [hFormat appendString:@"H:|[hs0]"];
    [vFormat appendString:@"[hs0]"];
    
    
    for (int av = 0; av < avatarData.count; av++) {
        [hFormat appendFormat:@"-[av%i(==%f)]-[hs%i(==hs0)]", av, avatarWidth, av + 1];
        [vFormat appendFormat:@"[av%i][hs%i]", av, av + 1];
    }
    
    [hFormat appendString:@"|"];
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:hFormat options:NSLayoutFormatAlignAllTop metrics:nil views:constraintViewsDictionary];
    
    [NSLayoutConstraint activateConstraints:horizontalConstraints];
    
    NSArray *verticalCenteringConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[av1(==%f)]|", avatarWidth] options:NSLayoutFormatAlignAllLeft metrics:nil views:constraintViewsDictionary];
    
    
    [NSLayoutConstraint activateConstraints:verticalCenteringConstraints];
    
    
    NSArray *verticalPositionningConstraints = [NSLayoutConstraint constraintsWithVisualFormat:vFormat options:NSLayoutFormatAlignAllCenterY metrics:nil views:constraintViewsDictionary];
    
    [NSLayoutConstraint activateConstraints:verticalPositionningConstraints];
    
    
    return avatarsRowContainer;
}

- (void)updateBubbleWidth:(CGFloat)bubbleWidth {
    /*[super updateBubbleWidth:bubbleWidth];
    self.bubbleWidthConstraint.constant = bubbleWidth;
    [self layoutIfNeeded];*/
}

- (void)didTapActionButton:(id)sender
{
    NSMutableDictionary *confDict = [[NSMutableDictionary alloc] init];
    [confDict setObject:self.conferenceId forKey:@"conferenceId"];
    [confDict setObject:self.actionButton.titleLabel.text forKey:@"actionText"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ConferenceActionButtonTapped" object:self userInfo:confDict];
    
}

@end
