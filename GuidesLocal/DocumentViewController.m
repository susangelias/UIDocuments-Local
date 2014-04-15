//
//  guideDocumentViewController.m
//  GuidesLocal
//
//  Created by Susan Elias on 3/6/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import "DocumentViewController.h"
#import "GuideDocument.h"
#import "FileExtension.h"


NSString * const editDoneButtonTitleEdit = @"Edit";
NSString * const editDoneButtonTitleDone = @"Done";

@interface DocumentViewController () <UITextViewDelegate>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

#pragma mark View LifeCyle

@implementation DocumentViewController

#define kTITLE_LENGTH 40

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    self.guideTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    // sign up to catch any changes the user makes to the font settings
    [[NSNotificationCenter defaultCenter]
            addObserver:self
                selector:@selector(preferredContentSizeChanged:)
                    name:UIContentSizeCategoryDidChangeNotification
                object:nil ];
    self.guideTextView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Make sure Edit/Done button has the correct target action
    self.editButtonItem.target = self;
    self.editButtonItem.action = @selector(EditDoneButtonPressed:);
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self textViewDidEndEditing:self.guideTextView];
    
    [super viewWillDisappear:animated];
}

-(void)preferredContentSizeChanged:(NSNotification *)notification
{
    self.guideTextView.font  = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.guideTextView.text = self.guideDocument.text;
    
}


#pragma mark User Action

- (IBAction)EditDoneButtonPressed:(UIBarButtonItem *)sender {
    
    if ([sender.title isEqualToString:editDoneButtonTitleEdit]) {
        // toggle button to done
        sender.title = editDoneButtonTitleDone;
        
        // activate keyboard
        [self.guideTextView becomeFirstResponder];
    }
    else {
        // togggle button to edit
        sender.title = editDoneButtonTitleEdit;
        
        // deactivate keyboard
        [self.guideTextView resignFirstResponder];
    }
}

- (IBAction)backButtonPressed:(UIBarButtonItem *)sender {
    
    NSLog(@"back button pressed");
}

#pragma mark SplitViewController Delegate

- (BOOL) splitViewController:(UISplitViewController *)svc
    shouldHideViewController:(UIViewController *)vc
               inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void) splitViewController:(UISplitViewController *)sender
      willHideViewController:(UIViewController *)master
           withBarButtonItem:(UIBarButtonItem *)barButtonItem
        forPopoverController:(UIPopoverController *)popover
{
    
    barButtonItem.title = @"Guides";
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popover;
    
}

- (void) splitViewController:(UISplitViewController *)svc
      willShowViewController:(UIViewController *)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
    self.masterPopoverController = nil;
}

-(void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController
{
    if ([self checkFileName]) {
        [self.delegate listNeedsRefresh];
    }
    
//    [self.guideTextView resignFirstResponder];
}

#pragma mark Helpers


- (BOOL)checkFileName
{
    // check if document name needs to change
    BOOL result = NO;
    
    // document name is the first line of text truncated to kTITLE_LENGTH characters
    NSArray *lines = [self.guideTextView.text  componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *firstLine = [[lines objectAtIndex:0]mutableCopy];   // get the first line
    if ( [firstLine length] > kTITLE_LENGTH ) {
        firstLine = [[firstLine substringToIndex:kTITLE_LENGTH]mutableCopy];
        // remove any trailing white space
        firstLine = [[firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]mutableCopy];
    }
    
    if (![firstLine isEqualToString:self.guideDocument.localizedName]) {
        self.guideDocument.guideTitle = firstLine;
        result = YES;
    }
    return result;
}


#pragma mark UITextViewDelegate Methods

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    // toggle the edit/done button in the navigation bar to match state
    UIBarButtonItem *editButton = [self.navigationItem rightBarButtonItem];
    editButton.title = editDoneButtonTitleDone;
    
    // verify that document is open - iPad only
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (self.guideDocument.documentState & UIDocumentStateClosed) {
            // document needs to reopen
            NSLog(@"document is closed %lu",self.guideDocument.documentState );
            if (self.guideDocument) {
                [self.guideDocument openWithCompletionHandler:^(BOOL success) {
                    if (success) {
                        NSLog(@"document is open");
                    }
                }];
            }
        }
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.guideDocument) {        
        // check if there is any text
        NSString *documentText = [self.guideTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([documentText isEqualToString:@""]) {
            // don't save documents without content, let the delegate know
            [self.delegate documentContentEmpty:self.guideDocument.fileURL];
        }
        else {
            // update the model
            self.guideDocument.text = self.guideTextView.text;
            
            // update the guide Document's guideTitle if the name needs to change
            [self checkFileName];
            
            // let delegate know the document content has changed
            if (!self.guideDocument.documentState & UIDocumentStateNormal) {
         //       NSLog(@"documentState = %d", self.guideDocument.documentState);
            }
            else {
                [self.delegate documentContentChanged];
            }
        }
    }
    // toggle the edit/done button in the navigation bar to match state
    UIBarButtonItem *editButton = [self.navigationItem rightBarButtonItem];
    editButton.title = editDoneButtonTitleEdit;
    
}

-(void) keyboardWillShow:(NSNotification *)note
{
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.guideTextView.frame;
    
    // Start animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height -= keyboardBounds.size.height;
    else
        frame.size.height -= keyboardBounds.size.width;
    
    // Apply new size of table view
    self.guideTextView.frame = frame;
    
    // Scroll the table view to see the TextField just above the keyboard
    if (self.guideTextView)
    {
        CGRect textFieldRect = [self.guideTextView convertRect:self.guideTextView.superview.bounds fromView:self.guideTextView.superview];
        [self.guideTextView scrollRectToVisible:textFieldRect animated:NO];
    }
    
    [UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)note
{
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.guideTextView.frame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height += keyboardBounds.size.height;
    else
        frame.size.height += keyboardBounds.size.width;
    
    // Apply new size of table view
    self.guideTextView.frame = frame;
    
    [UIView commitAnimations];
}



@end
