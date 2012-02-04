//
//  MainViewController.m
//  JTPinIt
//
//  Created by James Tang on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "NSData+Base64.h"
#import "NSString+URLEncoding.h"

typedef enum {
    MainViewControllerSegmentImageView,
    MainViewControllerSegmentWebView,
} MainViewControllerSegment;

NSString *const pinterestBookmarklet = @"void((function(){var e=document.createElement('script'); e.setAttribute('type','text/javascript'); e.setAttribute('charset','UTF-8'); e.setAttribute('src','http://assets.pinterest.com/js/pinmarklet.js?r='+Math.random()*99999999);document.body.appendChild(e);})());";
NSString *PinterestURLMake(UIImage *image, NSString *urlString, NSString *alt, NSString *title, BOOL isVideo);

#define IMAGE_QUALITY 0.8
#define LOAD_WEBVIEW_WITH_IMAGE_DATA 0

@interface MainViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIImage *image;
@end

@implementation MainViewController

@synthesize image;
@synthesize imageView, webView, scrollView, segmentControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.image = self.imageView.image;
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width * 2, self.scrollView.frame.size.height);
    self.webView.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
    self.webView.scalesPageToFit = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark Action
- (void)updateWebviewImage {
#if LOAD_WEBVIEW_WITH_IMAGE_DATA
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *data = UIImageJPEGRepresentation(self.image, IMAGE_QUALITY);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView loadData:data
                          MIMEType:@"image/jpeg"
                  textEncodingName:nil
                           baseURL:nil];
        });
    });
#else
    NSString *htmlString = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='width=device-width,user-scalable=true' /></head><body style='width:100%;margin:0px;padding:0px;'><img src='data:image/jpeg;base64,%@' /></body></html>", NSStringFromUIImage(self.image)];
    NSURL *URL = [NSURL URLWithString:htmlString];
    [self.webView loadHTMLString:htmlString baseURL:URL];
#endif
}

- (void)pinThroughWebview {
    NSString *javascript = [NSString stringWithFormat:@"%@", pinterestBookmarklet];
    [self.webView stringByEvaluatingJavaScriptFromString:javascript];
}

- (void)pinThroughURLScheme {
    NSString *urlString = PinterestURLMake(self.image, nil, @"alt", @"image.jpeg", NO);
    NSLog(@"%@", urlString);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction)uploadButtonPressed:(id)sender {
    switch (self.segmentControl.selectedSegmentIndex) {
        case MainViewControllerSegmentImageView:
        default:
            [self pinThroughURLScheme];
            break;
        case MainViewControllerSegmentWebView:
            [self pinThroughWebview];
            break;
    }
}

- (IBAction)libraryButtonPressed:(id)sender {
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.delegate   = self;
    [self presentModalViewController:controller animated:YES];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case MainViewControllerSegmentWebView:
            [self.scrollView scrollRectToVisible:self.webView.frame animated:YES];
            [self updateWebviewImage];
            break;
        case MainViewControllerSegmentImageView:
        default:
            [self.scrollView scrollRectToVisible:self.imageView.frame animated:YES];
            self.imageView.image = self.image;
            break;
    }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    switch (self.segmentControl.selectedSegmentIndex) {
        case MainViewControllerSegmentWebView:
            [self updateWebviewImage];
            break;
        case MainViewControllerSegmentImageView:
        default:
            self.imageView.image = self.image;
            break;
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    NSLog(@"%@", aWebView.request);
}

@end


NSString *NSStringFromUIImage(UIImage *image) {
    NSData *dataObj = UIImageJPEGRepresentation(image, IMAGE_QUALITY);
    return [dataObj base64Encoding];
}


NSString *PinterestURLMake(UIImage *image, NSString *urlString, NSString *alt, NSString *title, BOOL isVideo) {
    NSString *base64ImageString = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", NSStringFromUIImage(image)];
    
    NSString *encodedBase64ImageString = [base64ImageString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedURLValue = [urlString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedAltValue = [alt urlEncodeUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedTitleValue = [[NSString stringWithFormat:@"%@ %.0fx%.0f pixels", title, image.size.width, image.size.height] urlEncodeUsingEncoding:NSUTF8StringEncoding];
    NSString *videoValue        = isVideo ? @"true" : @"false";
    
    return [NSString stringWithFormat:@"pinit12://pinterest.com/pin/create/bookmarklet/?media=%@%@%@%@&is_video=%@&",
            encodedBase64ImageString,
            urlString ? [NSString stringWithFormat:@"&url=%@", encodedURLValue] : @"",
            alt ? [NSString stringWithFormat:@"&alt=%@", encodedAltValue] : @"",
            title ? [NSString stringWithFormat:@"&title=%@", encodedTitleValue] : @"",
            videoValue];
}
