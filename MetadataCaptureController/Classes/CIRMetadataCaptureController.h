//
//  CIRMetadataCaptureController.h
//  MetadataCaptureController
//
//  Created by Pietro Caselani on 13/06/16.
//  Copyright (c) 2016 Copy Is Right. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVCaptureDevice.h>

#define kDefaultObjectTypes @[@"face", @"org.iso.Aztec", @"org.iso.Code128", @"org.iso.Code39", \
@"org.iso.Code39Mod43", @"com.intermec.Code93", @"org.iso.DataMatrix", @"org.gs1.EAN-13", @"org.gs1.EAN-8", \
@"org.ansi.Interleaved2of5", @"org.gs1.ITF14", @"org.iso.PDF417", @"org.iso.QRCode", @"org.gs1.UPC-E"]

@class AVMetadataObject;

@interface AVCaptureDevice (CIR)

- (void)cir_usesBestConfigurationPossible;

@end

@interface CIRMetadataCaptureController : UIViewController

@property (nonatomic, copy, nullable) void (^didCaptureMetadata)(NSArray<AVMetadataObject *> *__nonnull);
@property (nonatomic, copy, nullable) void (^didReceiveCaptureSessionNotification)(NSNotification *__nonnull);
@property (nonatomic, strong, nonnull) NSArray<NSString *> *supportedMetadataObjectTypes;
@property (nonatomic, assign, getter=isShowingFocusLayer) BOOL showFocusLayer;

- (void)configureCaptureDevice:(void (^ __nonnull)(AVCaptureDevice *__nullable, NSError *__nullable))tap;

- (void)startCapturingWithCompletion:(void (^ __nullable)())completionHandler;

- (void)stopCapturing;

- (BOOL)isCapturing;

@end