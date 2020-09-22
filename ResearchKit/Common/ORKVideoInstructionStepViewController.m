/*
 Copyright (c) 2017, Oliver Schaefer.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 Hacked version by MBS to make this class work with a category
 */

#import "ORKVideoInstructionStepViewController.h"
#import "ORKVideoInstructionStepResult.h"
#import "AVFoundation/AVFoundation.h"
#import <AVKit/AVKit.h>


@interface ORKRateObservedPlayer : AVPlayer

@end


@implementation ORKRateObservedPlayer {
    id _observer;
}

- (instancetype)initWithPlayerItem:(AVPlayerItem *)item andObserver:(id)observer {
    self = [super initWithPlayerItem:item];
    if (self) {
        _observer = observer;
        [self addObserver:_observer forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:_observer forKeyPath:@"rate"];
}

@end


@implementation ORKVideoInstructionStepViewController {
    Float64 _playbackStoppedTime;
    BOOL _playbackCompleted;
}

- (ORKVideoInstructionStep *)videoInstructionStep {
    NSAssert(self.step == nil || [self.step isKindOfClass:[ORKVideoInstructionStep class]], @"View controller is only valid with a ORKVideoInstructionStep step class.");
    return (ORKVideoInstructionStep *)self.step;
}

- (void)stepDidChange {
    [self setThumbnailImageFromAsset];
    [super stepDidChange];
    _playbackStoppedTime = NAN;
    _playbackCompleted = NO;

    if (self.step && [self isViewLoaded] && [self videoInstructionStep].image) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapRecognizer addTarget:self action:@selector(play)];
        [self.stepView addGestureRecognizer:tapRecognizer];

        if (self.stepView.stepTopContentImage) {
            UIImageView *playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play" inBundle:ORKBundle() compatibleWithTraitCollection:nil]];
            self.stepView.userInteractionEnabled = YES;
            [self.stepView addSubview:playImageView];

            playImageView.translatesAutoresizingMaskIntoConstraints = NO;

            NSLayoutConstraint* xConstraint = [NSLayoutConstraint constraintWithItem:self.stepView.stepContentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:playImageView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
            
            CGFloat yOffSet = ORKStepContainerTopContentHeightForWindow(self.view.window)/2 - playImageView.frame.size.height/2;
            NSLayoutConstraint* yConstraint = [NSLayoutConstraint constraintWithItem:playImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.stepView.stepContentView attribute:NSLayoutAttributeTop multiplier:1 constant:yOffSet];

            [self.stepView addConstraints:@[xConstraint, yConstraint]];
        }
    }
}

- (void)setThumbnailImageFromAsset {
    if ([self videoInstructionStep].image) {
        return;
    }
    if (![self videoInstructionStep].videoURL) {
        self.videoInstructionStep.image = nil;
        return;
    }
    
    [self videoInstructionStep].image = [UIImage imageNamed:@"placeholder"];

    ORKWeakTypeOf(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ORKStrongTypeOf(self) strongSelf = weakSelf;
        AVAsset* asset = [AVAsset assetWithURL:[strongSelf videoInstructionStep].videoURL];
        CMTime duration = [asset duration];
        duration.value = MIN([strongSelf videoInstructionStep].thumbnailTime, duration.value / duration.timescale) * duration.timescale;
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        CGImageRef thumbnailImageRef = [imageGenerator copyCGImageAtTime:duration actualTime:NULL error:NULL];
        UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef];
        CGImageRelease(thumbnailImageRef);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [strongSelf videoInstructionStep].image = thumbnailImage;
            [strongSelf stepDidChange];
        });
    });
}

- (void)play {
    AVAsset* asset = [AVAsset assetWithURL:[self videoInstructionStep].videoURL];
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset];
    ORKRateObservedPlayer* player = [[ORKRateObservedPlayer alloc] initWithPlayerItem:playerItem andObserver:self];
    player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = player;
    
    [self presentViewController:playerViewController animated:true completion:^{
        if (playerViewController.player.status == AVPlayerStatusReadyToPlay) {
            [playerViewController.player play];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath  isEqual: @"rate"]) {
        AVPlayer *player = (AVPlayer*)object;
        if (player.rate == 0) {
            _playbackStoppedTime = CMTimeGetSeconds([player.currentItem currentTime]);
            if (CMTimeGetSeconds(player.currentItem.duration) == _playbackStoppedTime) {
                _playbackCompleted = YES;
            }
        }
    }
}

- (ORKStepResult *)result {
    ORKStepResult *parentResult = [super result];
    if (parentResult) {
        ORKVideoInstructionStepResult *childResult = [[ORKVideoInstructionStepResult alloc]
                                                      initWithIdentifier:self.step.identifier];
        childResult.playbackStoppedTime = _playbackStoppedTime;
        childResult.playbackCompleted = _playbackCompleted;
        parentResult.results = [self.addedResults arrayByAddingObject:childResult] ? : @[childResult];
    }
    return parentResult;
}

@end
