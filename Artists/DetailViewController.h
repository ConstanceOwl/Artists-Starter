//
//  DetailViewController.h
//  Artists
//
//  Created by Constance Li on 8/15/14.
//  Copyright (c) 2014 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@protocol DetailViewControllerDelegate <NSObject>

- (void)detailViewController:(DetailViewController *)controller didPickButtonWithIndex:(NSInteger)buttonIndex;

@end

@interface DetailViewController : UIViewController

@property (nonatomic, weak) id <DetailViewControllerDelegate>delegate;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;

- (IBAction)coolAction;
- (IBAction)mehAction;

@end
