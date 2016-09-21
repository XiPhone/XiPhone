//
//  AppDelegate.m
//  Kloudphone
//
//  Created by Yuan on 15/1/22.
//  Copyright (c) 2015年 Yuan. All rights reserved.
//

#import "AppDelegate.h"
#import "History.h"
#import "BZActiveRecord.h"

@interface AppDelegate ()
{
    UIBackgroundTaskIdentifier bgTask;
    NSTimer *bgTimer;
}
@end

@implementation AppDelegate

@synthesize callCenter;

-(void)updateTimer {
    //NSLog(@"Background -- %@", [NSDate date]);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if ([userDefault objectForKey:@"account"] == nil) {
        UIViewController *mainController = self.window.rootViewController;
        UIViewController *launchController = [mainController.storyboard instantiateViewControllerWithIdentifier:@"LaunchController"];
        self.window.rootViewController = launchController;
    }
   
    NSError *error = nil;
    BZObjectStore *os = [BZObjectStore openWithPath:@"kloudphone.db" error:&error];
    [BZActiveRecord setupWithObjectStore:os];
    
    self.rowid = 0;
    self.pickup = NO;
    self.callId = nil;
    
    callCenter = [[CTCallCenter alloc] init];
    callCenter.callEventHandler = ^(CTCall* call) {
        NSLog(@"call %@", call.callState);
        if ([call.callState isEqualToString:CTCallStateDisconnected]) {
            AppDelegate *app = [[UIApplication sharedApplication] delegate];
            if (app.rowid != 0 && app.pickup == YES && [app.callId isEqualToString:call.callID]) {
                NSLog(@"Call has been disconnected");
                
                BZObjectStoreConditionModel *fetchCondition = [BZObjectStoreConditionModel condition];
                fetchCondition.sqlite.where = @"rowid = ?";
                fetchCondition.sqlite.parameters = @[@(app.rowid)];
                
                NSError *error = nil;
                NSArray *objects = [History fetch:fetchCondition error:&error];
                History *history = objects[0];
                history.endTime = [NSDate date];
                history.success = YES;
                [history save:&error];
                
                app.rowid = 0;
                app.pickup = NO;
                app.callId = nil;
            }
        } else if ([call.callState isEqualToString:CTCallStateConnected]) {
            AppDelegate *app = [[UIApplication sharedApplication] delegate];
            if (app.rowid != 0 && app.pickup == NO && [app.callId isEqualToString:call.callID]) {
                NSLog(@"Call has just been connected");
                
                BZObjectStoreConditionModel *fetchCondition = [BZObjectStoreConditionModel condition];
                fetchCondition.sqlite.where = @"rowid = ?";
                fetchCondition.sqlite.parameters = @[@(app.rowid)];
                
                NSError *error = nil;
                NSArray *objects = [History fetch:fetchCondition error:&error];
                History *history = objects[0];
                history.startTime = [NSDate date];
                [history save:&error];
                
                app.pickup = YES;
            }
        } else if ([call.callState isEqualToString:CTCallStateDialing]) {
            AppDelegate *app = [[UIApplication sharedApplication] delegate];
            if (app.rowid != 0 && app.pickup == NO && app.callId == nil) {
                NSLog(@"call is dialing");
                BZObjectStoreConditionModel *fetchCondition = [BZObjectStoreConditionModel condition];
                fetchCondition.sqlite.where = @"rowid = ?";
                fetchCondition.sqlite.parameters = @[@(app.rowid)];
                
                NSError *error = nil;
                NSArray *objects = [History fetch:fetchCondition error:&error];
                History *history = objects[0];
                history.startTime = [NSDate date];
                [history save:&error];
                
                app.callId = call.callID;
            }
        }
    };
    
    NSLog(@"%f", [UIScreen mainScreen].bounds.size.width);
    bgTask = UIBackgroundTaskInvalid;
    
    // iOS8 下需要使⽤用新的 API
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound
        | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    
    return YES;
}

- (void)onMethod:(NSString *)method response:(NSDictionary *)data {
    NSLog(@"%@ --> %@", method, data);
}

-  (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"DeviceToken 获取失败,原因:%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // App 收到推送通知
    NSLog(@"%@ --> %@", @"App 收到推送通知", userInfo);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground");
    if (bgTask == UIBackgroundTaskInvalid) {
        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"background task expired");
        }];
        
        NSLog(@"started background task");
    }
    
    bgTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
    
    [bgTimer invalidate];
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"applicationDidBecomeActive");
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    NSLog(@"applicationWillTerminate");
}

@end
