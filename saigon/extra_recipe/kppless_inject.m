////
////  kppless_inject.m
////  saïgon
////
////  Taken from come's Substitute
////
//
//#include "kppless_inject.h"
//
//#include <mach/mach.h>
//#include <mach-o/dyld_images.h>
//#include <dlfcn.h>
//#include <pthread.h>
//#include <sys/param.h>
//#include <sys/mman.h>
//#include <stdint.h>
//#include <stdio.h>
//#include <stdlib.h>
//#include <stdbool.h>
//
//extern const struct dyld_all_image_infos *_dyld_get_all_image_infos();
//
//#define DEFINE_STRUCTS
//
//#define dyld_image_infos_fields(ptr) \
//uint32_t version; \
//uint32_t infoArrayCount; \
//ptr infoArray; \
//ptr notification; \
//bool processDetachedFromSharedRegion; \
//bool libSystemInitialized; \
//ptr dyldImageLoadAddress; \
//ptr jitInfo; \
//ptr dyldVersion; \
//ptr errorMessage; \
//ptr terminationFlags; \
//ptr coreSymbolicationShmPage; \
//ptr systemOrderFlag; \
//ptr uuidArrayCount; \
//ptr uuidArray; \
//ptr dyldAllImageInfosAddress; \
//ptr initialImageCount; \
//ptr errorKind; \
//ptr errorClientOfDylibPath; \
//ptr errorTargetDylibPath; \
//ptr errorSymbol; \
//ptr sharedCacheSlide; \
//uint8_t sharedCacheUUID[16]; \
//ptr reserved[16];
//
//struct dyld_all_image_infos_64 {
//    dyld_image_infos_fields(uint64_t)
//};
//
//#define FFI_SHORT_CIRCUIT -1
//
//kern_return_t find_foreign_images(mach_port_t task, struct foreign_image *images, size_t nimages) {
//
//    struct task_dyld_info tdi;
//    mach_msg_type_number_t cnt = TASK_DYLD_INFO_COUNT;
//    
//    kern_return_t kr = task_info(task, TASK_DYLD_INFO, (void *) &tdi, &cnt);
//    if (kr || cnt != TASK_DYLD_INFO_COUNT) {
//        printf("[ERROR]: task_info(TASK_DYLD_INFO): kr=%d\n", kr);
//        return KERN_ABORTED;
//    }
//    
//    if (!tdi.all_image_info_addr || !tdi.all_image_info_size ||
//        tdi.all_image_info_size > 1024 ||
//        tdi.all_image_info_format > TASK_DYLD_ALL_IMAGE_INFO_64) {
//        printf("[ERROR]: TASK_DYLD_INFO obviously malformed\n");
//        return KERN_ABORTED;
//    }
//    
//    char all_image_infos_buf[1024];
//    
//    cnt = tdi.all_image_info_size;
//    mach_vm_size_t size;
//    kr = mach_vm_read_overwrite(task, tdi.all_image_info_addr,
//                                tdi.all_image_info_size,
//                                (mach_vm_address_t) all_image_infos_buf, &size);
//    if (kr || size != tdi.all_image_info_size) {
//        printf("[ERROR]: mach_vm_read_overwrite(all_image_info): kr=%d\n", kr);
//        return KERN_ABORTED;
//    }
//
//    const struct dyld_all_image_infos_64 *aii64 = (void *) all_image_infos_buf;
//
//    if (aii64->version < 2) {
//        /* apparently we're on Leopard or something */
//        printf("[ERROR]: dyld_all_image_infos version too low\n");
//        return KERN_ABORTED;
//    }
//    
//    /* If we are on the same shared cache with the same slide, then we can just
//     * look up the symbols locally and don't have to do the rest of the
//     * syscalls... not sure if this is any faster, but whatever. */
//    if (aii64->version >= 13) {
//        const struct dyld_all_image_infos *local_aii = _dyld_get_all_image_infos();
//        if (local_aii->version >= 13 &&
//            aii64->sharedCacheSlide == local_aii->sharedCacheSlide &&
//            !memcmp(aii64->sharedCacheUUID, local_aii->sharedCacheUUID, 16)) {
//            printf("[INFO]: could not find shared cache on the same slide\n");
//            return FFI_SHORT_CIRCUIT;
//        }
//    }
//    
//    
//    uint64_t info_array_addr = aii64->infoArray;
//    uint32_t info_array_count = aii64->infoArrayCount;
//    size_t info_array_elm_size = sizeof(uint64_t) * 3;
//    
//    
//    if (info_array_count > 2000) {
//        printf("[ERROR]: unreasonable number of loaded libraries: %u\n", info_array_count);
//        return KERN_ABORTED;
//    }
//    size_t info_array_size = info_array_count * info_array_elm_size;
//    void *info_array = malloc(info_array_count * info_array_elm_size);
//    if (!info_array) {
//        printf("[ERROR]: info_array not setup correctly\n");
//        return KERN_ABORTED;
//    }
//    
//    kr = mach_vm_read_overwrite(task, info_array_addr, info_array_size,
//                                (mach_vm_address_t) info_array, &size);
//    if (kr || size != info_array_size) {
//        printf("[ERROR]: mach_vm_read_overwrite(info_array): kr=%d\n", kr);
//        free(info_array);
//        return KERN_ABORTED;
//    }
//    
//    /* yay, slow file path reads! */
//    
//    void *info_array_ptr = info_array;
//    size_t images_left = nimages;
//    for (uint32_t i = 0; i < info_array_count; i++) {
//        uint64_t load_address;
//        uint64_t file_path;
//        
//        uint64_t *e = info_array_ptr;
//        load_address = e[0];
//        file_path = e[1];
//
//        
//        /* mach_vm_read_overwrite won't do partial copies, so... */
//        
//        char path_buf[MAXPATHLEN+1];
//        size_t toread = MIN(MAXPATHLEN, -file_path & 0xfff);
//        path_buf[toread] = '\0';
//        kr = mach_vm_read_overwrite(task, file_path, toread,
//                                    (mach_vm_address_t) path_buf, &size);
//        if (kr) {
//            /* printf("kr=%d <%p %p>\n", kr, (void *) file_path, path_buf); */
//            continue;
//        }
//        if (strlen(path_buf) == toread && toread < MAXPATHLEN) {
//            /* get the rest... */
//            kr = mach_vm_read_overwrite(task, file_path + toread,
//                                        MAXPATHLEN - toread,
//                                        (mach_vm_address_t) path_buf + toread,
//                                        &size);
//            if (kr) {
//                continue;
//            }
//            path_buf[MAXPATHLEN] = '\0';
//        }
//        
//        for (size_t i = 0; i < nimages; i++) {
//            if (!images[i].address &&
//                !strcmp(path_buf, images[i].name)) {
//                images[i].address = load_address;
//                if (--images_left == 0) {
//                    free(info_array);
//                    printf("[INFO]: success!\n");
//                    return KERN_SUCCESS;
//                }
//            }
//        }
//        
//        info_array_ptr += info_array_elm_size;
//    }
//    
//    free(info_array);
//    printf("[ERROR]: couldn't find libdyld or libpthread\n");
//    return KERN_ABORTED;
//}
//
//
//static int get_foreign_image_export(mach_port_t task, uint64_t hdr_addr,
//                                    void **linkedit_p, size_t *linkedit_size_p,
//                                    void **export_p, size_t *export_size_p,
//                                    cpu_type_t *cputype_p) {
//    mach_vm_offset_t hdr_buf = 0;
//    mach_vm_size_t hdr_buf_size;
//    int ret;
//    
//    vm_prot_t cur, max;
//    hdr_buf_size = PAGE_SIZE;
//    kern_return_t kr = mach_vm_remap(mach_task_self(), &hdr_buf, hdr_buf_size, 0,
//                                     VM_FLAGS_ANYWHERE, task, hdr_addr,
//                                     /*copy*/ true, &cur, &max, VM_INHERIT_NONE);
//    if (kr) {
//        printf("[ERROR]: mach_vm_remap(libdyld header): kr=%d\n", kr);
//        return KERN_ABORTED;
//    }
//    
//    struct mach_header *mh = (void *) hdr_buf;
//    if (mh->magic != MH_MAGIC && mh->magic != MH_MAGIC_64) {
//        return("[ERROR]: bad magic in libdyld mach_header\n");
//        ret = KERN_ABORTED;
//        goto fail;
//    }
//    
//    *cputype_p = mh->cputype;
//    
//    size_t mh_size = mh->magic == MH_MAGIC_64 ? sizeof(struct mach_header_64)
//    : sizeof(struct mach_header);
//    if (mh->sizeofcmds < mh_size || mh->sizeofcmds > 128*1024)
//        goto badmach;
//    
//    size_t total_size = mh_size + mh->sizeofcmds;
//    if (total_size > hdr_buf_size) {
//        vm_deallocate(mach_task_self(), (vm_offset_t) hdr_buf,
//                      (vm_size_t) hdr_buf_size);
//        hdr_buf_size = total_size;
//        hdr_buf = 0;
//        kr = mach_vm_remap(mach_task_self(), &hdr_buf, hdr_buf_size, 0,
//                           VM_FLAGS_ANYWHERE, task, hdr_addr, /*copy*/ true,
//                           &cur, &max, VM_INHERIT_NONE);
//        if (kr) {
//            printf("[ERROR]: mach_vm_remap(libdyld header) #2: kr=%d\n", kr);
//            ret = KERN_ABORTED;
//            goto fail;
//        }
//        mh = (void *) hdr_buf;
//    }
//    
//    struct load_command *lc = (void *) mh + mh_size;
//    uint32_t export_off = 0, export_size = 0;
//    uint64_t slide = 0;
//    for (uint32_t i = 0; i < mh->ncmds; i++, lc = (void *) lc + lc->cmdsize) {
//        size_t remaining = total_size - ((void *) lc - (void *) mh);
//        if (remaining < sizeof(*lc) || remaining < lc->cmdsize)
//            goto badmach;
//        if (lc->cmd == LC_DYLD_INFO || lc->cmd == LC_DYLD_INFO_ONLY) {
//            struct dyld_info_command *dc = (void *) lc;
//            if (lc->cmdsize < sizeof(*dc))
//                goto badmach;
//            export_off = dc->export_off;
//            export_size = dc->export_size;
//        } else if (lc->cmd == LC_SEGMENT) {
//            struct segment_command *sc = (void *) lc;
//            if (lc->cmdsize < sizeof(*sc))
//                goto badmach;
//            if (sc->fileoff == 0)
//                slide = hdr_addr - sc->vmaddr;
//        } else if (lc->cmd == LC_SEGMENT_64) {
//            struct segment_command_64 *sc = (void *) lc;
//            if (lc->cmdsize < sizeof(*sc))
//                goto badmach;
//            if (sc->fileoff == 0)
//                slide = hdr_addr - sc->vmaddr;
//        }
//    }
//    
//    if (export_off == 0) {
//        printf("[ERROR]: no LC_DYLD_INFO in libdyld header\n");
//        ret = KERN_ABORTED;
//        goto fail;
//    }
//    lc = (void *) mh + mh_size;
//    
//    
//    uint64_t export_segoff, vmaddr, fileoff, filesize;
//    for (uint32_t i = 0; i < mh->ncmds; i++, lc = (void *) lc + lc->cmdsize) {
//        if (lc->cmd == LC_SEGMENT) {
//            struct segment_command *sc = (void *) lc;
//            vmaddr = sc->vmaddr;
//            fileoff = sc->fileoff;
//            filesize = sc->filesize;
//        } else if (lc->cmd == LC_SEGMENT_64) {
//            struct segment_command_64 *sc = (void *) lc;
//            vmaddr = sc->vmaddr;
//            fileoff = sc->fileoff;
//            filesize = sc->filesize;
//        } else {
//            continue;
//        }
//        export_segoff = (uint64_t) export_off - fileoff;
//        if (export_segoff < filesize) {
//            if (export_size > filesize - export_segoff)
//                goto badmach;
//            break;
//        }
//    }
//    
//    uint64_t linkedit_addr = vmaddr + slide;
//    mach_vm_address_t linkedit_buf = 0;
//    kr = mach_vm_remap(mach_task_self(), &linkedit_buf, filesize, 0,
//                       VM_FLAGS_ANYWHERE, task, linkedit_addr, /*copy*/ true,
//                       &cur, &max, VM_INHERIT_NONE);
//    if (kr) {
//        printf("[ERROR]: mach_vm_remap(libdyld linkedit): kr=%d\n");
//        ret = KERN_ABORTED;
//        goto fail;
//    }
//    
//    *linkedit_p = (void *) linkedit_buf;
//    *linkedit_size_p = (size_t) filesize;
//    *export_p = (void *) linkedit_buf + export_segoff;
//    *export_size_p = export_size;
//    
//    ret = KERN_SUCCESS;
//    goto fail;
//    
//badmach:
//    printf("[INFO]: bad Mach-O data in libdyld header\n");
//    ret = KERN_ABORTED;
//    goto fail;
//fail:
//    vm_deallocate(mach_task_self(), (vm_offset_t) hdr_buf,
//                  (vm_size_t) hdr_buf_size);
//    return ret;
//}
//
//bool read_leb128(void **ptr, void *end, bool is_signed, uint64_t *out) {
//    uint64_t result = 0;
//    uint8_t *p = *ptr;
//    uint8_t bit;
//    unsigned int shift = 0;
//    do {
//        if (p >= (uint8_t *) end)
//            return false;
//        bit = *p++;
//        uint64_t k = bit & 0x7f;
//        if (shift < 64)
//            result |= k << shift;
//        shift += 7;
//    } while (bit & 0x80);
//    if (is_signed && (bit & 0x40) && shift < 64)
//        result |= ~((uint64_t) 0) << shift;
//    *ptr = p;
//    if (out)
//        *out = result;
//    return true;
//}
//
//bool read_leb128(void **ptr, void *end, bool is_signed, uint64_t *out);
//
//static inline bool read_cstring(void **ptr, void *end, char **out) {
//    char *s = *ptr;
//    size_t maxlen = (char *) end - s;
//    size_t len = strnlen(s, maxlen);
//    if (len == maxlen)
//        return false;
//    *out = s;
//    *ptr = s + len + 1;
//    return true;
//}
//
//
//static bool find_export_symbol(void *export, size_t export_size, const char *name,
//                               uint64_t hdr_addr, uint64_t *sym_addr_p) {
//    void *end = export + export_size;
//    void *ptr = export;
//    while (1) {
//        /* skip this symbol data */
//        uint64_t size;
//        if (!read_leb128(&ptr, end, false, &size) ||
//            size > (uint64_t) (end - ptr))
//            return false;
//        ptr += size;
//        if (ptr == end)
//            return false;
//        uint8_t i, nedges = *(uint8_t *) ptr;
//        ptr++;
//        for (i = 0; i < nedges; i++) {
//            char *prefix;
//            if (!read_cstring(&ptr, end, &prefix))
//                return false;
//            size_t prefix_len = (char *) ptr - prefix - 1;
//            uint64_t next_offset;
//            if (!read_leb128(&ptr, end, false, &next_offset))
//                return false;
//            if (!strncmp(name, prefix, prefix_len)) {
//                if (next_offset > export_size)
//                    return false;
//                ptr = export + next_offset;
//                name += prefix_len;
//                if (*name == '\0')
//                    goto got_symbol;
//                break;
//            }
//        }
//        if (i == nedges) {
//            /* not found */
//            return false;
//        }
//    }
//got_symbol:;
//    uint64_t size, flags, hdr_off;
//    if (!read_leb128(&ptr, end, false, &size))
//        return false;
//    if (!read_leb128(&ptr, end, false, &flags))
//        return false;
//    if (flags & (EXPORT_SYMBOL_FLAGS_REEXPORT |
//                 EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)) {
//        /* don't bother to support for now */
//        return false;
//    }
//    if (!read_leb128(&ptr, end, false, &hdr_off))
//        return false;
//    *sym_addr_p = hdr_addr + hdr_off;
//    return true;
//}
//
//
//static int do_baton(const char *filename, size_t filelen,
//                    mach_vm_address_t target_stackpage_end,
//                    mach_vm_address_t *target_stack_top_p,
//                    uint64_t sym_addrs[static 5],
//                    const struct shuttle *shuttle, size_t nshuttle,
//                    struct shuttle **target_shuttle_p,
//                    semaphore_t *sem_port_p,
//                    mach_port_t task) {
//    int ret;
//    
//    size_t baton_len = 64;
//    size_t shuttles_len = nshuttle * sizeof(struct shuttle);
//    size_t filelen_rounded = (filelen + 7) & ~7;
//    size_t total_len = baton_len + shuttles_len + filelen_rounded;
//    mach_vm_address_t target_stack_top = target_stackpage_end - total_len;
//    target_stack_top &= ~15;
////    if (cputype == CPU_TYPE_X86_64)
////        target_stack_top -= 8;
//    *target_stack_top_p = target_stack_top;
//    char *stackbuf = calloc(total_len, 1);
//    if (!stackbuf) {
//        printf("[ERROR]: out of memory allocating stackbuf\n");
//        ret = KERN_NO_SPACE;
//        goto fail;
//    }
//    strcpy(stackbuf + baton_len + shuttles_len, filename);
//    
//    struct shuttle *target_shuttle = calloc(nshuttle, sizeof(*target_shuttle));
//    *target_shuttle_p = target_shuttle;
//    for (size_t i = 0; i < nshuttle; i++) {
//        const struct shuttle *in = &shuttle[i];
//        struct shuttle *out = &target_shuttle[i];
//        out->type = in->type;
//        switch (in->type) {
//            case SUBSTITUTE_SHUTTLE_MACH_PORT:
//                out->u.mach.right_type = in->u.mach.right_type;
//                while (1) {
//                    mach_port_name_t name;
//                    kern_return_t kr = mach_port_allocate(task,
//                                                          MACH_PORT_RIGHT_DEAD_NAME,
//                                                          &name);
//                    if (kr) {
//                        printf("[ERROR]: mach_port_allocate(temp dead name): kr=%d\n",
//                                 kr);
//                        ret = KERN_ABORTED;
//                        goto fail;
//                    }
//                    kr = mach_port_deallocate(task, name);
//                    if (kr) {
//                        printf("[ERROR]: mach_port_deallocate(temp dead name): kr=%d\n",
//                                 kr);
//                        ret = KERN_ABORTED;
//                        goto fail;
//                    }
//                    kr = mach_port_insert_right(task, name, in->u.mach.port,
//                                                in->u.mach.right_type);
//                    if (kr == KERN_NAME_EXISTS) {
//                        /* between the deallocate and the insert, someone must have
//                         * grabbed this name - just try again */
//                        continue;
//                    } else if (kr) {
//                        printf("[ERROR]: mach_port_insert_right(shuttle %zu): kr=%d\n", i, kr);
//                        ret = KERN_ABORTED;
//                        goto fail;
//                    }
//                    
//                    /* ok */
//                    out->u.mach.port = name;
//                    break;
//                }
//                break;
//            default:
//                printf("[ERROR]: bad shuttle type %d\n", in->type);
//                ret = KERN_ABORTED;
//                goto fail;
//        }
//    }
//    
//    memcpy(stackbuf + baton_len, target_shuttle,
//           nshuttle * sizeof(*target_shuttle));
//    
//    semaphore_t sem_port = MACH_PORT_NULL;
//    kern_return_t kr = semaphore_create(task, &sem_port, SYNC_POLICY_FIFO, 0);
//    if (kr) {
//        printf("[ERROR]: semaphore_create: kr=%d\n", kr);
//        ret = KERN_ABORTED;
//        goto fail;
//    }
//    *sem_port_p = sem_port;
//    
//    uint64_t baton_vals[] = {
//        sym_addrs[0],
//        sym_addrs[1],
//        sym_addrs[2],
//        sym_addrs[3],
//        sym_addrs[4],
//        target_stack_top + baton_len + shuttles_len,
//        sem_port,
//        nshuttle
//    };
//    
//
//    uint64_t *p = (void *) stackbuf;
//    for (size_t i = 0; i < sizeof(baton_vals)/sizeof(*baton_vals); i++)
//        p[i] = baton_vals[i];
//
//    
//    kr = mach_vm_write(task, target_stack_top, (mach_vm_address_t) stackbuf, total_len);
//    if (kr) {
//        printf("[ERROR]: mach_vm_write(stack data): kr=%d\n", kr);
//        ret = KERN_ABORTED;
//        goto fail;
//    }
//    
//    ret = KERN_SUCCESS;
//    
//fail:
//    free(stackbuf);
//    return ret;
//}
//
//kern_return_t inject_launchd (mach_port_t launchd_task) {
//    
//    kern_return_t ret = KERN_SUCCESS;
//    
//    mach_vm_address_t target_stack = 0;
//    struct shuttle *target_shuttle = NULL;
//    semaphore_t sem_port = MACH_PORT_NULL;
//    
//    struct foreign_image images[] = {
//        {"/usr/lib/system/libdyld.dylib", 0},
//        {"/usr/lib/system/libsystem_pthread.dylib", 0},
//        {"/usr/lib/system/libsystem_kernel.dylib", 0}
//    };
//    
//    if ((ret = find_foreign_images(launchd_task, images, 3)) > 0) {
//        printf("[ERROR]: finding dylibs\n");
//        ret = KERN_ABORTED;
//        goto cleanup;
//    }
//    
//    printf("[INFO]: found dylibs\n");
//    
//    
//    uint64_t pthread_create_addr, pthread_detach_addr;
//    uint64_t dlopen_addr, dlsym_addr, munmap_addr;
//    cpu_type_t cputype;
//    if (ret == FFI_SHORT_CIRCUIT) {
//        pthread_create_addr = (uint64_t) pthread_create;
//        pthread_detach_addr = (uint64_t) pthread_detach;
//        dlopen_addr = (uint64_t) dlopen;
//        dlsym_addr = (uint64_t) dlsym;
//        munmap_addr = (uint64_t) munmap;
//        
//        cputype = CPU_TYPE_ARM64;
//        
//    } else {
//        struct {
//            uint64_t addr;
//            int nsyms;
//            struct {
//                const char *symname;
//                uint64_t symaddr;
//            } syms[2];
//        } libs[3] = {
//            {images[0].address, 2, {{"_dlopen", 0},
//                {"_dlsym", 0}}},
//            {images[1].address, 2, {{"_pthread_create", 0},
//                {"_pthread_detach", 0}}},
//            {images[2].address, 1, {{"_munmap", 0}}},
//        };
//
//        for (int i = 0; i < 3; i++) {
//            void *linkedit, *export;
//            size_t linkedit_size, export_size;
//            if ((ret = get_foreign_image_export((mach_port_t)launchd_task, libs[i].addr,
//                                                &linkedit, &linkedit_size,
//                                                &export, &export_size,
//                                                &cputype)))
//                goto cleanup;
//            const char *failed_symbol = NULL;
//            for (int j = 0; j < libs[i].nsyms; j++) {
//                if (!find_export_symbol(export, export_size,
//                                        libs[i].syms[j].symname,
//                                        libs[i].addr,
//                                        &libs[i].syms[j].symaddr)) {
//                    failed_symbol = libs[i].syms[j].symname;
//                    break;
//                }
//            }
//            
//            vm_deallocate(mach_task_self(), (vm_offset_t) linkedit,
//                          (vm_size_t) linkedit_size);
//            if (failed_symbol) {
//                printf("[ERROR]: couldn't find target symbol %s\n", failed_symbol);
//                ret = KERN_ABORTED;
//                goto cleanup;
//            }
//        }
//        
//        dlopen_addr = libs[0].syms[0].symaddr;
//        dlsym_addr = libs[0].syms[1].symaddr;
//        pthread_create_addr = libs[1].syms[0].symaddr;
//        pthread_detach_addr = libs[1].syms[1].symaddr;
//        munmap_addr = libs[2].syms[0].symaddr;
//    }
//    
//    
//    printf("[INFO]: dlopen_addr: 0x%llx\n", dlopen_addr);
//    printf("[INFO]: dlsym_addr: 0x%llx\n", dlsym_addr);
//    printf("[INFO]: pthread_create_addr: 0x%llx\n", pthread_create_addr);
//    printf("[INFO]: pthread_detach_addr: 0x%llx\n", pthread_detach_addr);
//    printf("[INFO]: munmap_addr: 0x%llx\n", munmap_addr);
//
//    
//    extern char inject_page_start[],
//    inject_start_x86_64[],
//    inject_start_i386[],
//    inject_start_arm[],
//    inject_start_arm64[];
//    
//    int target_page_size = 0x4000;
//    
//    ret = mach_vm_allocate(launchd_task, &target_stack, 2 * target_page_size, VM_FLAGS_ANYWHERE);
//    if (ret == KERN_SUCCESS) {
//        printf("[INFO]: successfully allocated target stack\n");
//    
//    } else {
//        printf("[ERROR]: couldn't allocate target stack\n");
//        goto cleanup;
//    }
//    
//
//    mach_vm_address_t target_code_page = target_stack + target_page_size;
//    vm_prot_t cur, max;
//    ret = mach_vm_remap(launchd_task, &target_code_page, target_page_size, 0,
//                       VM_FLAGS_OVERWRITE, mach_task_self(),
//                       (mach_vm_address_t) inject_page_start,
//                       /*copy*/ false,
//                       &cur, &max, VM_INHERIT_NONE);
//
//    if(ret == KERN_SUCCESS)
//        printf("[INFO]: successfully remaped targed code\n");
//    else {
//        printf("[INFO]: couldn't remap target code\n");
//        goto cleanup;
//
//    }
//    
//    mach_port_t port = 0;
//    ret = mach_port_allocate(mach_task_self(),
//                             MACH_PORT_RIGHT_RECEIVE,
//                             &port);
//    if (ret == KERN_SUCCESS) {
//        printf("[INFO]: allocated a receive right port\n");
//    } else {
//        printf("[ERROR]: could not allocate a receive right port for our task: %x", ret);
//        goto cleanup;
//    }
//    
//    uint64_t sym_addrs[] = {pthread_create_addr,
//        pthread_detach_addr,
//        dlopen_addr,
//        dlsym_addr,
//        munmap_addr};
//    mach_vm_address_t target_stack_top;
//    
//    struct shuttle shuttle = {
//        .type = SUBSTITUTE_SHUTTLE_MACH_PORT,
//        .u.mach.right_type = MACH_MSG_TYPE_MAKE_SEND,
//        .u.mach.port = port // TODO: use the priveleged port we have?
//    };
//    
//    const char *dylib_path = "/Developer/Library/Saigon/posixspawn-hook.dylib";
//    if ((ret = do_baton(dylib_path, strlen(dylib_path), target_code_page, &target_stack_top,
//                        sym_addrs, &shuttle, 1, &target_shuttle, &sem_port,
//                        launchd_task)))
//        goto cleanup;
//    
//
//    
//    
//    
//cleanup:
//    return ret;
//}
