//
//  CIRMetadataCaptureController.m
//  MetadataCaptureController
//
//  Created by Pietro Caselani on 13/06/16.
//  Copyright (c) 2016 Copy Is Right. All rights reserved.
//

#import "CIRMetadataCaptureController.h"

#import <AVFoundation/AVFoundation.h>

#define kCaptureQueueName "captureQueue"
#define kSessionQueueName "sessionQueue"

@interface CIRCaptureView : UIView

@property (nonatomic, assign, getter=isShowingFocusLayer) BOOL showFocusLayer;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) CALayer *focusLayer;

- (void)configureWithSession:(AVCaptureSession *)captureSession completion:(void (^)())completionHandler;

- (void)cleanUp;

@end

@interface CIRMetadataCaptureController () <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDevice *captureDevice;
@property (strong, nonatomic) CIRCaptureView *captureView;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;

@end

@implementation CIRMetadataCaptureController

//region Initialization
- (instancetype)init
{
	if (self = [super init])
		[self baseInit];

	return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ([super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
		[self baseInit];

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if ([super initWithCoder:coder])
		[self baseInit];

	return self;
}

- (void)baseInit
{
	_supportedMetadataObjectTypes = kDefaultObjectTypes;

	_showFocusLayer = YES;

	_captureView = [[CIRCaptureView alloc] init];
	_captureView.backgroundColor = [UIColor blackColor];
	_captureView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self selector:@selector(didNotify:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(didNotify:) name:AVCaptureSessionWasInterruptedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(didNotify:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(didNotify:) name:AVCaptureSessionDidStartRunningNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(didNotify:) name:AVCaptureSessionDidStopRunningNotification object:nil];

	_sessionQueue = dispatch_queue_create(kSessionQueueName, DISPATCH_QUEUE_SERIAL);
}

- (void)dealloc
{
	for (AVCaptureOutput *output in _captureSession.outputs)
		[_captureSession removeOutput:output];

	for (AVCaptureInput *input in _captureSession.inputs)
		[_captureSession removeInput:input];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
//endregion

//region Notifications
- (void)didNotify:(NSNotification *)notification
{
	if (_didReceiveCaptureSessionNotification)
		_didReceiveCaptureSessionNotification(notification);
}
//endregion

//region View Lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];

	_captureView.frame = self.view.bounds;
	_captureView.showFocusLayer = _showFocusLayer;

	[self.view addSubview:_captureView];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self adjustRectOfInterest];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	if (self.isBeingDismissed || self.isMovingFromParentViewController ||
			self.parentViewController.isBeingDismissed || self.parentViewController.isMovingFromParentViewController)
	{
		[_captureView cleanUp];

		if ([_captureSession isRunning])
			[self stopCapturing];
	}
}
//endregion

//region Private
- (BOOL)initilizeComponents:(NSError **)error
{
	_captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:error];

	if (*error) return NO;

	_captureSession = [[AVCaptureSession alloc] init];
	[_captureSession addInput:input];

	AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];

	[_captureSession addOutput:output];

	if (_supportedMetadataObjectTypes)
		_supportedMetadataObjectTypes = [output availableMetadataObjectTypes];

	dispatch_queue_t captureQueue = dispatch_queue_create(kCaptureQueueName, NULL);
	[output setMetadataObjectsDelegate:self queue:captureQueue];
	[output setMetadataObjectTypes:_supportedMetadataObjectTypes];

	return YES;
}

- (void)adjustRectOfInterest
{
	CGRect rectOfInterest = [_captureView.videoPreviewLayer metadataOutputRectOfInterestForRect:_captureView.focusLayer.frame];

	[[_captureSession.outputs firstObject] setRectOfInterest:rectOfInterest];
}
//endregion

//region Public
- (void)configureCaptureDevice:(void (^ __nonnull)(AVCaptureDevice *__nullable, NSError *__nullable))tap
{
	NSError *error = nil;

	if ([self initilizeComponents:&error] && [_captureDevice lockForConfiguration:&error])
	{
		tap(_captureDevice, nil);

		[_captureDevice unlockForConfiguration];
	}
	else
		tap(nil, error);
}

- (void)startCapturingWithCompletion:(void (^ __nullable)())completionHandler
{
	dispatch_async(_sessionQueue, ^{
		[_captureSession startRunning];

		dispatch_async(dispatch_get_main_queue(), ^{
			[_captureView configureWithSession:_captureSession completion:nil];

			if (completionHandler != nil)
				completionHandler();
		});
	});
}

- (void)stopCapturing
{
	[_captureSession stopRunning];
}

- (BOOL)isCapturing
{
	return [_captureSession isRunning];
}
//endregion

//region AV Delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
	if (metadataObjects.count > 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			_didCaptureMetadata(metadataObjects);
		});
	}
}
//endregion

@end

@implementation CIRCaptureView

- (void)cleanUp
{
	[_focusLayer removeFromSuperlayer];

	[_videoPreviewLayer removeFromSuperlayer];
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	[self updateWithRect:self.frame];
}

- (void)configureWithSession:(AVCaptureSession *)captureSession completion:(void (^)())completionHandler
{
	_videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
	_videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	_videoPreviewLayer.anchorPoint = CGPointZero;

	[self.layer addSublayer:_videoPreviewLayer];

	if (_showFocusLayer)
	{
		_focusLayer = [CALayer layer];
		_focusLayer.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3].CGColor;

		[self.layer insertSublayer:_focusLayer above:_videoPreviewLayer];
	}

	[self updateWithRect:self.frame];

	if (completionHandler)
		completionHandler();
}

- (void)updateWithRect:(CGRect)rect
{
	_videoPreviewLayer.bounds = rect;
	_videoPreviewLayer.position = rect.origin;
	_videoPreviewLayer.connection.videoOrientation = [self currentVideoOrientation];

	if (_showFocusLayer)
		[self adjustFocusLayer];
}

- (void)adjustFocusLayer
{
	CGRect viewFrame = self.frame;

	CGAffineTransform affineTransform = [self focusLayerAffineTransformForOrientation:[UIDevice currentDevice].orientation];

	CGRect rect = CGRectMake(0.f, 0.f, 2.f, fmaxf(CGRectGetMaxX(viewFrame), CGRectGetMaxY(viewFrame)));
	CGPoint position = CGPointMake(CGRectGetMidX(viewFrame), CGRectGetMidY(viewFrame));

	_focusLayer.affineTransform = affineTransform;
	_focusLayer.position = position;
	_focusLayer.bounds = rect;
}

- (CGAffineTransform)focusLayerAffineTransformForOrientation:(UIDeviceOrientation)orientation
{
	CGAffineTransform affineTransform;

	switch (orientation)
	{
		case UIDeviceOrientationLandscapeLeft:
			affineTransform = CGAffineTransformMakeRotation(M_PI + M_PI_2);
			break;
		case UIDeviceOrientationLandscapeRight:
			affineTransform = CGAffineTransformMakeRotation(M_PI_2);
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			affineTransform = CGAffineTransformMakeRotation(M_PI);
			break;
		default:
			affineTransform = CGAffineTransformMakeRotation(0.0);
	}

	return affineTransform;
}

- (AVCaptureVideoOrientation)currentVideoOrientation
{
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;

	AVCaptureVideoOrientation videoOrientation;

	if (orientation == AVCaptureVideoOrientationPortrait)
		videoOrientation = AVCaptureVideoOrientationPortrait;
	else if (orientation == AVCaptureVideoOrientationPortraitUpsideDown)
		videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
	else if (orientation == UIDeviceOrientationLandscapeLeft)
		videoOrientation = AVCaptureVideoOrientationLandscapeRight;
	else
		videoOrientation = AVCaptureVideoOrientationLandscapeLeft;

	return videoOrientation;
}

@end

@implementation AVCaptureDevice (CIR)

- (void)cir_usesBestConfigurationPossible
{
	if ([self isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
		self.focusMode = AVCaptureFocusModeContinuousAutoFocus;
	else if ([self isFocusModeSupported:AVCaptureFocusModeAutoFocus])
		self.focusMode = AVCaptureFocusModeAutoFocus;
	else if ([self isFocusModeSupported:AVCaptureFocusModeLocked])
		self.focusMode = AVCaptureFocusModeLocked;

	if (self.smoothAutoFocusSupported)
		self.smoothAutoFocusEnabled = YES;

	if (self.focusPointOfInterestSupported)
		self.focusPointOfInterest = CGPointMake(0.5f, 0.5f);

	if ([self isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
		self.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
	else if ([self isExposureModeSupported:AVCaptureExposureModeAutoExpose])
		self.exposureMode = AVCaptureExposureModeAutoExpose;
	else if ([self isExposureModeSupported:AVCaptureExposureModeCustom])
		self.exposureMode = AVCaptureExposureModeCustom;
	else if ([self isExposureModeSupported:AVCaptureExposureModeLocked])
		self.exposureMode = AVCaptureExposureModeLocked;
}

@end