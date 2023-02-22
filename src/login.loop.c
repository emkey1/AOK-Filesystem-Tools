#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>


/*
 *  Simple login wrapper to force ish to prompt for username
 *
 *  Loop back to login on exit to better simulate what a real
 *  system would do
 */

void show_issue(void)
{
    FILE *ptr;
    char ch;

    if (access("/etc/issue", F_OK) == 0)
    {
        // Opening file in reading mode
        ptr = fopen("/etc/issue", "r");

        // Printing what is written in file
        // character by character using loop.
        do
        {
            ch = fgetc(ptr);
            printf("%c", ch);

            // Checking if character is not EOF.
            // If it is EOF stop reading.
        } while (ch != EOF);

        // Closing the file
        fclose(ptr);
    }
}

int mylogin(void)
{

    char *argv[2] = {"login", NULL}; // You could try specifying a login here but it won't work
    int pid = fork();

    if (pid == 0)
    {
        show_issue();
        execvp("/bin/busybox", argv);
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
