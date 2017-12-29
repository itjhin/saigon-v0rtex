//
//  Utilities.h
//  saïgon
//
//  Created by Abraham Masri on 8/18/17.
//

#ifndef Utilities_h
#define Utilities_h



#import <sys/sysctl.h>

#include <stdint.h>             // uint*_t
#include <stdlib.h>
#include <stdio.h>
#include <spawn.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/utsname.h>
#include <Foundation/Foundation.h>

#include <dirent.h>

#include "offsets.h"

#define LOG(str, args...) do { NSLog(@"[INFO]: " str "\n", ##args); } while(0)
#ifdef __LP64__
#   define ADDR "0x%016llx"
typedef uint64_t kptr_t;
#else
#   define ADDR "0x%08x"
typedef uint32_t kptr_t;
#endif

char * get_internal_model_name();
int ami_jailbroken();
int is_cydia_installed();
kern_return_t offsets_init();

void kill_backboardd();

#endif /* Utilities_h */
