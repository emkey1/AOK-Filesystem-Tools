#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

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

/*
 *  Simple login wrapper to force ish to prompt for username
 */

int main(void)
{
   char *argv[2] = {"login", NULL}; // You could try specifying a login here but it won't work
   int pid = fork();

   if (pid == 0)
   {
      show_issue();
      execvp("/bin/busybox", argv);
   }

   /* Wait */
   wait(NULL);

   return 0;
}
