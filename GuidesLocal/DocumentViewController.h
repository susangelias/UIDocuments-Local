//
//  guideDocumentViewController.h
//  SpeakSteps
//
//  Created by Susan Elias on 3/6/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GuideDocument.h"
#import "DocumentViewControllerDelegate.h"

@interface DocumentViewController : UIViewController < UISplitViewControllerDelegate>

@property (strong, nonatomic) GuideDocument *guideDocument;
@property (weak, nonatomic) IBOutlet UITextView *guideTextView;
@property (weak, nonatomic) id <DocumentViewControllerDelegate> delegate;

@end


