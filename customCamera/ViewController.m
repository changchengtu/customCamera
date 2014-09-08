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
                               @"saveAudio.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    NSLog(@"%@",pathComponents);
    
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
            tmpImage = image;
            
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
        // Start recording
        [recorder record];
        [startRecordButton setTitle:@"Done" forState:UIControlStateNormal];
        
    } else {
        // Stop recording
        [recorder stop];
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
        // play with path format-> /var/mobile/Applications/00E43168-08E3-4EC2-8A9E-80BF6A2C7C17/Documents/audioFile.ext
        
        // Set the audio file
        NSArray *pathComponents = [NSArray arrayWithObjects:
                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                   @"saveAudio.m4a",
                                   nil];
        NSURL *fileURL = [NSURL fileURLWithPathComponents:pathComponents];
        
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        [player setDelegate:self];
        [player play];
        
    }
}

- (IBAction)savePhotoTapped:(id)sender {
    
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeImageToSavedPhotosAlbum:tmpImage.CGImage orientation:(ALAssetOrientation)tmpImage.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error )
     {
         // compress image
         CGSize destinationSize = CGSizeMake(320,200);
         UIGraphicsBeginImageContext(destinationSize);
         [tmpImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
         UIImage *compressedImage = UIGraphicsGetImageFromCurrentImageContext();
         UIGraphicsEndImageContext();
         
         // save thumbnail image to document
         NSData *thumbnailData = UIImagePNGRepresentation(compressedImage);
         NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
         NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
         
         // name thumbnail as date
         NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
         [DateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
         NSString *thumbnailName = [NSString stringWithFormat:@"%@",[DateFormatter stringFromDate:[NSDate date]]];
         NSString *filePath = [documentsPath stringByAppendingPathComponent:thumbnailName];
         
         // save thu
         [thumbnailData writeToFile:filePath atomically:YES];
         
         NSLog(@"RecordController: IMAGE SAVED TO PHOTO ALBUM");
     }];
    
    
    [self showFile];
    
}

- (void)showFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *arr = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *url = arr[0];
    
    // includingPropertiesForKey: 表示要列出具備哪些屬性的檔案，nil表示所有屬性都要的意思
    // option: 目前可以使用的參數是 NSDirectoryEnumerationSkipsHiddenFiles 代表不要列出隱藏檔
    //         如果要連隱藏檔都列出，則使用 ~NSDirectoryEnumerationSkipsHiddenFiles
    //         UNIX 的隱藏檔是以「.」開頭的檔案
    NSArray *fileList = [fm contentsOfDirectoryAtURL:url
                          includingPropertiesForKeys:nil
                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                               error:nil
                         ];
    
    BOOL isDir;
    for (NSURL *p in fileList) {
        // NSURL 類別包含了檔案的絕對路徑（以URI的格式呈現）
        // .lastPathComponent 則是URI中檔名的部分
        if ([fm fileExistsAtPath:p.path isDirectory:&isDir] && isDir)
            NSLog(@"%@ 是目錄.", p.lastPathComponent);
        else
            NSLog(@"%@ 是檔案.", p.lastPathComponent);
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
