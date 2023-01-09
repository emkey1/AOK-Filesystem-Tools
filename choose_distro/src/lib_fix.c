/*
   Part of https://github.com/emkey1/AOK-Filesystem-Tools

   License: MIT

   Copyright (c) 2023: Jacob.Lundqvist@gmail.com
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    int ret = 0;

// Remove /lib

    ret = unlink("/lib/libc.musl-x86.so.1");
    if(ret) {
        printf("Error(%d), unable to unlink /lib/libc.musl-x86.so.1\n", ret);
        exit(1);
    }

    ret = remove("/lib/ld-musl-i386.so.1");
    if(ret) {
        printf("Error(%d), unable to remove /lib/ld-musl-i386.so.1\n", ret);
        exit(1);
    }

    ret = rmdir("/lib");
    if(ret) {
        printf("Error(%d), unable to delete /lib\n", ret);
        exit(1);
    }

// Make the symlink
    ret = symlink("/usr/lib", "/lib");

    if(ret) {
       printf("Error(%d), unable to create soft link to /lib from /usr/lib\n", ret);
       exit(1);
    }

    exit(0);

}
