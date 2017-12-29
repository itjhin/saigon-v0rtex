//
//  main.m
//  Saigon
//
//  Created by Abraham Masri on 10/23/17.
//  Copyright © 2017 cheesecakeufo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int load_command(char * path) {
    
    printf("[INFO]: loading %s\n", path);
    sleep(2);
    
    extern int launchctl_load_cmd(const char *filename, int do_load, int opt_force, int opt_write);
    int rv = launchctl_load_cmd(path, 1, 0, 0);
    sleep(2);
    
    printf("[INFO]: subrv = %d\n", rv);
//    system("/Developer/usr/bin/killall backboardd");
    return rv;
}

int main(int argc, char * argv[]) {
    
    
    if (argc > 2 && strstr(argv[1], "derp"))
        return load_command(argv[2]);
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

