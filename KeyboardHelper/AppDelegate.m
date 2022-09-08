//
//  AppDelegate.m
//  KeyboardHelper
//
//  Created by Fang on 2021/3/10.
//

#import "AppDelegate.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    BOOL alreadyRuning = false;
    NSString * mainBundleID = @"com.murphy.KeyboardCounter";
    
    for (NSRunningApplication * app in [NSWorkspace sharedWorkspace].runningApplications ) {
        if ([app.bundleIdentifier isEqualToString:mainBundleID]) {
            alreadyRuning = true;
            break;
        }
    }
    
    if (!alreadyRuning) {
        [NSDistributedNotificationCenter.defaultCenter addObserverForName:@"killHelper" object:mainBundleID queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
            [NSApp terminate:nil];
        }];
        
        NSString * path = NSBundle.mainBundle.bundlePath;
        NSMutableArray * components = [path.pathComponents mutableCopy];
        [components removeLastObject];
        [components removeLastObject];
        [components removeLastObject];
        [components addObject:@"MacOS"];
        [components addObject:@"KeyboardCounter"];
        
        NSString * newPath = [NSString pathWithComponents:components];
        if ([NSWorkspace.sharedWorkspace launchApplication:newPath]) {
            NSLog(@"打开成功");
        } else {
            NSLog(@"打开失败 - %@", newPath);
        }
        
//        NSWorkspaceOpenConfiguration * configuration = [NSWorkspaceOpenConfiguration configuration];
//        [NSWorkspace.sharedWorkspace openApplicationAtURL:[NSURL fileURLWithPath:newPath] configuration:configuration completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
//
//        }];
        
    } else {
        [NSApp terminate:nil];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    NSLog(@"helper - %s",__func__);
}


@end
