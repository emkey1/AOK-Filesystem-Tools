#include <stdio.h>
#include <unistd.h>

/* 
 *  Simple login wrapper to force ish to be the user that logs in
 */

int main( void ) {

     	char *argv[3] = {"-f ish", NULL};

	int pid = fork();

	if ( pid == 0 ) {
		execvp( "/bin/login.real", argv );
	}

	/* Put the parent to sleep for 2 seconds--let the child finished executing */
	wait( 2 );

	printf( "Finished executing the parent process\n"
	        " - the child won't get here--you will only see this once\n" );

	return 0;

}

