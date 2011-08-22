#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc,char *argv[])
{
  FILE *fin;
  FILE *fout;
  int defaultInt;
  double defaultDouble;
  char defaultChar;
  float defaultFloat;
  bool defaultBool;
  short defaultShort;
  long defaultLong;
  int *defaultIntArray;
  double *defaultDoubleArray;
  char *defaultCharArray;
  float *defaultFloatArray;
  bool *defaultBoolArray;
  short *defaultShortArray;
  long *defaultLongArray;

  if (argc != 3)
    {
    fprintf(stderr,
            "Usage: %s class_name output_file\n",argv[0]);
    exit(1);
    }

  fout = fopen(argv[2],"w");

  if (!fout)
    {
    fprintf(stderr,"Error opening output file %s\n",argv[2]);
    exit(1);
    }

  // DO THE REAL STUFF HERE
  @DEFAULT_VALUE_CHECKS@

  fclose (fout);

  return 0;
}
