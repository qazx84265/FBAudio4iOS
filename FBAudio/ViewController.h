//
//  ViewController.h
//  FBAudio
//
//  Created by 123 on 16/2/19.
//  Copyright © 2016年 com.pureLake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBAudioVisualizerView.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *recordAudioInfoLabel;
@property (weak, nonatomic) IBOutlet FBAudioVisualizerView *levelView;

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;


- (IBAction)record:(id)sender;

- (IBAction)play:(id)sender;
@end