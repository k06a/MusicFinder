//
//  ABListenTrackViewController.m
//  MusicFinder
//
//  Created by Антон Буков on 20.03.13.
//  Copyright (c) 2013 Anton Bukov. All rights reserved.
//

#import "ABListenTrackViewController.h"

@interface ABListenTrackViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation ABListenTrackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSStringEncoding encoding;
    NSString * str = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.url] usedEncoding:&encoding error:nil];
    
    NSRange range = [str rangeOfString:@"http://www.youtube.com/v/"];
    if (range.location != NSNotFound)
    {
        NSRange znakRange = [str rangeOfString:@"?" options:0 range:NSMakeRange(range.location, str.length-range.location)];
        NSString * videoCode = [str substringWithRange:NSMakeRange(range.location+range.length, znakRange.location - range.location - range.length)];
        
        NSString * path = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",videoCode,nil];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:path]]];
        return;
    }
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
