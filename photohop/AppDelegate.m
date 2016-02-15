//
//  AppDelegate.m
//  photohop
//
//  Created by Akshay Easwaran on 2/11/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import "AppDelegate.h"
#import "MemoriesViewController.h"

#import <ChameleonFramework/Chameleon.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    MemoriesViewController *memVC = [[MemoriesViewController alloc] init];
    [self.window setRootViewController:memVC];
    [self.window makeKeyAndVisible];
    return YES;
}


@end
