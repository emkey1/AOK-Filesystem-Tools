#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include "functions.h"

extern void show_issue(void);

/*
 *  Simple login wrapper to force ish to prompt for username
 */

int main(void)
{
   char *argv[2] = {"", NULL}; // You could try specifying a login here but it won't work
   int pid = fork();

   if (pid == 0)
   {
      show_issue();
      execvp("/bin/login.original", argv);
   }

   /* Wait */
   wait(NULL);

   return 0;
}
