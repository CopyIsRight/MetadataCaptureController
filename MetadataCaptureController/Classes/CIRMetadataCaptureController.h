//
//  CIRMetadataCaptureController.h
//  Pods
//
//  Created by Pietro Caselani on 15/06/16.
//
//

#import <UIKit/UIKit.h>

@class MTBBarcodeScanner;

@interface CIRMetadataCaptureController : UIViewController

@property (nonatomic, strong, readonly) MTBBarcodeScanner *scanner;
@property (nonatomic, weak) IBOutlet UIView *focusView;

@end
