//
//  ContactsViewController.h
//  SideMenuExample
//
//  Created by Yuan on 15/1/21.
//  Copyright (c) 2015年 Australian Broadcasting Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "MJNIndexView.h"

@interface ContactsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ABNewPersonViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *contactsTable;
@property (strong, nonatomic) MJNIndexView *indexView;
@property (strong, nonatomic) NSMutableArray *_contacts;
@end
