#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#define MAXVERSIZE 100

/* 
 *  Simple login wrapper to force ish to prompt for username
 *
 *  Loop back to login on exit to better simulate what a real
 *  system would do
 */


int mylogin( void ) {

   char *argv[2] = {"", NULL}; // You could try specifying a login here but it won't work 
   char filename[] = "/etc/aok_release"; // Let's get the version of AOK we're running
   char version [MAXVERSIZE]; 
   FILE *file = fopen ( filename, "r" );

   if (file != NULL) {
       if(fgets(version,(sizeof version),file)== NULL) {
          strcpy(version,""); // Don't leave it empty
       } else {
          size_t ln = strlen(version) - 1;
	  if(ln > MAXVERSIZE) { // Don't let it get too large
	      ln = MAXVERSIZE -1;
	  }

          if (*version && version[ln] == '\n') 
           version[ln] = '\0';
       }
       
       fclose(file);

    } else {
       strcpy(version,""); // Don't leave it empty
    }

    int pid = fork();

    if ( pid == 0 ) {
       printf("Welcome to the AOK iSH filesystem (%s)\n\n",version);
       printf("Default login is [36m 'ish'[0m\n\n");
       execvp( "/bin/login.alpine", argv );
    }

    // Wait for exit
    wait( NULL );

}

int main( void ) {
  while(1) {
     mylogin();
  }

  return 0;

}
