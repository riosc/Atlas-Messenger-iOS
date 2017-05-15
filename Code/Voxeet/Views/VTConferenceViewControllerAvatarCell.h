//
//  VTConferenceViewControllerAvatarCell.h
//  Atlas Messenger
//
//  Created by Coco on 16/01/2017.
//  Copyright © 2017 Layer, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Atlas.h"
@import VoxeetSDK;

@interface VTConferenceViewControllerAvatarCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet VideoRenderer *videoView;
@property (weak, nonatomic) IBOutlet ATLAvatarView *avatarImage;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

//@property (nonatomic, strong) MediaStream *currentStream;

@end
