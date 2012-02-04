//
//  MainViewController.h
//  JTPinIt
//
//  Created by James Tang on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *imageView;
@property (nonatomic, unsafe_unretained) IBOutlet UIWebView *webView;
@property (nonatomic, unsafe_unretained) IBOutlet UIScrollView *scrollView;
@property (nonatomic, unsafe_unretained) IBOutlet UISegmentedControl *segmentControl;

- (IBAction)uploadButtonPressed:(id)sender;
- (IBAction)libraryButtonPressed:(id)sender;
- (IBAction)segmentChanged:(id)sender;

@end


NSString *NSStringFromUIImage(UIImage *image);