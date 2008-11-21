// to be called by the shell script h5convert
// usefull for mass conversion and easy access from
// the shell

require,"util_fr.i";
require,"hdf5.i";

func h5convert_help(void)
{
  write,"h5convert [-v# -f -p -h] file1 file2 ...";
  write,"   -v#: verbose level (0,1,2)";
  write,"   -p:  in place (output name = input name)";
  write,"   -f:  force processing file, even though it should not";
  write,"   -h:  this help";
  write,"files can use widlcards";
  quit;
}

// progress args
a = get_argv();
w = (a == "h5convert_fromshell.i");
if (where(w)(1)==numberof(a)) h5convert_help;
// keep only flags and files
a = a (where(w)(1)+1:);

// find flags
w = strglob("-*",a);
if (anyof(w)) {
  flags = a(where(w));
  if (anyof(flags=="-v0")) verbose=0;
  if (anyof(flags=="-v1")) verbose=1;
  if (anyof(flags=="-v2")) verbose=2;
  if (anyof(flags=="-f"))  force=1;
  if (anyof(flags=="-p"))  inplace=1;
  if (anyof(flags=="-h"))  h5convert_help;
 }  

// files to process (can have wildcards)
w = where(w==0);
if (numberof(w)==0) h5convert_help;
files = a(w);
filesv = [];

// build string vector with all files
for (i=1;i<=numberof(files);i++) {
  grow,filesv,findfiles(files(i));
 }

// do it
h5old2new,filesv,inplace=inplace,verbose=verbose,force=force;

quit
