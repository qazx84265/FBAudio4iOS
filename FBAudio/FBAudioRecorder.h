//
//  FBAudioRecorder.h
//  FBAudio
//
//  Created by 123 on 16/2/19.
//  Copyright © 2016年 com.pureLake. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBAudioRecorder : NSObject

@property (nonatomic, readonly) NSURL *recordFileUrl;

- (void)startRecord;
- (void)startRecordToFile:(NSURL*)fileUrl;

- (void)stopRecord;


- (BOOL)isRecording;
- (Float64)sampleRate;
- (UInt32)channels;
- (float)audioPowerLevel;

@end