//
//  ViewController.m
//  TestWebP
//
//  Created by Carson on 1/17/13.
//  Copyright (c) 2013 Carson McDonald. All rights reserved.
//

#import "ViewController.h"

#import <WebP/decode.h>

@interface ViewController (Private)

- (void)displayImage:(NSString *)filePath;

@end

@implementation ViewController
{
    NSArray *webpImages;
}

- (void)viewDidLoad
{
    webpImages = [[[NSBundle mainBundle] pathsForResourcesOfType:@"webp" inDirectory:nil] retain];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self displayImage:[webpImages objectAtIndex:0]];
}

- (void)dealloc
{
    [webpImages release];
    [_imagePickerView release];
    [_imageScrollView release];
    [_testImageView release];
    [super dealloc];
}

#pragma mark - WebP example

/*
 This gets called when the UIImage gets collected and frees the underlying image.
 */
static void free_image_data(void *info, const void *data, size_t size)
{
    free((void *)data);
}

- (void)displayImage:(NSString *)filePath
{
    // Find the path of the selected WebP image in the bundle and read it into memory
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    // Get the current version of the WebP decoder
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return;
    }
    
    config.output.colorspace = MODE_rgbA;
    config.options.use_threads = 1;
    
    if (WebPDecode([data bytes], [data length], &config) != VP8_STATUS_OK) {
        return;
    }
    
    int width = (&config)->input.width;
    int height = (&config)->input.height;
    if ((&config)->options.use_scaling) {
        width = (&config)->options.scaled_width;
        height = (&config)->options.scaled_height;
    }
    
    // Construct a UIImage from the decoded RGBA value array.
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, (&config)->output.u.RGBA.rgba,
                                 (&config)->output.u.RGBA.size, free_image_data);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef =
    CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo,
                  provider, NULL, NO, renderingIntent);
    
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    
    UIImage* newImage = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    
    // Set the image into the image view and make image view and the scroll view to the correct size
    self.testImageView.frame = CGRectMake(0, 0, width, height);
    self.testImageView.image = newImage;
    
    self.imageScrollView.contentSize = CGSizeMake(width, height);
    
  
    
    [newImage release];
}

#pragma mark - UIScrollViewDelegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.testImageView;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return webpImages.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[webpImages[row] componentsSeparatedByString:@"/"] lastObject];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self displayImage:webpImages[row]];
}

@end
