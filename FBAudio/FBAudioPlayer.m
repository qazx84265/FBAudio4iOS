//
//  FBAudioPlayer.m
//  FBAudio
//
//  Created by 123 on 16/2/22.
//  Copyright © 2016年 com.pureLake. All rights reserved.
//

#import "FBAudioPlayer.h"
#import <AudioToolbox/AudioToolbox.h>


#define kAudioBufferDurationInSeconds 1
#define kAudioQueuePreferredBufferNumbers 3

typedef struct {
    UInt64 mPlayPackets;
    AudioFileID mPlayAudioFileID;
    AudioQueueRef mPlayAudioQueue;
    AudioQueueBufferRef mPlayBuffers[kAudioQueuePreferredBufferNumbers];
    AudioStreamBasicDescription mPlayASBD;
    AudioQueueLevelMeterState *mPlayLevels;
    BOOL mIsPlaying;
}PlayState;



@interface FBAudioPlayer() {

}
@end




@implementation FBAudioPlayer


#pragma mark -- init

- (instancetype)init {
    if (self = [super init]) {
        
    }
    
    
    return self;
}


- (void)dealloc {

}



#pragma mark -- player actions

- (void)play {

}


- (void)pause {

}

- (void)stop {

}

@end
