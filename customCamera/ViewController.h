//
//  ViewController.h
//  customCamera
//
//  Created by 杜長城 on 9/5/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AssetsLibrary/AssetsLibrary.h"

@interface ViewController : UIViewController
{
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    AVCaptureSession *session;
    AVCaptureStillImageOutput *stillImageOutput;
    UIImage *tmpImage;
}

@property (weak, nonatomic) IBOutlet UIView *frameForCapture;

- (IBAction)takePhoto:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *startRecordButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *retakeButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveImageButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *takePhotoButton;


@end
