//
//  ViewController.m
//  FBAudio
//
//  Created by 123 on 16/2/19.
//  Copyright © 2016年 com.pureLake. All rights reserved.
//

#import "ViewController.h"
#import "FBAudioRecorder.h"
#import <AVFoundation/AVAudioSession.h>

@interface ViewController ()
@property (nonatomic, strong) FBAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (!self.recorder) {
        self.recorder = [[FBAudioRecorder alloc] init];
    }
    
    
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(refreshAudioPower:) userInfo:nil repeats:YES];
    }
}

- (void)dealloc {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (self.recorder) {
        [self.recorder stopRecord];
    }
}

- (void)refreshAudioPower:(NSTimer*)timer {
    float level = [self.recorder audioPowerLevel];
    [self.recordAudioInfoLabel setText:[NSString stringWithFormat:@"power: %.1f", level]];
    
    self.levelView.level = level;
}

- (void)updateBtn {
    [self.recordBtn setTitle:self.recorder.isRecording?@"stop":@"record" forState:UIControlStateNormal];
    self.playBtn.enabled = !self.recorder.isRecording;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)record:(id)sender {
    if (self.recorder.isRecording) {
        [self.recorder stopRecord];
    } else {
        
        [self.recorder startRecord];
        
        [self.recordAudioInfoLabel setText:[NSString stringWithFormat:@"%d ch, %.f hz", (unsigned int)[self.recorder channels], [self.recorder sampleRate]]];
    }
    
    [self updateBtn];
}

- (IBAction)play:(id)sender {
}
@end
