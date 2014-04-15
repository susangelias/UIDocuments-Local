//
//  DocumentViewControllerDelegate.h
//  GuidesLocal
//
//  Created by Susan Elias on 4/14/14.
//  Copyright (c) 2014 GriffTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DocumentViewControllerDelegate <NSObject>

@required

- (void)documentContentChanged;
- (void)documentContentEmpty: (NSURL *)fileURL;
- (void)listNeedsRefresh;

@end
