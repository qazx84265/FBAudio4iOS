//
//  FBAudioRecorder.m
//  FBAudio
//
//  Created by 123 on 16/2/19.
//  Copyright © 2016年 com.pureLake. All rights reserved.
//

#import "FBAudioRecorder.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioSession.h>

#define kAudioBufferDurationInSeconds 1
#define kAudioQueuePreferredBufferNumbers 3


typedef struct {
    UInt64 mRecordPackets;
    AudioFileID mRecordAudioFileID;
    AudioQueueRef mRecordAudioQueue;
    AudioQueueBufferRef mRecordBuffers[kAudioQueuePreferredBufferNumbers];
    AudioStreamBasicDescription mRecordASBD;
    AudioQueueLevelMeterState *levels;
    BOOL mIsRecording;
}RecordState;




@interface FBAudioRecorder() {
    NSURL *_recordFileUrl;
    
    RecordState *_recordState;
    
    AVAudioSession *_avSession;
    
}
//@property (nonatomic, retain) NSURL *recordFileUrl;

@end





@implementation FBAudioRecorder


#pragma mark -- init

- (instancetype)init {
    if (self = [super init]) {
        _recordState = (RecordState*)malloc(sizeof(RecordState));
        memset(_recordState, 0, sizeof(RecordState));
        _recordState->mIsRecording = NO;
        _recordState->levels = (AudioQueueLevelMeterState*)malloc(sizeof(AudioQueueLevelMeterState) * (_recordState->mRecordASBD.mChannelsPerFrame));
        
        _avSession = [AVAudioSession sharedInstance];
    }
    
    return self;
}


- (void)dealloc {
    if (_recordState->mIsRecording) {
        [self stopRecord];
    }
    
    if (_recordState->levels) {
        free(_recordState->levels);
        _recordState->levels = NULL;
    }
    
    //
    if (_recordState) {
        
        free(_recordState);
        _recordState = NULL;
    }
}


#pragma mark -- interfaces
- (void)startRecord {
    [self startRecordToFile:nil];
}


- (void)startRecordToFile:(NSURL *)fileUrl {
    if (fileUrl == nil || ![fileUrl isFileURL]) {
        fileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"record.caf"]];
    }
    
    _recordFileUrl = fileUrl;
    _recordState->mRecordPackets = 0;
    
    // specify recording audio stream format, kAudioFormatLinearPCM default
    [self configASBD:kAudioFormatLinearPCM];
    
    // create audio queue
    OSStatus err;
    err = AudioQueueNewInput(&(_recordState->mRecordASBD), recordAQCallBack, _recordState, NULL, NULL, 0, &(_recordState->mRecordAudioQueue));
    if (err) {
        printf("Failed to crate record audio queue.\n");
        return;
    }
    
    
    // get the record format back from the queue's audio converter --
    // the file may require a more specific stream description than was necessary to create the encoder.
    UInt32 size = sizeof(_recordState->mRecordASBD);
    err = AudioQueueGetProperty(_recordState->mRecordAudioQueue, kAudioQueueProperty_StreamDescription, &(_recordState->mRecordASBD), &size);
    if (err) {
        printf("Failed to get audio queue's asbd.\n");
    }
    
    // enable the audio power level metering
    UInt32 e = 1;
    UInt32 *meter = &e;
    AudioQueueSetProperty(_recordState->mRecordAudioQueue, kAudioQueueProperty_EnableLevelMetering, meter, sizeof(UInt32));
    
    
    // create record file
    CFURLRef url = CFBridgingRetain(fileUrl);
    err = AudioFileCreateWithURL(url, kAudioFileCAFType, &(_recordState->mRecordASBD), kAudioFileFlags_EraseFile, &(_recordState->mRecordAudioFileID));
    CFRelease(url);
    if (err) {
        printf("Failed to create audio file.\n");
    }
    
    
    // magic cookie
    [self copyMagicCookieToAudioFile:_recordState->mRecordAudioFileID];
    
    
    // allocate and enqueue buffers
    int buffersize = [self computeAQBufferSizeWithASBD:&(_recordState->mRecordASBD) andDuration:kAudioBufferDurationInSeconds];
    
    for (int i=0; i<kAudioQueuePreferredBufferNumbers; i++) {
        AudioQueueAllocateBuffer(_recordState->mRecordAudioQueue, buffersize, &(_recordState->mRecordBuffers[i]));
        AudioQueueEnqueueBuffer(_recordState->mRecordAudioQueue, _recordState->mRecordBuffers[i], 0, NULL);
    }
    
    
    // start queue
    _recordState->mIsRecording = YES;
    err = AudioQueueStart(_recordState->mRecordAudioQueue, NULL);
    if (err) {
        printf("Failed to start audio queue.\n");
    }
}


- (void)stopRecord {
    // end recording
    _recordState->mIsRecording = NO;
    if (AudioQueueStop(_recordState->mRecordAudioQueue, YES)) {
        printf("Failed to stop audio queue.\n");
    }
    
    //a codec may update its cookie at the end of an encoding session, so reapply it to the file now
    [self copyMagicCookieToAudioFile:_recordState->mRecordAudioFileID];
    
    AudioQueueDispose(_recordState->mRecordAudioQueue, true);
    AudioFileClose(_recordState->mRecordAudioFileID);
}


- (BOOL)isRecording {
    return _recordState->mIsRecording;
}






#pragma mark -- intenal methods

/**
 *  Setting up audioStreamBasicDescription with sepecified audio format
 *
 *  @param audioFormatID
 */
- (void)configASBD:(AudioFormatID)audioFormatID {
//    memset(&(_recordState->mRecordASBD), 0, sizeof(_recordState->mRecordASBD));
    
    _recordState->mRecordASBD.mSampleRate = _avSession.sampleRate;
    _recordState->mRecordASBD.mChannelsPerFrame = (UInt32)_avSession.inputNumberOfChannels;
    
    
    _recordState->mRecordASBD.mFormatID = audioFormatID;
    
    if (_recordState->mRecordASBD.mFormatID == kAudioFormatLinearPCM) {
        // if we want pcm, default to signed 16-bit little-endian
        _recordState->mRecordASBD.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
        _recordState->mRecordASBD.mBitsPerChannel = 16;
        _recordState->mRecordASBD.mBytesPerFrame = (_recordState->mRecordASBD.mBitsPerChannel / 8) * _recordState->mRecordASBD.mChannelsPerFrame;
        _recordState->mRecordASBD.mFramesPerPacket = 1;
        _recordState->mRecordASBD.mBytesPerPacket = _recordState->mRecordASBD.mBytesPerFrame * _recordState->mRecordASBD.mFramesPerPacket;
    }
    
    
    realloc(_recordState->levels, sizeof(AudioQueueLevelMeterState) * _recordState->mRecordASBD.mChannelsPerFrame);
}



/**
 *  caculate the audio queue buffer size
 *
 *  @param asbd    <#asbd description#>
 *  @param seconds <#seconds description#>
 *
 *  @return <#return value description#>
 */
- (int)computeAQBufferSizeWithASBD:(AudioStreamBasicDescription*)asbd andDuration:(NSUInteger)seconds {
    int packets, frames, bytes = 0;
    
    frames = (int)ceil(seconds * asbd->mSampleRate);
    
    if (asbd->mBytesPerFrame > 0)
        bytes = frames * asbd->mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (asbd->mBytesPerPacket > 0) {
            maxPacketSize = asbd->mBytesPerPacket;	// constant packet size
        } else {
            UInt32 propertySize = sizeof(maxPacketSize);
            if (AudioQueueGetProperty(_recordState->mRecordAudioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &propertySize) != noErr) {
                printf("couldn't get queue's maximum output packet size.\n");
            }
        }
        
        if (asbd->mFramesPerPacket > 0) {
            packets = frames / asbd->mFramesPerPacket;
        } else {
            packets = frames;	// worst-case scenario: 1 frame in a packet
        }
        
        if (packets == 0) {		// sanity check
            packets = 1;
        }
        
        bytes = packets * maxPacketSize;
    }
    
    return bytes;
}


/**
 *  <#Description#>
 *
 *  @param audioFile <#audioFile description#>
 */
- (void)copyMagicCookieToAudioFile:(AudioFileID)audioFile {
    UInt32 propertySize;
    
    OSStatus status = AudioQueueGetPropertySize(_recordState->mRecordAudioQueue, kAudioQueueProperty_MagicCookie, &propertySize);
    if (status == noErr && propertySize > 0) {
        UInt8 *magicCookie = (UInt8*)malloc(propertySize);
        
        if ((status = AudioQueueGetProperty(_recordState->mRecordAudioQueue, kAudioQueueProperty_MagicCookie, magicCookie, &propertySize)) != noErr) {
            printf("Failed to get audio queue's magic cookie.\n");
            return;
        }
        
        UInt32 magicCookieSize = propertySize;
        UInt32 cookieCanSet;
        status = AudioFileGetPropertyInfo(_recordState->mRecordAudioFileID, kAudioFilePropertyMagicCookieData, NULL, &cookieCanSet);
        if (status == noErr && cookieCanSet) {
            if ((status = AudioFileSetProperty(_recordState->mRecordAudioFileID, kAudioFilePropertyMagicCookieData, magicCookieSize, magicCookie)) != noErr) {
                free(magicCookie);
                printf("Failed to set audio queue's magic cookie.\n");
                return;
            }
        }
        
        free(magicCookie);
    }
}



/**
 *  Recording audio queue callback
 *
 *  @param inUserData   <#inUserData description#>
 *  @param inAQ         <#inAQ description#>
 *  @param inBuffer     <#inBuffer description#>
 *  @param inStartTime  <#inStartTime description#>
 *  @param inNumPackets <#inNumPackets description#>
 *  @param inPacketDesc <#inPacketDesc description#>
 */
void recordAQCallBack(void *								inUserData,
                             AudioQueueRef						inAQ,
                             AudioQueueBufferRef					inBuffer,
                             const AudioTimeStamp *				inStartTime,
                             UInt32								inNumPackets,
                             const AudioStreamPacketDescription*	inPacketDesc) {
    
    RecordState *stateRef = (RecordState*)inUserData;
    
    OSStatus err = noErr;
    if (inNumPackets > 0) {
        err = AudioFileWritePackets(stateRef->mRecordAudioFileID, NO, inBuffer->mAudioDataByteSize, inPacketDesc, stateRef->mRecordPackets, &inNumPackets, inBuffer->mAudioData);
        if ( err == noErr) {
            stateRef->mRecordPackets += inNumPackets;
        } else {
            printf("Failed to save audio data.\n");
        }
    }
    
    if (stateRef->mIsRecording) {
        err = AudioQueueEnqueueBuffer(stateRef->mRecordAudioQueue, inBuffer, 0, NULL);
        if (err) {
            printf("Failed to reenqueue buffer.\n");
        }
    }
}



#pragma mark -- others

- (NSURL*)recordFileUrl {
    return _recordFileUrl;
}


- (Float64)sampleRate {
    return _recordState->mRecordASBD.mSampleRate;
}

- (UInt32)channels {
    return _recordState->mRecordASBD.mChannelsPerFrame;
}

- (float)audioPowerLevel {
    float level = 0.0;
    
    UInt32 data_sz = sizeof(AudioQueueLevelMeterState) * _recordState->mRecordASBD.mChannelsPerFrame;
    OSErr status = AudioQueueGetProperty(_recordState->mRecordAudioQueue, kAudioQueueProperty_CurrentLevelMeterDB, _recordState->levels, &data_sz);
    if (status == noErr && data_sz>0) {
        float sum = 0.0;
        for (int i=0; i<_recordState->mRecordASBD.mChannelsPerFrame; i++) {
            sum += _recordState->levels[i].mPeakPower;
        }
        
        level = sum / _recordState->mRecordASBD.mChannelsPerFrame;
    }
    
    
    return level;
}

@end
