//
//  AccountViewController.m
//  Kloudphone
//
//  Created by Yuan on 15/1/22.
//  Copyright (c) 2015年 Yuan. All rights reserved.
//

#import "AccountViewController.h"
#import "AccountCell.h"
#import "CMDAwesomeButton.h"

@interface AccountViewController ()
{
    NSMutableArray *optionArray;
    NSMutableArray *optionImageArray;
}
@end

@implementation AccountViewController

@synthesize accountTable;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    optionArray = [NSMutableArray arrayWithObjects:@"Credit balance: $4", @"Rates (Price List)", @"My Account", @"Setting", nil];
    optionImageArray = [NSMutableArray arrayWithObjects:@"Kloud Credit-", @"Rates (Price List)", @"My Account", @"Setting", nil];
    
    UIColor *bgcolor = [UIColor colorWithRed:133/255.0 green:88/255.0 blue:170/255.0 alpha:1];
    self.navigationController.navigationBar.barTintColor = bgcolor;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;
    
    UIImage *img = [UIImage imageNamed:@"banner"];
    UIImageView *imgView = [[UIImageView alloc] init];
    imgView.frame = CGRectMake(0, 0, 320, 197);
    imgView.image = img;
    accountTable.tableHeaderView = imgView;
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 100)];
    if ([userDefault objectForKey:@"account"] != nil) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, [UIScreen mainScreen].bounds.size.width, 20)];
        NSDictionary *dictionary = [userDefault objectForKey:@"account"];
        NSLog(@"%@", dictionary);
        label.text = [NSString stringWithFormat:@"Account: %@", [dictionary objectForKey:@"username"]];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor darkGrayColor];
        label.font = [UIFont systemFontOfSize:15];
        [footer addSubview:label];
        CMDAwesomeButton *button = [[CMDAwesomeButton alloc] initWithFrame:CGRectMake(20, 40, [UIScreen mainScreen].bounds.size.width - 40, 48)];
        [button setTitle:@"Log out" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(logoutPressed:) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundColor:[UIColor colorWithRed:228/255.0 green:31/255.0 blue:54/255.0 alpha:1] forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor colorWithRed:228/255.0 green:31/255.0 blue:54/255.0 alpha:0.85] forState:UIControlStateHighlighted];
        button.layer.cornerRadius = 8.0;
        [footer addSubview:button];
    } else {
        CMDAwesomeButton *button = [[CMDAwesomeButton alloc] initWithFrame:CGRectMake(20, 10, [UIScreen mainScreen].bounds.size.width - 40, 48)];
        [button setTitle:@"Log in" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(loginPressed:) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundColor:[UIColor colorWithRed:0/255.0 green:178/255.0 blue:238/255.0 alpha:1] forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor colorWithRed:0/255.0 green:178/255.0 blue:238/255.0 alpha:0.85] forState:UIControlStateHighlighted];
        button.layer.cornerRadius = 8.0;
        [footer addSubview:button];
    }
    accountTable.tableFooterView = footer;
}

- (void)loginPressed:(id)sender {
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginController"];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)logoutPressed:(id)sender {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:@"account"];
    [userDefault synchronize];
    UIView *footer = accountTable.tableFooterView;
    for (UIView *view in footer.subviews) {
        [view removeFromSuperview];
    }
    CMDAwesomeButton *button = [[CMDAwesomeButton alloc] initWithFrame:CGRectMake(20, 10, [UIScreen mainScreen].bounds.size.width - 40, 48)];
    [button setTitle:@"Log in" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(loginPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor colorWithRed:0/255.0 green:178/255.0 blue:238/255.0 alpha:1] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithRed:0/255.0 green:178/255.0 blue:238/255.0 alpha:0.85] forState:UIControlStateHighlighted];
    button.layer.cornerRadius = 8.0;
    [footer addSubview:button];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [optionArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //由于此方法调用十分频繁，cell的标示声明成静态变量有利于性能优化
    static NSString *cellIdentifier = @"AccountCell";
    
    AccountCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[AccountCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    cell.optionLabel.text = [optionArray objectAtIndex:indexPath.row];
    cell.iconView.image = [UIImage imageNamed:[optionImageArray objectAtIndex:indexPath.row]];
    if (indexPath.row != 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        UIButton *button;
        UIImage *image = [UIImage imageNamed:@"Buy"];
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake(0.0, 0.0, image.size.width / image.size.height * 30, 30);
        button.frame = frame;
        [button setBackgroundImage:image forState:UIControlStateNormal];
        button.backgroundColor = [UIColor clearColor];
        cell.accessoryView = button;
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 3) {
        NSLog(@"Setting");
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        UIViewController *myView = [story instantiateViewControllerWithIdentifier:@"Setting"];
        [self.navigationController pushViewController:myView animated:YES];
    }
    
    [accountTable deselectRowAtIndexPath:[accountTable indexPathForSelectedRow] animated:YES];
    return;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
