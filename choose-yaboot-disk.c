/* Program to search for disks with a correct yaboot setup, and then
   prompt the user for which one to install yaboot on.

   Copyright (C) 2002 Colin Walters <walters@gnu.org>
*/

#define _GNU_SOURCE

#include "libkdetect.h"
#include <parted/parted.h>
#include <stdio.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <cdebconf/debconfclient.h>

PedExceptionOption exception_handler(PedException *ex) {
  if (ex->type > 3) {
    fprintf(stderr, "A fatal error occurred: %s\n", ex->message);
    exit(1);
  }
  return PED_EXCEPTION_UNHANDLED;
}

int newworld_powermac_partition_is_bootable(PedPartition *partition) {
  if (!(partition->type & PED_PARTITION_METADATA || partition->type & PED_PARTITION_FREESPACE)) {
    if (ped_partition_is_flag_available(partition, PED_PARTITION_BOOT) &&
	ped_partition_get_flag(partition, PED_PARTITION_BOOT)) {
      /* Check for at least 800k of space. */
      if (partition->geom.length*512 >= 800 * 1024) {
	PedFileSystemType *fs = ped_file_system_probe(&partition->geom);
	if (fs && !strcmp(fs->name, "hfs"))
	  return 1;
      }
    }
  }
  return 0;
}

static char *machine_type = NULL;
char *get_powerpc_type(void) {
  if (machine_type != NULL) {
    return machine_type;
  } else {
    FILE *f = popen("./powerpc-type", "r");
    char *buf = NULL;
    int size = 0;
    int readbytes;
    if ((readbytes = getline(&buf, &size, f)) >= 0) {
      buf[readbytes-1] = '\0';
      machine_type = buf;
      return machine_type;
    }
    return "Unknown";
  }
}

int partition_is_bootable(PedPartition *partition) {
  if (!strcmp("NewWorld PowerMac", get_powerpc_type())) {
    return newworld_powermac_partition_is_bootable(partition);
  } else {
    fprintf(stderr, "Unknown machine type\n");
    return 0;
  }
}

int main(int argc, char **argv)
{
  struct debconfclient *client;
  char *p;
  char *device_list = NULL;
  char *valid_device_list = strdup("");

  ped_exception_set_handler(exception_handler);

  printf("machine type: %s\n", get_powerpc_type());
  
  device_list = (char *) malloc(512);
  device_list = get_device_list();
  printf("device list is [%s]\n",device_list);
  
  for (p = device_list; p != NULL; p = strchr(p, ' ') ? strchr(p, ' ')+1 : NULL) {
    char *end = strchr(p, ' ');
    int count = end ? end - p : strlen(p);
    char *devname = malloc(strlen("/dev/") + count + 1);
    strcpy(devname, "/dev/");
    strncat(devname, p, count);
    printf("examining device: %s", devname);
    {
      PedDevice *dev = ped_device_get(devname);
      PedDiskType *ptype;
      if (dev) {
	ptype = ped_disk_probe(dev);
	if (!strcmp(ptype->name, "mac")) {
	  PedDisk *disk = ped_disk_new(dev);
	  PedPartition *partition = NULL;
	  for (partition = ped_disk_next_partition(disk, partition); partition != NULL; partition = ped_disk_next_partition(disk, partition)) {
	    if (partition_is_bootable(partition)) {
	      printf(" (bootable)");
	      valid_device_list = realloc(valid_device_list, strlen(valid_device_list) + 1 + strlen(devname));
	      strcat(valid_device_list, " ");
	      strcat(valid_device_list, devname);
	    }
	  }
	}
      }
    }
    printf("\n");
  }

  client = debconfclient_new ();
  if (strlen(device_list) == 0) {
    client->command (client, "title", "No valid boot device", NULL);
    client->command (client, "fset", "yaboot-installer/no-valid-bootdev", "seen", "false", NULL);
    client->command (client, "input", "high", "yaboot-input/no-valid-bootdev", NULL);
    client->command (client, "go", NULL);
    exit(1);
  } else {
    client->command (client, "title", "Select device on which to install yaboot", NULL);
    client->command (client, "subst", "yaboot-installer/bootdev", "devices", valid_device_list, NULL);
    
    client->command (client, "fset", "yaboot-installer/bootdev", "seen", "false", NULL);
    client->command (client, "input", "high", "yaboot-installer/bootdev", NULL);
    client->command (client, "go", NULL);
    client->command (client, "get", "yaboot-installer/bootdev", NULL);
  }
  exit(0);
}
