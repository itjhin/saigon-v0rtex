//
//  kppless_inject.h
//  saïgon
//
//  Created by Abraham Masri on 10/25/17.
//  Copyright © 2017 Abraham Masri. All rights reserved.
//

#pragma once
#include <stdint.h>
#include <mach/mach.h>
#include <mach-o/loader.h>

#ifndef kppless_inject_h
#define kppless_inject_h

struct foreign_image {
    const char *name;
    uint64_t address;
};



enum shuttle_type {
    SUBSTITUTE_SHUTTLE_MACH_PORT,
    /* ... */
};

struct shuttle {
    int type;
    union {
        struct {
            mach_port_t port;
            mach_msg_type_name_t right_type;
        } mach;
    } u;
};


kern_return_t mach_vm_read_overwrite(vm_map_t, mach_vm_address_t,
                                     mach_vm_size_t, mach_vm_address_t,
                                     mach_vm_size_t *);
kern_return_t mach_vm_remap(vm_map_t, mach_vm_address_t *, mach_vm_size_t,
                            mach_vm_offset_t, int, vm_map_t, mach_vm_address_t,
                            boolean_t, vm_prot_t *, vm_prot_t *, vm_inherit_t);
kern_return_t mach_vm_write(vm_map_t, mach_vm_address_t, vm_offset_t,
                            mach_msg_type_number_t);
kern_return_t mach_vm_allocate(vm_map_t, mach_vm_address_t *, mach_vm_size_t, int);
kern_return_t mach_vm_deallocate(vm_map_t, mach_vm_address_t, mach_vm_size_t);
kern_return_t mach_vm_region(vm_map_t, mach_vm_address_t *, mach_vm_size_t *,
                             vm_region_flavor_t, vm_region_info_t,
                             mach_msg_type_number_t *, mach_port_t *);


kern_return_t inject_launchd (mach_port_t launchd_task);
#endif /* kppless_inject_h */
