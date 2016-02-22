//
//  FBAudioVisualizerView.m
//  FBAudio
//
//  Created by 123 on 16/2/22.
//  Copyright © 2016年 com.pureLake. All rights reserved.
//

#import "FBAudioVisualizerView.h"


#define kMinDecibel -70
#define kMaxDecibel 0


@implementation FBAudioVisualizerView
@synthesize level = _level;


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.frame = frame;
        [self performInit];
    }
    
    
    return self;
}



- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self performInit];
    }
    
    
    return self;
}



- (void)performInit {

    _level = kMinDecibel;
}


- (void)setLevel:(float)level {
    if (_level < kMinDecibel) {
        _level = kMinDecibel;
    }
    else if(_level > kMaxDecibel) {
        _level = kMaxDecibel;
    } else {
        _level = level;
    }
    
    [self setNeedsDisplay];
}







// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect rec = CGRectMake(0, self.frame.size.height/4, self.frame.size.width*(1-_level/kMinDecibel), self.frame.size.height/2);
    CGContextAddRect(ctx, rec);
    [[UIColor redColor] set];
    CGContextDrawPath(ctx, kCGPathFillStroke);
}


@end
