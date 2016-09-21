//
//  AppDelegate.h
//  Kloudphone
//
//  Created by Yuan on 15/1/22.
//  Copyright (c) 2015年 Yuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CTCallCenter *callCenter;
@property (strong, nonatomic) NSString *callId;
@property NSUInteger rowid;
@property BOOL pickup;
@end

