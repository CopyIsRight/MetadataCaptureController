//
//  CIRMetadataCaptureController.m
//  Pods
//
//  Created by Pietro Caselani on 15/06/16.
//
//

#import "CIRMetadataCaptureController.h"
#import "MTBBarcodeScanner.h"

@interface CIRMetadataCaptureController ()

@end

@implementation CIRMetadataCaptureController

//region Initialization
- (void)awakeFromNib
{
	_scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:self.view];
	
	if (_focusView)
		_scanner.scanRect = _focusView.frame;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[_scanner stopScanning];
}
//endregion

@end
