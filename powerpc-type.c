/*
  Determine what PowerPC subarchitecture we're running.
  Copyright (C) 2002 Colin Walters <walters@gnu.org>
*/

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>

char * get_powerpc_type(void) {
  int status;
  status = system("test -f /proc/cpuinfo && grep -q \"pmac-generation.*NewWorld\" /proc/cpuinfo");
  
  if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
    return "NewWorld PowerMac";
  }
  return "Unknown";
}

int main(int argc, char **argv) {
  fprintf(stdout, "%s\n", get_powerpc_type());
  exit(0);
}
