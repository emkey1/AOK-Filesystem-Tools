// Functions in support of the custom AOK login programs
void show_issue(void) {
    FILE *ptr;
    char ch;

    if (access("/etc/issue", F_OK) == 0) {
        // Opening file in reading mode
        ptr = fopen("/etc/issue", "r");

        // Printing what is written in file
        // character by character using loop.
        do {
            ch = fgetc(ptr);
            printf("%c", ch);

            // Checking if character is not EOF.
            // If it is EOF stop reading.
        } while (ch != EOF);

        // Closing the file
        fclose(ptr);
    }
}
