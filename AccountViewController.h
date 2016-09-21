//
//  AccountViewController.h
//  Kloudphone
//
//  Created by Yuan on 15/1/22.
//  Copyright (c) 2015年 Yuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *accountTable;
@end
