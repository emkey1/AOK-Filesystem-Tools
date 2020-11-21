#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

/* 
 *  Simple login wrapper to force ish to prompt for username
 */

int main( void ) {

   char *argv[2] = {"", NULL}; /* You could try specifying a login here but it won't work */

   int pid = fork();

   if ( pid == 0 ) {
      printf("Welcome to the AOK iSH root filesystem\n\n");
      printf("Default login is [36m 'ish'[0m\n\n");
      execvp( "/bin/login.real", argv );
   }

   /* Put the parent to sleep for 2 seconds--let the child finished executing */
   wait( 2 );

   return 0;

}

