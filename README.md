# yorick-hdf5
HDF5 Plugin for Yorick

This is a HDF5 plugin for yorick. It allows to do basic HDF5 operations within yorick, like saving and reading data.

```
/* DOCUMENT HDF5 plugin: Simple HIERARCHICAL DATA FORMAT 5 wrappers.
   
   DATA I/O:
     h5read(fname,target)                     return data
     h5write,fname,fullpath,data,zip=,mode=   write data
     h5open(filename,mode)                    return file handle
     h5close(filename)                        close file

   INFO, GROUP LINKING:
     h5info,fname,target,att=                 print out file info/structure
     h5link(fname,group,group2link2,linktype) link datasets
     h5delete,fname,object                    delete data

   ATTRIBUTE I/O:
     h5awrite(fname,object,aname,attdata)     write an object attribute
     h5aread(fname,object,aname)              read an object attribute
     h5adelete,fname,object,aname             delete an object attribute

   MISC:
     h5list_open                              list open files
     h5version                                return linhdf5 version
     
   ERROR RECOVERY
     h5off                                    close all reference to the
                                              h5 library (clean up).
     
   + Many of the atomic HDF5 functions are available (e.g. H5Fopen, H5Dopen)
   with mostly the same APIs. Many simple tasks can be done with the
   provided high level wrappers. Beware that programming an HDF5 custom
   wrapper is not trivial. Make sure you close every objects opened!
   
   This implementation supports reading of most of the HDF5 supported
   datatype. Only yorick datatype can be used for writes. Compression, soft
   and hard links, as well as support for attribute read/writes is provided.
   
   There is no support for hyperslabs, compound, enum or opaque datatype.
   Generally, there is very little support for datatype related
   functionalities.
   
   EXAMPLES:
   1. simplest:
   h5write,"sinus.h5","/sin2t","sin(2*indgen(100));

   2. ex2: save 2 vectors
   fd1=h5open("sinus.h5","w");  // "w" start from scratch
   t = span(0.,2*pi,100);
   h5write,fd1,"/data/t",t;
   h5write,fd1,"/data/sin2t",sin(2*t);
   h5close,fd1;

   3. ex3: append another vector and attribute
   h5write,"sinus.h5","/data/damped sin",sin(t)*exp(-0.7*t),mode="a";
   h5awrite,"sinus.h5","/data/damped sin", \
       "functional form","sin(t)*exp(-0.7t)";

   4. examine the content of the file
   h5info,"sinus.h5";

   NOTE: HDF5_SAFE is a global flag that, if set, will prevent to open
   an existing file in mode "w". In this mode, if the file has indeed
   to be overwritten, it needs to be deleted prior to the call to
   h5open.
   
   SEE ALSO:
 */
```

Note on version compatibility: This plugin was written with the HDF5 1.6 APIs. HDF5 1.8 can be used, make use of the -D H5_USE_16_API flag. I haven't 
been able to make it work with HDF5 v1.10, so 1.6 or 1.8 are required to build this plugin. You can edit the include and library path in the Makefile.


