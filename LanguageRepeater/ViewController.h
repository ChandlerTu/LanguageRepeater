//
//  ViewController.h
//  LanguageRepeater
//
//  Created by nbpt on 15-3-23.
//  Copyright (c) 2015年 Chandler Tu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVAudioPlayerDelegate, AVAudioRecorderDelegate>

- (IBAction)unwindToRepeater:(UIStoryboardSegue *)segue;

@end
