//
//  Utilities.m
//  saïgon
//
//  Created by Abraham Masri on 8/18/17.
//

#import "Utilities.h"
#import "IOKitLib.h"



// device info
char * get_internal_model_name() {
    
    size_t len = 0;
    char *name = malloc(len * sizeof(char));
    sysctlbyname("hw.model", NULL, &len, NULL, 0);

    if (len) {
        sysctlbyname("hw.model", name, &len, NULL, 0);
        printf("[INFO]: model internal name: %s\n", name);
    } else {
        printf("[ERROR]: could not get internal name!\n");
    }

    return name;
}

int ami_jailbroken () {
    
    struct utsname u = { 0 };
    uname(&u);
    
    // Check if 'SaigonARM' in the version (aka. we're jailbroken)
    return (strstr(u.version, "SaigonARM") != NULL);
}

int is_cydia_installed () {
    
    return ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]);

}

void kill_backboardd() {
    pid_t pid;
    posix_spawn(&pid, "killall", 0, 0, (char**)&(const char*[]){"killall", "blackboardd", NULL}, NULL);
}

