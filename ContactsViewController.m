//
//  FriendsViewController.m
//  SideMenuExample
//
//  Created by Yuan on 15/1/21.
//  Copyright (c) 2015年 Australian Broadcasting Corporation. All rights reserved.
//

#import "ContactsViewController.h"
#import "NTContact.h"
#import "NTContactGroup.h"
#import "APContact.h"
#import "APAddressBook.h"
#import "ContactsCell.h"
#import "PersonViewController.h"
#import "SVProgressHUD.h"

@interface ContactsViewController () <UISearchBarDelegate, UISearchDisplayDelegate, MJNIndexViewDataSource>
{
    NSIndexPath *_selectedIndexPath; //当前选中的组和行
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchDisplayController;
    NSMutableArray *_searchContacts;//符合条件的搜索联系人
}
@end

@implementation ContactsViewController

@synthesize contactsTable;
@synthesize indexView;
@synthesize _contacts;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.contactsTable deselectRowAtIndexPath:[self.contactsTable indexPathForSelectedRow] animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"Contacts Init");
    [self.navigationController setNavigationBarHidden:NO];
    
    [self initContactData];
    [self addSearchBar];
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    contactsTable.tableFooterView = view;
    
    UIColor *bgcolor = [UIColor colorWithRed:133/255.0 green:88/255.0 blue:170/255.0 alpha:1];
    self.navigationController.navigationBar.barTintColor = bgcolor;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;
    
    // initialise MJNIndexView
    indexView = [[MJNIndexView alloc] initWithFrame:self.view.bounds];
    indexView.dataSource = self;
    indexView.fontColor = [UIColor colorWithRed:133/255.0 green:88/255.0 blue:170/255.0 alpha:1];
    [self.view addSubview:indexView];
    
//    UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
//    segmentControl.tintColor = [UIColor whiteColor];
//    [segmentControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
//    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Medium" size:15], NSFontAttributeName, nil];
//    [segmentControl setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
//    [segmentControl insertSegmentWithTitle:@"Local" atIndex:0 animated:NO];
//    [segmentControl insertSegmentWithTitle:@"Community" atIndex:1 animated:NO];
//    [segmentControl setSelectedSegmentIndex:0];
//    self.navigationItem.titleView = segmentControl;
}

- (void)segmentSelected:(UISegmentedControl *)segmentControl {
    NSLog(@"segmentSelectedIndex %ld", (long)segmentControl.selectedSegmentIndex);
}

- (IBAction)refreshContacts:(id)sender {
    NSLog(@"refreshContacts");
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf initContactData];
    });
}

- (void)addSearchBar {
    _searchBar = (UISearchBar *)[self.view viewWithTag:1];
    [_searchBar sizeToFit];//大小自适应容器
    _searchBar.placeholder = @"Search";
    _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    //添加搜索框到页眉位置
    _searchBar.delegate = self;
    _searchDisplayController = [[UISearchDisplayController alloc]initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsDelegate = self;
    [_searchDisplayController setActive:NO animated:YES];
    
    //搜索界面 cancel的颜色
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:133/255.0 green:88/255.0 blue:170/255.0 alpha:1], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self searchDataWithKeyWord:searchString];
    return YES;
}

-(void)searchDataWithKeyWord:(NSString *)keyWord {
    _searchContacts = [NSMutableArray array];
    [_contacts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NTContactGroup * group = obj;
        [group.contacts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NTContact * contact = obj;
            if (([contact.compositeName.uppercaseString rangeOfString:keyWord.uppercaseString].location != NSNotFound && contact.compositeName != nil)) {
                [_searchContacts addObject:contact];
            }
        }];
    }];
}

- (void)initContactData {
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    APAddressBook *addressBook = [[APAddressBook alloc] init];
    addressBook.filterBlock = ^BOOL(APContact *contact) {
        return contact.phones.count > 0 && contact.compositeName != nil;
    };
    addressBook.fieldsMask = APContactFieldFirstName | APContactFieldLastName | APContactFieldCompositeName | APContactFieldThumbnail | APContactFieldRecordID | APContactFieldPhones;
    [addressBook loadContacts:^(NSArray *contacts, NSError *error) {
        // hide activity
        if (!error) {
            NSMutableArray *allContacts = [NSMutableArray array];
            
            for(APContact *tmpPerson in contacts) {
                NSString* tmpFirstName = tmpPerson.firstName;
                NSString* tmpLastName = tmpPerson.lastName;
                NSString* letter;
                NSString* tmpString;
                
                if(tmpLastName.length > 0) {
                    tmpString = tmpLastName;
                } else {
                    tmpString = tmpFirstName;
                }
        
                NTContact *contact = [NTContact initWithUid:tmpPerson.recordID andCompositeName:tmpPerson.compositeName andImage:tmpPerson.thumbnail];
                NTContactGroup *group;
                
                //判断首字符是否为字母
                NSString *regex = @"[A-Za-z0-9]+";
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                tmpString = [tmpString stringByReplacingOccurrencesOfString:@" " withString:@""];
                tmpString = [tmpString stringByReplacingOccurrencesOfString:@"'" withString:@""];
                
                if ([predicate evaluateWithObject:tmpString]) {
                    letter = [NSString stringWithFormat:@"%c", [[tmpString lowercaseString] characterAtIndex:0]];
                } else {
                    if(![tmpString isEqualToString:@""] && tmpString != nil) {
                        //chinese to pinyin  -----  Yuan
                        NSMutableString *string = [tmpString mutableCopy];
                        CFStringTransform((__bridge CFMutableStringRef)string, NULL, kCFStringTransformMandarinLatin, NO);
                        CFStringTransform((__bridge CFMutableStringRef)string, NULL, kCFStringTransformStripDiacritics, NO);
                        /*多音字处理*/
                        if ([[tmpString substringToIndex:1] compare:@"长"] == NSOrderedSame) {
                            [string replaceCharactersInRange:NSMakeRange(0, 5) withString:@"chang"];
                        }
                        if ([[tmpString substringToIndex:1] compare:@"沈"] == NSOrderedSame) {
                            [string replaceCharactersInRange:NSMakeRange(0, 4) withString:@"shen"];
                        }
                        if ([[tmpString substringToIndex:1] compare:@"厦"] == NSOrderedSame) {
                            [string replaceCharactersInRange:NSMakeRange(0, 3) withString:@"xia"];
                        }
                        if ([[tmpString substringToIndex:1] compare:@"地"] == NSOrderedSame) {
                            [string replaceCharactersInRange:NSMakeRange(0, 3) withString:@"di"];
                        }
                        if ([[tmpString substringToIndex:1] compare:@"重"] == NSOrderedSame) {
                            [string replaceCharactersInRange:NSMakeRange(0, 5) withString:@"chong"];
                        }
                        NSString *finalString = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%c", 32] withString:@""];
                        letter = [NSString stringWithFormat:@"%c", [finalString characterAtIndex:0]];
                        string = nil;
                    } else {
                        letter = @"";
                    }
                }
                
                if(letter.length == 1) {
                    regex = @"[a-z]";
                    predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                    if (![predicate evaluateWithObject:letter]) {
                        letter = @"#";
                    }
                    
                    if([[dictionary allKeys] containsObject:letter]) {
                        group = [dictionary objectForKey:letter];
                    } else {
                        group = [NTContactGroup initWithName:[letter uppercaseString] andContacts:[NSMutableArray array]];
                        [dictionary setObject:group forKey:letter];
                    }
                    [group addContact:contact];
                }
            }
            
            NSArray *allKeys = [dictionary allKeys];
            NSArray *sortedKeys = [allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            
            for(id key in sortedKeys) {
                [allContacts addObject:[dictionary objectForKey:key]];
            }
            
            [weakSelf._contacts removeAllObjects];
            weakSelf._contacts = nil;
            weakSelf._contacts = [NSMutableArray arrayWithArray:allContacts];
            [allContacts removeAllObjects];
            allContacts = nil;
            [weakSelf.contactsTable reloadData];
            [weakSelf.indexView refreshIndexItems];
            [SVProgressHUD dismiss];
        } else {
            NSLog(@"move failed:%@", [error localizedDescription]);
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == _searchDisplayController.searchResultsTableView) {
        return 1;
    }
    return _contacts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _searchDisplayController.searchResultsTableView) {
        return _searchContacts.count;
    }
    NTContactGroup * group = _contacts[section];
    return group.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NTContact *contact = nil;
    if (tableView == _searchDisplayController.searchResultsTableView) {
        contact = _searchContacts[indexPath.row];
        
        //由于此方法调用十分频繁，cell的标示声明成静态变量有利于性能优化
        static NSString *cellIdentifier = @"SearchCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        }
        
        cell.textLabel.text = contact.compositeName;
        
        return cell;
    } else {
        NTContactGroup *group = _contacts[indexPath.section];
        contact = group.contacts[indexPath.row];
        
        //由于此方法调用十分频繁，cell的标示声明成静态变量有利于性能优化
        static NSString *cellIdentifier = @"ContactsCell";
        
        ContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[ContactsCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        }
        
        cell.nameLabel.text = contact.compositeName;
        if (contact.image == nil) {
            cell.portraitView.image = [UIImage imageNamed:@"头像"];
        } else {
            cell.portraitView.image = contact.image;
            cell.portraitView.contentMode = UIViewContentModeScaleAspectFill;
            cell.portraitView.layer.CornerRadius = CGRectGetHeight([cell.portraitView bounds]) / 2.4;
            cell.portraitView.layer.masksToBounds = YES;
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == _searchDisplayController.searchResultsTableView) {
        return @"搜索结果";
    }
    
    NTContactGroup *group = _contacts[section];
    return group.groupName;
}

// two methods needed for MJNINdexView protocol
- (NSArray *)sectionIndexTitlesForMJNIndexView:(MJNIndexView *)indexView
{
    NSMutableArray *indexs = [NSMutableArray array];
    for (NTContactGroup *group in _contacts) {
        [indexs addObject:group.groupName];
    }
    
    NSLog(@"loading index");
    return indexs;
}

- (void)sectionForSectionMJNIndexTitle:(NSString *)title atIndex:(NSInteger)index;
{
    [contactsTable scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:index] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

#pragma mark 选中行
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _searchDisplayController.searchResultsTableView)
    {
        NTContact *contact = [_searchContacts objectAtIndex:indexPath.row];
        
        //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        //由storyboard根据myView的storyBoardID来获取我们要切换的视图
        PersonViewController *myView = [story instantiateViewControllerWithIdentifier:@"Person"];
        myView.uid = contact.uid;
        //由navigationController推向我们要推向的view
        [self.navigationController pushViewController:myView animated:YES];
        return;
    }
    
    NTContactGroup *group = _contacts[indexPath.section];
    NTContact *contact = group.contacts[indexPath.row];
    
    //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    //由storyboard根据myView的storyBoardID来获取我们要切换的视图
    PersonViewController *myView = [story instantiateViewControllerWithIdentifier:@"Person"];
    myView.uid = contact.uid;
    //由navigationController推向我们要推向的view
    [self.navigationController pushViewController:myView animated:YES];
    return;
}

- (IBAction)showNewPersonView:(id)sender {
    ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
    picker.newPersonViewDelegate = self;
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person
{
    [newPersonView.navigationController popToRootViewControllerAnimated:YES];
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_searchBar resignFirstResponder];//退出键盘
    return indexPath;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
