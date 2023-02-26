#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include "functions.h"

/*
 *  Simple login wrapper to force ish to prompt for username
 *
 *  Loop back to login on exit to better simulate what a real
 *  system would do
 */

extern void show_issue(void);

int mylogin(void)
{

    char *argv[2] = {"", NULL}; // You could try specifying a login here but it won't work
    int pid = fork();

    if (pid == 0)
    {
        show_issue();
        execvp("/bin/login.original", argv);
    }

    // Wait for exit
    wait(NULL);
}

int main(void)
{
    while (1)
    {
        mylogin();
    }

    return 0;
}
