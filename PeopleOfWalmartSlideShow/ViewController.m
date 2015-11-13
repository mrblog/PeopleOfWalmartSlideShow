//
//  ViewController.m
//  PeopleOfWalmartSlideShow
//
//  Created by David Beckemeyer on 11/12/15.
//  Copyright © 2015 telEvolution. All rights reserved.
//

#import "ViewController.h"

#define kSlideShowInterval			7.0

/* RSS cache update interval in seconds */
const double RSSCacheInterval = 1200.0;

@interface ViewController ()
{
    NSMutableArray *_urlList;
    NSInteger _imageIndex;
    UIImageView *_imageView;
    NSMutableArray *_imageCache;
    BOOL _paused;
    NSDate *_pausedTime;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _paused = NO;
    _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_imageView];
    [self rssAgain];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePlayPause:)];
    tap.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - exposed methods

- (void)pauseShow {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _paused = YES;
}

- (void)resumeShow {
    if (_paused) {
        _paused = NO;
        [self performSelector:@selector(rssAgain) withObject:nil afterDelay:RSSCacheInterval];
        [self nextImage];
    }
}

- (void)handlePlayPause:(id)sender {
    if (_paused) {
        [self resumeShow];
    } else {
        [self pauseShow];
    }
}

#pragma mark - local methods

- (void)rssAgain {
    NSString *rssdata;
    NSString *itemstart = @"<item>";
    NSString *itemend = @"</item>";
    NSString *imgstart = @"<img ";
    NSString *srcstart = @" src=\"";
    NSString *qt = @"\"";
    NSString *sharestring = @"share_save";
    NSError *error;
    
    NSURL *urlString = [[NSURL alloc]initWithString:@"http://www.peopleofwalmart.com/feed/"];
    rssdata = [[NSString alloc] initWithContentsOfURL:urlString
                                             encoding:NSUTF8StringEncoding
                                                error:&error];
    
    //Populate an array with all the image urls in the RSS feed
    _urlList = [NSMutableArray new];

    NSRange firstRange = [rssdata rangeOfString:itemstart
                                        options:NSCaseInsensitiveSearch];
    while (firstRange.length > 0) {
        rssdata = [rssdata substringFromIndex: (firstRange.location+firstRange.length)];
        NSRange endRange = [rssdata rangeOfString:itemend options:NSCaseInsensitiveSearch];
        NSString *thisItem = [rssdata substringToIndex: endRange.location];
        rssdata = [rssdata substringFromIndex: (endRange.location+endRange.length)];
        firstRange = [rssdata rangeOfString:itemstart
                                    options:NSCaseInsensitiveSearch];
        NSRange imgRange = [thisItem rangeOfString:imgstart options:NSCaseInsensitiveSearch];
        while (imgRange.length > 0) {
            thisItem = [thisItem substringFromIndex: (imgRange.location+imgRange.length-1)];
            NSRange srcRange = [thisItem rangeOfString:srcstart options:NSCaseInsensitiveSearch];
            if (srcRange.length) {
                thisItem = [thisItem substringFromIndex: (srcRange.location+srcRange.length)];
                NSRange qtRange = [thisItem rangeOfString:qt];
                NSString *imgUrl = [thisItem substringWithRange:NSMakeRange(0,qtRange.location)];
                thisItem = [thisItem substringFromIndex: (qtRange.location+qtRange.length)];
                NSRange skipRange = [imgUrl rangeOfString:sharestring options:NSCaseInsensitiveSearch];
                if (skipRange.length <= 0) {
                    NSLog(@"imgUrl: %@", imgUrl);
                    [_urlList addObject:[[NSURL alloc] initWithString:imgUrl]];
                }
                
            }
            imgRange = [thisItem rangeOfString:imgstart options:NSCaseInsensitiveSearch];
        }
    }
    NSLog(@"loaded %ld urls", [_urlList count]);
    [self startShow];
    [self performSelector:@selector(rssAgain) withObject:nil afterDelay:RSSCacheInterval];

}

- (void)startShow {
    _imageIndex = 0;
    _imageCache = [NSMutableArray new];
    [self nextImage];
}

- (void)nextImage {
    
    UIImage *image;
    if ([_imageCache count] > _imageIndex) {
        image = [_imageCache objectAtIndex:_imageIndex];
    } else {
        NSData *imgData = [NSData dataWithContentsOfURL:[_urlList objectAtIndex:_imageIndex]];
        if(imgData == nil) {
            NSLog(@"Cannot load image url %@", [_urlList objectAtIndex:_imageIndex]);
            return;
        }
        image = [[UIImage alloc] initWithData:imgData];
        if(image == nil) {
            NSLog(@"Cannot init image url %@", [_urlList objectAtIndex:_imageIndex]);
            return;
        }
        [_imageCache addObject:image];
    }
    _imageView.image = image;
    _imageIndex = (_imageIndex + 1) % [_urlList count];
    [self performSelector:@selector(nextImage) withObject:nil afterDelay:kSlideShowInterval];
}

@end
