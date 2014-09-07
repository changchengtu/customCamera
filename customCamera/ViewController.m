//
//  ViewController.m
//  customCamera
//
//  Created by 杜長城 on 9/5/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize frameForCapture;
@synthesize playButton;
@synthesize startRecordButton;
@synthesize retakeButton;
@synthesize saveImageButton;
@synthesize takePhotoButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    [self startCamera];
    
    // Disable Stop/Play button when application launches
    [playButton setEnabled:NO];
    [saveImageButton setEnabled:NO];
    [retakeButton setEnabled:NO];
    [startRecordButton setEnabled:NO];
    
    [playButton setHidden:YES];
    [startRecordButton setHidden:YES];
    
}


- (void)startCamera
{
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if ([session canAddInput:deviceInput]) {
        [session addInput:deviceInput];
    }
    
    // for preview the photo
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer]; //add rootLayer on the view
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.frameForCapture.frame;
    
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSetting];
    
    [session addOutput:stillImageOutput];
    [session startRunning];
    
}

- (void)startVoiceRecod
{
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)takePhoto:(id)sender
{
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {

                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break;}
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
        if (imageDataSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            // get photo
            UIImage *image = [UIImage imageWithData:imageData];
            
        }
    }];
    
    [session stopRunning];
    
    [retakeButton setEnabled:YES];
    [startRecordButton setEnabled:YES];
    [saveImageButton setEnabled:YES];
    [takePhotoButton setEnabled:NO];
    [startRecordButton setHidden:NO];
    [playButton setHidden:NO];
    
    [self startVoiceRecod];
    
}

- (IBAction)retake:(id)sender
{
    [session startRunning];
    [playButton setEnabled:NO];
    [saveImageButton setEnabled:NO];
    [retakeButton setEnabled:NO];
    [startRecordButton setEnabled:NO];
    [takePhotoButton setEnabled:YES];
    [playButton setHidden:YES];
    [startRecordButton setHidden:YES];
}

- (IBAction)startRecordTapped:(id)sender {
    if (player.playing) {
        [player stop];
    }
    
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [recorder record];
        [startRecordButton setTitle:@"Done" forState:UIControlStateNormal];
        
    } else {
        
        // Stop recording
        [recorder stop];
         
         AVAudioSession *audioSession = [AVAudioSession sharedInstance];
         [audioSession setActive:NO error:nil];
        //[playButton setEnabled:YES];
        //[playButton setHidden:YES];
    }
    
    [playButton setEnabled:NO];
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [startRecordButton setTitle:@"Record" forState:UIControlStateNormal];
    
    [playButton setEnabled:YES];
}


- (IBAction)playTapped:(id)sender {
    if (!recorder.recording){
        // get audio file
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [player setDelegate:self];
        [player play];
    }
}

/*
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Done"
                                                    message: @"Finish playing the recording!"
                                                   delegate: nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
*/

@end
