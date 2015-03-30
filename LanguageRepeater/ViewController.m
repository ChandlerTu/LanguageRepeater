//
//  ViewController.m
//  LanguageRepeater
//
//  Created by nbpt on 15-3-23.
//  Copyright (c) 2015年 Chandler Tu. All rights reserved.
//

#import "ViewController.h"
#import "TableViewController.h"

@interface ViewController ()

@property NSTimeInterval bTimeInterval;
@property (nonatomic, retain) AVAudioPlayer *player;
@property (nonatomic, retain) AVAudioRecorder *recorder;
@property (nonatomic, retain) AVAudioPlayer *recordingPlayer;

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (strong, nonatomic) IBOutlet UIButton *durationButton;
@property (strong, nonatomic) IBOutlet UITextField *aTextField;
@property (strong, nonatomic) IBOutlet UITextField *bTextField;
@property (strong, nonatomic) IBOutlet UIButton *aButton;
@property (strong, nonatomic) IBOutlet UIButton *bButton;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *playRecordingButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initPlayer];
    
    [self initRecorder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initPlayer
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *selectedFileName = [defaults objectForKey:@"selectedFileName"];
    
    [self.titleLabel setText:selectedFileName];
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *pathComponents = [NSArray arrayWithObjects:documentDirectory, selectedFileName, nil];
    NSURL *url = [NSURL fileURLWithPathComponents:pathComponents];
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player setDelegate:self];
    
    NSString *duration = [self stringFromTimeInterval:self.player.duration];
    [self.durationButton setTitle:duration forState: UIControlStateNormal];
    [self.bTextField setText:duration];
}

- (void) initRecorder
{
    [self.playRecordingButton setEnabled:NO];
    
    NSString *temporaryDirectory = NSTemporaryDirectory();
    NSString *path = [temporaryDirectory stringByAppendingString:@"recording.caf"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:44100.0], AVSampleRateKey, [NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey, [NSNumber numberWithInt:1], AVNumberOfChannelsKey, [NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey, nil];
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:nil];
    self.recorder.delegate = self;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag == YES) {
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
        [self.playRecordingButton setTitle:@"PlayRecording" forState:UIControlStateNormal];
    }
}

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [self.playRecordingButton setEnabled:YES];
}

- (IBAction)playOrPause:(id)sender
{
    if (self.player.playing) {
        [self.playButton setTitle: @"Play" forState: UIControlStateNormal];
        [self.player pause];
    } else {
        [self.playButton setTitle: @"Pause" forState: UIControlStateNormal];
        
        NSTimeInterval aTimeInterval = [self timeIntervalFromString:[self.aTextField text]];
        [self.player setCurrentTime:aTimeInterval];
        self.bTimeInterval = [self timeIntervalFromString:[self.bTextField text]];
        [self.player play];
        
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    }
}

- (void)updateProgress
{
    NSString *currentTime = [self stringFromTimeInterval:self.player.currentTime];
    [self.currentTimeLabel setText:currentTime];
    [self.progressView setProgress:(self.player.currentTime/self.player.duration)];
    
    if (self.player.currentTime >= self.bTimeInterval) {
        [self.playButton setTitle: @"Play" forState: UIControlStateNormal];
        [self.player pause];
    }
}

- (IBAction)aTimeInterval:(id)sender
{
    NSString *aTimeInterval = [self stringFromTimeInterval:self.player.currentTime];
    [self.aTextField setText:aTimeInterval];
}

- (IBAction)bTimeInterval:(id)sender
{
    NSString *bTimeInterval = [self stringFromTimeInterval:self.player.currentTime];
    [self.bTextField setText:bTimeInterval];
}

- (IBAction)duration:(id)sender {
    NSString *duration =[self.durationButton titleForState:UIControlStateNormal];
    [self.bTextField setText:duration];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval {
    NSInteger ti = (NSInteger)timeInterval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld",  (long)minutes, (long)seconds];
}

- (NSTimeInterval)timeIntervalFromString:(NSString *)string {
    NSInteger minutes = [[string substringToIndex:2] integerValue];
    NSInteger seconds = [[string substringFromIndex:3] integerValue];
    NSTimeInterval timeInterval = minutes * 60 + seconds;
    return timeInterval;
}

- (IBAction)recordOrStop:(id)sender {
    if (self.recordingPlayer.playing) {
        [self.recordingPlayer stop];
    }
    
    if (!self.recorder.recording) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        [self.recorder record];
        [self.recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        
    } else {
        [self.recorder stop];
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
    }
    
    [self.playRecordingButton setEnabled:NO];
}

- (IBAction)playRecording:(id)sender {
    if (!self.recorder.recording){
        self.recordingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recorder.url error:nil];
        [self.recordingPlayer setDelegate:self];
        [self.recordingPlayer play];
    }
}

- (IBAction)unwindToRepeater:(UIStoryboardSegue *)segue
{
    [self initPlayer];
}

@end
