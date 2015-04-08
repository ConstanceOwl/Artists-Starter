//
//  DetailViewController.m
//  Artists
//
//  Created by Constance Li on 8/15/14.
//  Copyright (c) 2014 Hollance. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

@synthesize delegate;
@synthesize artistName;
@synthesize navigationBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationBar.topItem.title = self.artistName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    NSLog(@"dealloc DetailViewController");
    NSLog(@"artistName %@", self.artistName);
    NSLog(@"navigationBar %@", self.navigationBar);
}

- (IBAction)coolAction
{
    [self.delegate detailViewController:self didPickButtonWithIndex:0];
}

- (IBAction)mehAction
{
    [self.delegate detailViewController:self didPickButtonWithIndex:1];
}

@end
