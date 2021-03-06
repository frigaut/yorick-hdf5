HDF5_VERSION = "0.8.0";

/* HDF5 Yorick plugin
 *
 * $Id: hdf5.i,v 1.6 2010-04-15 02:46:29 frigaut Exp $
 *
 * Francois Rigaut, February 2005
 * Created: 24 February 2005
 * last revision/addition:
 *
 * $Log: hdf5.i,v $
 * Revision 1.6  2010-04-15 02:46:29  frigaut
 *
 * updated to v0.8.0
 *
 * 2009/09/16:
 * - Version 0.8.0
 * - I just realized today there was an issue with the new HDF5 APIs.
 * added dynamic declaration of H5 static variable (from their value
 * in the HDF5 include files).
 * - Also, writting attributes with string value was to be broken (see
 * note in h5awrite. Fixed by setting last param of H5Acreate to 0.
 *
 * Revision 1.5  2008/11/21 19:00:54  frigaut
 * - added some text to man page
 * - added warning mechanism through h5v062bug_warning() function.
 * - version 0.7.1
 *
 * Revision 1.4  2008/11/21 17:29:47  frigaut
 * - added some support for reading 64bits longs in a 32 bits OS
 *
 * Revision 1.3  2008/11/21 16:19:17  frigaut
 * - added h5old2new to convert pre-v0.6.2 files to post v0.6.2 file formats
 * - added h5convert and h5info shell wrappers
 * - added h5convert_fromshell.i and h5scan_fromshell.i to go with it.
 * - added h5convert.1 man page (but not yet h5info.1)
 * - updated Makefile to include these new files for the install and
 *   make package
 * - bumped version to 0.7.0
 *
 * Revision 1.2  2008/11/13 21:19:44  frigaut
 * - Fixed swapped array dimension and messed up array shape
 *   as reported by David Strozzi.
 *
 * Revision 1.1.1.1  2007/12/27 15:10:25  frigaut
 * Initial Import - yorick-hdf5
 *
 * 11 dec 2005, v0.6
 *   many hours of work on this plugin.
 *   - the whole h5open/h5close is now much more robust.
 *   - fixed many occurences where things were left open
 *   - added 2 new functions: h5version, h5list_open
 *
 * 8 nov 2005
 *   fixed issue when reading large array of strings in hdf5.c
 *
 * 25 may 2005
 *   fixed a bug in creating multiple levels groups
 *
 * 24 february 2005
 *   initial revision
 *
 *
 * Copyright (c) 2005, Francois RIGAUT (frigaut@gemini.edu, Gemini
 * Observatory, 670 N A'Ohoku Place, HILO HI-96720).
 *
 * This program is free software; you can redistribute it and/or  modify it
 * under the terms of the GNU General Public License  as  published  by the
 * Free Software Foundation; either version 2 of the License,  or  (at your
 * option) any later version.
 *
 * This program is distributed in the hope  that  it  will  be  useful, but
 * WITHOUT  ANY   WARRANTY;   without   even   the   implied   warranty  of
 * MERCHANTABILITY or  FITNESS  FOR  A  PARTICULAR  PURPOSE.   See  the GNU
 * General Public License for more details (to receive a  copy  of  the GNU
 * General Public License, write to the Free Software Foundation, Inc., 675
 * Mass Ave, Cambridge, MA 02139, USA).
*/

plug_in, "hdf5";

local hdf5;
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

//::::::::::::::::::::::::::::::::::::

HDF5_SAFE=0;
//  if set to 1, will prevent opening file that
//  already exist in mode "w". This can prevent
//  accidental deletion of important data, however
//  it can be a pain.

//::::::::::::::::::::::::::::::::::::

struct _hdf5info { string name, objectType; pointer aname; string target; };
struct _hdf5file_struct { string fname; long fd; long nref; string curmode; };

//::::::::::::::::::::::::::::::::::::


hdf5_varname_maxcar = 36; // length of variable name printout. can be changed.

// DO NOT change this:
plugin_version_string="Generated by yorick HDF5 plugin version";

  local h5convert;
/* DOCUMENT
   This is a shell command. The help is provided here for convenience.
  NAME
  h5convert  -  Conversion  of  files written with hdf5 yorick plugin pre-
                v0.6.2 to "fixed" format of v0.6.2 and higher

  SYNOPSIS
       h5convert [-p -v# -f -h] files

  DESCRIPTION
       h5convert is a shell utility to convert files that were generated  with
       the  HDF5  yorick  plugin  v<0.6.2  to  the  new,  fixed format used in
       v>=0.6.2.

       -p   perform in-place conversion (output file name = input file name)

       -f   force conversion of files generated with version>0.6.2

       -v#  verbose:  -v0:silent  -v1:files  -v2:files and contents

       -h   Print out short help

   AUTHOR
       Francois Rigaut, Gemini Observatory

   BUGS
       This  is  a patch for a previous bug. Beware: the flag "-p" will rename
       the converted file to the original name when done. Beware! This  should
       be  safe, but I haven't tested  all possible scenario (i.e. objects
       type). This will erase your original data. I encourage  you  to  check
       this conversion function on a few files before using this option.
       In particular, do not try to convert files generated by external HDF
       resources, as they will be converted while they should not!
       Also, these files may include data type and object type not yet
       implemented in the plugin, in which case it will trigger an error
       and the file may result corrupted. You have been warned.

   SEE ALSO:
 */




func h5info(file,target,att=,silent=,_recur=)
/* DOCUMENT h5info,filename,target_group,att=
   Prints out the content of a HDF5 file (groups, datasets and links)

   filename:     file name (string) or file descriptor (long)
   target_group: the root group at which to start scanning (default "/")
   att=1:        print out objects attributes (to group and datasets only)

   SEE ALSO: h5read, h5write, h5link, h5delete
 */
{
  extern objnovec,objnoname,objectInfo;

  // initialize some variable at top of recursion
  if (!_recur) {
    objnovec=[];
    objnoname=[];
    objectInfo = [];
  }

  if (!target) target="/"; //default start group

  // Open file
  if (structof(file)==string) {
    has2bclose=1;
    file = h5open(file,"r");
  }

  // Open group
  gid = _H5Gopen(file,target);
  if (gid<0) {
    if (has2bclose) h5close,file;
    error,"Unable to find group (h5info target has to be a group)";
  }

  if (!_recur) { // process the root target group
    grow,objectInfo,_hdf5info();
    objectInfo(0).name = target;
    objectInfo(0).objectType =" GROUP";
    if (!silent) \
      write,format="%-"+swrite(format="%d",hdf5_varname_maxcar)+"s",target;
    if (!silent) write,format=" %-8s\n","GROUP";
    if (att) {
      natt = _H5Aget_num_attrs(gid);
      tmp=[];
      for (na=0;na<natt;na++) {
        attid = _H5Aopen_idx(gid,na);
        str = array(" ",128)(sum);
        status= _H5Aget_name(attid,128,str);
        grow,tmp,str;
        if (!silent)                                                    \
          write,format=array(" ",hdf5_varname_maxcar+1)(sum)+           \
            "ATTRIB(%d): %-30s\n",na,strpart(str,1:30);
        status= _H5Aclose(attid);
      }
      objectInfo(0).aname=&tmp;
    }
  }

  if (target=="/") target="";

  nobj = _H5Gget_num_objs(gid);

  if (!nobj) return; // empty group

  for (i=0;i<nobj;i++) { // loop on group objects
    grow,objectInfo,_hdf5info();
    name = array(" ",128)(sum);
    size = _H5Gget_objname_by_idx(gid,i,name, 128n );
    fullname = target+"/"+name;
    dispname = fullname;
    if (strlen(fullname)>hdf5_varname_maxcar) dispname="..."+
      strpart(fullname,-(hdf5_varname_maxcar-4):0);
    if (!silent) \
      write,format="%-"+swrite(format="%d",hdf5_varname_maxcar)+"s",dispname;

    objno=[0,0];
    otype = _H5Gget_objtype_by_name(gid,fullname,objno);

    objectInfo(0).name=fullname;

    if (otype==H5G_GROUP) {
      // object is other group. we will enter recursion.
      if ((objnovec!=[])&&anyof((objno==objnovec)(sum,)==2)) {
        w = where((objno==objnovec)(sum,)==2)(1);
        link2 = objnoname(w);
        if (!silent) write,format=" %s -> %s\n","HARDLINK",link2;
        objectInfo(0).objectType="HARDLINK";
        objectInfo(0).target=link2;
      } else {
        if (!silent) write,format=" %-8s\n","GROUP";
        objectInfo(0).objectType="GROUP";
        if (att) {
          gid2 = _H5Gopen(file,fullname);
          natt = _H5Aget_num_attrs(gid2);
          tmp=[];
          for (na=0;na<natt;na++) {
            attid = _H5Aopen_idx(gid2,na);
            str = array(" ",128)(sum);
            status= _H5Aget_name(attid,128,str);
            grow,tmp,str;
            if (!silent) \
              write,format=array(" ",hdf5_varname_maxcar+1)(sum)+\
                "ATTRIB(%d): %-30s\n",na,strpart(str,1:30);
            status= _H5Aclose(attid);
          }
          objectInfo(0).aname=&tmp;
          status = _H5Gclose(gid2);
        }
        grow,objnovec,[objno];
        grow,objnoname,fullname;
        // call oneself one group down
        h5info,file,target+"/"+name,att=att,silent=silent,_recur=1;
      }

    } else if (otype==H5G_DATASET) {
      // object is dataset
      if (!silent) write,format=" %-8s ","DATASET";
      objectInfo(0).objectType="DATASET";

      dataset = _H5Dopen(file,target+"/"+name);
      // get dataspace id:
      dspid = _H5Dget_space(dataset);

      //get rank and dimensions:
      rank = _H5Sget_simple_extent_ndims(dspid);
      if (rank) {
        dims = maxdims = array(long,rank);
        status = _H5Sget_simple_extent_dims(dspid,dims,maxdims);
        dims = dims(::-1); // dim bug fix
      }
      // get type:
      yt=yotype(_H5Dget_type(dataset));
      if (yt != -1) {
        if (!silent) write,format=" %-6s ",strcase(1,typeof(yt));
      } else {
        if (!silent) write,format=" %-6s ","UNKNOWN";
      }

      if (rank) {
        if (!silent) write,format=" DIMSOF()=[%d",rank;
        for (j=1;j<=rank;j++) if (!silent) write,format=",%d",dims(j);
        if (!silent) write,format="]%s\n","";
      } else {
        if (!silent) write,format=" %sSCALAR\n","";
      }

      if (att) {
        natt = _H5Aget_num_attrs(dataset);
        tmp=[];
        for (na=0;na<natt;na++) {
          attid = _H5Aopen_idx(dataset,na);
          str = array(" ",128)(sum);
          status= _H5Aget_name(attid,128,str);
          grow,tmp,str;
          if (!silent) write,format=array(" ",hdf5_varname_maxcar+1)(sum)+\
                         "ATTRIB(%d): %-30s\n",na,
            strpart(str,1:30);
          status= _H5Aclose(attid);
        }
        objectInfo(0).aname=&tmp;
      }

      status=_H5Dclose(dataset);

    } else if (otype==H5G_LINK) {
      link2 = array(" ",128)(sum);
      status=_H5Gget_linkval(gid, fullname, 128l, link2 );
      if (!silent) write,format=" %s -> %s\n","SOFTLINK",link2;
      objectInfo(0).objectType="SOFTLINK";
      objectInfo(0).target=link2;
    } else if (otype==H5G_TYPE) {
      if (!silent) write,format=" %s\n","DADATYPE";
      objectInfo(0).objectType="DATATYPE";
    } else {
      if (!silent) write,format=" %s\n","UNKNOWN OBJECT";
      objectInfo(0).objectType="UNKNOWN OBJECT";
    }
  }
  status=_H5Gclose(gid);
  if (has2bclose) h5close,file;
  // because of recursive aspect of function:
  //  if(!_recur) _H5close;
  if (!_recur) return objectInfo;
}


//::::::::::::::::::::::::::::::::::::


func h5open(fname,mode)
/* DOCUMENT func h5open(fname,mode)
   Open file for write, append or read access.

   filename: file name
   mode:     access mode ("r"=read-only; "w"=write; "a"=append)

   Returns a file handle that can be used in further calls to HDF5
   functions (e.g. h5read, h5write).

   If HDF5_SAFE=1, try to open in mode "w" an existing file will
   produce an error ( to prevent accidentaly overwritting the data).
   Delete the file prior to the h5open call if this is the case.

   SEE ALSO: h5close, h5list_open
 */
{
  extern _hdf5file;

  if (!fname||(fname=="")) error,"h5open takes at least one argument";

  if (!mode) mode="a";

  if (noneof(mode==["r","a","w"])) {
    error,"mode should be either \"r\",\"a\" or \"w\"";
  }

  // the following is to ensure we are not opening the file twice.
  // if the call was as a function, then we return the fd for the
  // already opened file.
  // in all case, we increment the # of open reference so that
  // when we open twice, we have to close twice (each open must
  // have its corresponding close
  // this will deal with case as:
  // 1. we explicitely open the file
  // 2. we call a function that open the file automatically
  // 3. this function will close the file, but
  // 4. the file must remain open as requested in (1), thus
  //    has to be close by an explicit, balanced call to h5close
  // There is a catch to that: if the file is open in read-only,
  // we can't open it again in write or append, or vice-versa.

  if (_hdf5file!=[]) {
    if (anyof(_hdf5file.fname==fname)) {
      w = where(_hdf5file.fname==fname);
      if (numberof(w)) w=w(1);
      // error: file already open for reading
      if (((_hdf5file(w).curmode)=="r")&&(mode=="w")) {
        error,swrite(format="%s currently open for read-only",fname);
      }

      // error: file already open for writing
      if (((_hdf5file(w).curmode)=="w")&&(mode=="r")) {
        error,swrite(format="%s currently open for write-only",fname);
      }

      (_hdf5file(w).nref)++;
      return (_hdf5file(w).fd);
    }
  }

  // below we parse the input "fname" into a path and a file name.
  tok = strtok(fname,"/",20);
  tok = tok(where(tok));
  if (numberof(tok)>1) {
    path = sum(tok(1:-1)+"/");
    if (strpart(fname,1:1)=="/") path = "/"+path;
    path = strpart(path,1:-1);
  } else path=".";
  name=tok(0);

  // in case mode="r" or "a", file should already exist. check it.
  ctn = lsdir(path);
  if (anyof(mode==["a","r"])) {
    if (noneof(ctn==name))
      error,swrite(format="File does not exist (mode=\"%s\")",mode);
  } else { // mode "w"
    if ((HDF5_SAFE)&&(anyof(ctn==name)))
      error,swrite(format="File already exist (mode=\"%s\") and HDF5_SAFE=1",
                   mode);
  }

  // Open file
  if (mode=="r") {
    file=_H5Fopen(fname,H5F_ACC_RDONLY,0);
    if (file<0) {
      error,"Unable to open file (already open?)";
    }
  } else {
    // does not exist, have to create:
    if (noneof(ctn==name)) mode="w";
    if (mode=="a") { // open existing
      file = _H5Fopen(fname,H5F_ACC_RDWR,0);
      if (file<0) {
        error,"Unable to open file (already open?)";
      }
    } else { // create:
      flags = H5F_ACC_TRUNC;
      file=_H5Fcreate(fname,H5F_ACC_TRUNC,0,0);
      if (file<0) {
        error,"Unable to create file (already open?)";
      }
    }
  }
  // success. we can add the fname to the open file list:
  grow,_hdf5file,_hdf5file_struct(fname=fname,fd=file);
  w = where(_hdf5file.fname==fname)(1);
  _hdf5file(w).nref=1;
  _hdf5file(w).curmode=mode;

  return file;
}


//::::::::::::::::::::::::::::::::::::


func h5close(files)
/* DOCUMENT func h5close(files)
   Close h5 access to file(s) (after a h5open)
   files:      scalar or vector of file descriptor or file names
   Called without argument, this function closes all opened h5 files.
*/
{
  extern _hdf5file;

  if (files==[]) {
    // close all open files
    if (_hdf5file==[]) {
      write,format="%s\n","No file open";
      return 0;
    }
    // select all files fd:
    files = _hdf5file.fd;
    // force nref to 1 so that close will happen
    _hdf5file.nref = _hdf5file.nref*0+1;
  }

  for (i=1;i<=numberof(files);i++) {  // loop on input files
    if (!files(i)) continue;  // could be 0
    if (_hdf5file==[]) {
      write,format="%s\n","No file open";
      return 0;
    }
    if (structof(files(i))==string) {
      // user passed file name, not file descriptor
      w = where(_hdf5file.fname==files(i));
      wn = where(_hdf5file.fname!=files(i));
      if (numberof(w)==0)
        error,swrite(format="%s does not exist. Can not close.",files(i));
      fd = _hdf5file(w(1)).fd;
    } else {
      // user passed FD
      w = where(_hdf5file.fd==files(i));
      wn = where(_hdf5file.fd!=files(i));
      if (numberof(w)==0)
        error,swrite(format="File descriptor (%d) does not correspond"+
                     " to any open file. Can not close",files(i));
      fd = files(i);
    }
    // see comment in h5open. If files has been opened several times,
    // we don't close it until the # opened reference is == 1
    w=where(_hdf5file.fd==files(i))(1);
    if ((_hdf5file(w).nref)(1)>1) {
      (_hdf5file(w).nref)--;
      continue;
    }
    status = _H5Fclose(fd);
    if (status) error,swrite(format="Error closing file %s\n",_hdf5file(w).fname);
    // now suppress entry in _hdf5file:
    if (numberof(wn)==0) _hdf5file=[];
    else _hdf5file=_hdf5file(wn);
  }
  return 0;
}


//::::::::::::::::::::::::::::::::::::


func h5list_open(void)
/* DOCUMENT func h5list_open(void)
   Print (or return) a lit of open h5 files.
   SEE ALSO: h5open, h5close
 */
{
  extern _hdf5file;

  if (_hdf5file==[]) {
    write,format="%s\n","No file open";
    return;
  }

  if (am_subroutine()) {
    write,format="%-20s mode \"%s\" (%d ref)\n",_hdf5file.fname,
      _hdf5file.curmode,_hdf5file.nref;
  } else {
    return _hdf5file.fname;
  }
}


//::::::::::::::::::::::::::::::::::::


func h5read(file,target,pre062=)
/* DOCUMENT data=h5read(file,target,pre062=)
   Read content of one dataset in a HDF5 file and return the data

   file:     h5 file name (string) or h5 file id (output from h5open)
   target:   dataset name (string)
   pre062:   set this keyword to read files generated by this plugin
             version pre-0.6.2 (hdf5 libraries array dimensions issue)

   This will read all data type but datatype will be casted to one
   of the yorick datatype (char,short,int,long,float,double,string).
   SEE ALSO: H5write, h5info, h5link, h5delete
 */
{
  if (structof(file)==string) {
    has2bclose=1;
    file = h5open(file,"r");
  }

  // Open dataset
  dataset=_H5Dopen(file,target);
  if (dataset<0) {
    if (has2bclose) h5close,file;
    return;
    //error,"Unable to find Dataset";
  }

  // get dataspace id:
  dspid=_H5Dget_space(dataset);

  //get rank:
  rank = _H5Sget_simple_extent_ndims(dspid);
  if (rank) {
    dims = maxdims = array(long,rank);
    status = _H5Sget_simple_extent_dims(dspid,dims,maxdims);
    if (!pre062) dims = dims(::-1); // dim bug fix
  } else {dims=0;}

  ytype=yotype(_H5Dget_type(dataset),h5type);

  if (ytype==-1) error,"Unknown Datatype";

  data = array(ytype,_(rank,dims));
  if (structof(ytype)==string) {
    nelem = numberof(data);
    data=_H5Dreads(dataset,data,nelem);
  } else {
    status=_H5Dread(dataset,h5type,0,0,0,&data);
  }

  status=_H5Dclose(dataset);
  if (has2bclose) {h5close,file;}

  return data;
}


//::::::::::::::::::::::::::::::::::::


func h5write(file,fullpath,data,zip=,mode=,noheader=)
/* DOCUMENT h5write,file,fullpath,data,zip=,mode=,noheader=
   Write data in a HDF5 file.
   fname:    file name or file handle (from h5open)
   fullpath: full path to the dataset (string), including
             hierarchy (ex: "/g1/data"). If parent group(s)
             do not exist, they will be created. This function
             will refuse to overwrite an existing dataset.
             To do so, use delete the dataset with h5delete
             prior to the h5write.
   data:     data. Any yorick valid data. Scalar or arrays.
             Any yorick type is accepted (from char to double,
             and strings). Strings are stored in H5T_VARIABLE,
             which is a variable length type in the HDF5
             specification.
   zip=N     will use compression (N=0-9). Larger N will
             compress more (but take longer).

   mode=     "w"=write-only (erase previous content, default) or "a"=append

   Warning:  If file is a string, then mode="w" is used,
             which means an existing file will be overwritten.
             To update an existing file, use a file handle
             with the h5open/h5write/h5close combination.

   SEE ALSO: h5read, h5info, h5link, h5delete
 */
{
  if (!mode) mode="w";

  tmp = strpart(fullpath,strword(fullpath,"/",20));
  tmp = tmp(where(tmp));
  dataname = tmp(0);
  if (numberof(tmp)>1) {
    group = ("/"+tmp(1:-1))(sum);
  } else group="/";

  // Open/Create FILE
  if (structof(file)==string) {
    has2bclose=1;
    // default to overwrite when using the simple
    // filename option
    file = h5open(file,mode);
  }

  if ((group!="/")&&(strpart(group,0:0)=="/")) group=strpart(group,1:-1);

  // Open/Create GROUP
  gid = _H5Gopen(file,group);
  if (gid<0) { //group does not exist, create:
    g = strpart(group,strword(group,"/",20));
    g = g(where(g));
    g = "/"+g;
    for (i=1;i<=numberof(g);i++) {
      gid = _H5Gopen(file,g(1:i)(sum));
      if (gid<0) {
        gid = _H5Gcreate(file,g(1:i)(sum),0);
        status=_H5Gclose(gid);
      }
      if (gid<0) {
        if (has2bclose) h5close,file;
        error,"Unable to create group";
      }
      status=_H5Gclose(gid);
    }
    gid = _H5Gopen(file,group);
  }

  if (data==[]) { // just create a group
    gid = _H5Gopen(file,fullpath);
    if (gid<0) {
      gid = _H5Gcreate(file,fullpath,0);
      status=_H5Gclose(gid);
    }
    if (gid<0) {
      if (has2bclose) h5close,file;
      error,"Unable to create group";
    }
    swrite=0;
  } else { // create dataset and write data
    // Determine dimsof() data
    rank = dimsof(data)(1);
    if (rank>0) {
      dims = dimsof(data)(2:);
      dims = dims(::-1);   // dim bug fix
    }

    if (rank==0) {
      dataspace = _H5Screate(H5S_SCALAR);
    } else {
      dataspace=_H5Screate_simple(rank,dims);
      if (dataspace<0) {
        status=_H5Gclose(gid);
        if (has2bclose) h5close,file;
        error,"Unable to create dataspace";
      }
    }

    // Handle compression
    if ((zip!=[])&&(rank)) {
      plist  = _H5Pcreate(H5P_DATASET_CREATE);
      rank = dimsof(data)(1);
      cdims = min(dimsof(data)(2:),20);
      status = _H5Pset_chunk(plist, 2, cdims);
      status = _H5Pset_deflate( plist, zip);
    } else plist=H5P_DEFAULT;

    if (structof(data)==char) htype=H5T_NATIVE_CHAR;
    if (structof(data)==short) htype=H5T_NATIVE_SHORT;
    if (structof(data)==int) htype=H5T_NATIVE_INT;
    if (structof(data)==long) htype=H5T_NATIVE_LONG;
    if (structof(data)==float) htype=H5T_NATIVE_FLOAT;
    if (structof(data)==double) htype=H5T_NATIVE_DOUBLE;
    if (structof(data)==string) {
      /* create a datatype for the text */
      htype = _H5Tcopy(H5T_C_S1);
      /* set the total size for the datatype  */
      status = _H5Tset_size (htype,H5T_VARIABLE);
      plist = _H5Pcreate(H5P_DATASET_CREATE);
    }


    // Create dataset
    dataset=_H5Dcreate(file,group+"/"+dataname,htype,dataspace,plist);
    if (dataset<0) {
      status=_H5Sclose(dataspace);
      status=_H5Gclose(gid);
      if (has2bclose) h5close,file;
      error,"Unable to create dataset (already exist?)";
    }

    // and finally, write data...
    swrite=_H5Dwrite(dataset,htype,0,0,0,&data);

    status=_H5Sclose(dataspace);
    status=_H5Dclose(dataset);
  }

  status=_H5Gclose(gid);
  if (has2bclose) h5close,file;
  if (swrite<0) error,"Unable to write data";

  // write the yorick plugin version as an attribute of "/"
  h5awrite,file,"/",plugin_version_string,HDF5_VERSION,try=1;
}


//::::::::::::::::::::::::::::::::::::


func h5adelete(file,object,aname)
/* DOCUMENT h5adelete,file,object,aname
   Delete attribute "aname" in object "object" in HDF5 file "file"
   SEE ALSO: h5aread, h5awrite
 */
{
  // Open FILE
  if (structof(file)==string) {
    has2bclose=1;
    file = h5open(file,"a");
  }

  oid=_H5Dopen(file,object);
  if (oid<0) { // may be a group?
    oid=_H5Gopen(file,object);
    isgroup=1;
    if (oid<0) {
      if (has2bclose) h5close,file;
      error,swrite(format="Unable to find object %s\n",object);
    }
  }

  if (structof(aname)==string) {
    // attribute name passed as a string
    // check attribute exist:
    attid = _H5Aopen_name(oid,aname);
    if (attid<0) {
      if (isgroup) status=_H5Gclose(oid);
      else status=_H5Dclose(oid);
      if (has2bclose) h5close,file;
      error,swrite(format="No such attribute \"%s\" in %s\n",aname,object);
    }
    // we can (have to) close it
    status = _H5Aclose(attid);
  } else if ((structof(aname)==int)||(structof(aname)==long)) {
    // attribute name passed as an index
    attid = _H5Aopen_idx(oid,aname);
    if (attid<0) {
      if (isgroup) status=_H5Gclose(oid);
      else status=_H5Dclose(oid);
      if (has2bclose) h5close,file;
      error,swrite(format="No such attribute #%d in %s\n",aname,object);
    }
    // if it exist, then get name:
    aname = array(" ",129)(sum);
    status= _H5Aget_name(attid,128,aname);
  } else {
    if (isgroup) status=_H5Gclose(oid);
    else status=_H5Dclose(oid);
    if (has2bclose) h5close,file;
    error,"Unknow attribute name type";
  }

  status = _H5Adelete(oid,aname);

  if (isgroup) status=_H5Gclose(oid);
  else status=_H5Dclose(oid);

  if (has2bclose) h5close,file;
}


//::::::::::::::::::::::::::::::::::::


func h5aread(file,object,aname,pre062=)
/* DOCUMENT attrib = h5aread(file,object,aname,pre062=)
   Read the value of an object attribute in a HDF5 file
   file:  file name (string) or file handle (from h5open)
   object: object name (type GROUP or DATASET) (string)
   aname:  attribute name (string) or id (int).
   pre062:   set this keyword to read files generated by this plugin
             version pre-0.6.2 (hdf5 libraries array dimensions issue)

   If aname=[], then all attributes of the given object are read out
   and returned.
   SEE ALSO: h5awrite, h5adelete
 */
{
  // Open FILE
  if (structof(file)==string) {
    has2bclose=1;
    file = h5open(file,"r");
  }

  // Open object
  oid=_H5Dopen(file,object);
  if (oid<0) { // may be a group?
    oid=_H5Gopen(file,object);
    isgroup=1;
    if (oid<0) {
      if (has2bclose) h5close,file;
      error,swrite(format="Unable to find object %s\n",object);
    }
  }

  if (structof(aname)==string) {
    attid = _H5Aopen_name(oid,aname);
    if (attid<0) {
      if (isgroup) status=_H5Gclose(oid);
      else status=_H5Dclose(oid);
      if (has2bclose) h5close,file;
      error,swrite(format="No such attribute \"%s\" in %s\n",aname,object);
    }
  } else if ((structof(aname)==int)||(structof(aname)==long)) {
    attid = _H5Aopen_idx(oid,aname);
    if (attid<0) {
      if (isgroup) status=_H5Gclose(oid);
      else status=_H5Dclose(oid);
      if (has2bclose) h5close,file;
      error,swrite(format="No such attribute #%d in %s\n",aname,object);
    }
    str = array(" ",128)(sum);
    status= _H5Aget_name(attid,128,str);
    //write,format="Retrieving Attribute %s\n",str;
  } else {
    if (isgroup) status=_H5Gclose(oid);
    else status=_H5Dclose(oid);
    if (has2bclose) h5close,file;
    error,"Unknow attribute name type";
  }

  dspid = _H5Aget_space(attid);
  rank = _H5Sget_simple_extent_ndims(dspid);
  if (rank) {
    dims = maxdims = array(long,rank);
    status = _H5Sget_simple_extent_dims(dspid,dims,maxdims);
    if (!pre062) dims = dims(::-1); // dim bug fix
  } else {dims=0;}

  ytype=yotype(_H5Aget_type(attid),h5type);

  if (ytype==-1) error,"Unknow attribute data type";

  data = array(ytype,_(rank,dims));
  if (structof(ytype)==string) {
    nelem = numberof(data);
    data=_H5Areads(attid,data,nelem);
  } else {
    status=_H5Aread(attid,h5type,&data);
  }

  status=_H5Aclose(attid);
  if (isgroup) status=_H5Gclose(oid);
  else status=_H5Dclose(oid);
  if (has2bclose) h5close,file;

  if (numberof(data)==1) data=data(1);
  return data;
}


//::::::::::::::::::::::::::::::::::::


func h5awrite(file,object,aname,attdata,try=)
/* DOCUMENT h5awrite,file,object,aname,attdata
   Write an object attribute in a HDF5 file, attached to
   a group or a dataset.

   file:    file name (string) or file handle (from h5open)
   object:  object name (type GROUP or DATASET) (string)
   aname:   attribute name (string)
   attdata: attribute value (data). Any yorick type. Can be scalar
            or an array. HDF5 limits length to about 1000 elements.
   try:     if set, no errors are triggered, but the return status
            is set with the error number:
            0: no error
            1: Unable to find object
            2: Unable to create attribute dataspace
            3: Unable to create attribute (already exist?)
   SEE ALSO: h5aread, h5adelete
 */
{
  // Open FILE
  if (structof(file)==string) {
    has2bclose=1;
    file = h5open(file,"a");
  }

  // open object
  oid=_H5Dopen(file,object);
  if (oid<0) { // may be a group?
    oid=_H5Gopen(file,object);
    isgroup=1;
    if (oid<0) {
      if (has2bclose) h5close,file;
      if (try) return 1;
      else error,swrite(format="Unable to find object %s\n",object);
    }
  }


  props=H5P_DEFAULT;

  if (structof(attdata)==char) htype=H5T_NATIVE_CHAR;
  if (structof(attdata)==short) htype=H5T_NATIVE_SHORT;
  if (structof(attdata)==int) htype=H5T_NATIVE_INT;
  if (structof(attdata)==long) htype=H5T_NATIVE_LONG;
  if (structof(attdata)==float) htype=H5T_NATIVE_FLOAT;
  if (structof(attdata)==double) htype=H5T_NATIVE_DOUBLE;

  if (structof(attdata)==string) {
    /* create a datatype for the text */
    htype = _H5Tcopy(H5T_C_S1);
    /* set the total size for the datatype  */
    status = _H5Tset_size (htype,H5T_VARIABLE);
    props = _H5Pcreate(H5P_DATASET_CREATE);
  }

  rank = dimsof(attdata)(1);
  if (rank>0) {
    dims = dimsof(attdata)(2:);
    dims = dims(::-1);  // dim bug fix
  }

  if (rank==0) {
    dataspace = _H5Screate(H5S_SCALAR);
  } else {
    dataspace=_H5Screate_simple(rank,dims);
    if (dataspace<0) {
      if (isgroup) status=_H5Gclose(oid);
      else status=_H5Dclose(oid);
      if (has2bclose) h5close,file;
      if (try) return 2;
      else error,"Unable to create attribute dataspace";
    }
  }

  // 20090916: from the new hdf5 doc (H5Acreate1): The attribute creation
  // property list, acpl_id (the last one), is currently unused; it may be
  // used in the future for optional attribute properties. At this time,
  // H5P_DEFAULT is the only accepted value.
  // hence, forcing props to zero (and that made it works, broken if props
  // != 0, i.e. for strings -see above-):
  props = 0;
  /* Create a dataset attribute. */
  attid = _H5Acreate(oid, aname, htype, dataspace, props);
  if (attid<0) {
    if (has2bclose) h5close,file;
    if (try) return 3;
    else error,"Unable to create attribute (already exist?)";
  }

  /* Write the attribute data. */
  status = _H5Awrite(attid, htype, &attdata);

  /* Close the attribute. */
  status = _H5Aclose(attid);

  status=_H5Sclose(dataspace);
  if (isgroup) status=_H5Gclose(oid);
  else status=_H5Dclose(oid);

  if (has2bclose) h5close,file;
}


//::::::::::::::::::::::::::::::::::::


func h5link(file,group,group2link2,linktype)
/* DOCUMENT h5link,file,group,group2link2,linktype
   Create a SOFT or HARD link to a group in a HDF5 file

   file:        file name (string) or file handle (from h5open)
   group:       group to create that link to group2link2
                Must not already exist.
   group2link2: group to link to. Must exist. Has to be a group,
                Can NOT be a dataset (error).
   linktype:    link type. valid are:
                H5G_LINK_HARD or H5G_LINK_SOFT

   SEE ALSO: h5read, h5write, h5info, h5delete
 */
{
  if (linktype==[]) linktype=H5G_LINK_SOFT;
  if (noneof(linktype==[H5G_LINK_HARD,H5G_LINK_SOFT])) {
    error,"Unknow link type";
  }

  // Open FILE
  if (structof(file)==string) {
    has2bclose=1;
    file = h5open(file,"a");
  }

  if ((group!="/")&&(strpart(group,0:0)=="/")) group=strpart(group,1:-1);

  // Open/Create GROUP
  gid = _H5Gopen(file,group);
  if (gid>0) {
    // group already exist. it should not
    status=_H5Gclose(gid);
    if (has2bclose) h5close,file;
    error,"Group already exist";
  }

  // we create up to group parent level, as final link group will be
  // created by the H5Glink2 call
  g = strpart(group,strword(group,"/",20));
  g = g(where(g));
  if (numberof(g)==1) {
    groupParent="/";
  } else {
    groupParent = ("/"+g(1:-1))(sum);
  }

  gid = _H5Gopen(file,groupParent);
  if (gid<0) { //groupParent does not exist, create:
    g = strpart(groupParent,strword(groupParent,"/",20));
    g = g(where(g));
    g = "/"+g;
    gid2 = array(long,numberof(g));
    for (i=1;i<=numberof(g);i++) {
      gid2(i) = _H5Gopen(file,g(1:i)(sum));
      if (gid2(i)<0) gid2(i) = _H5Gcreate(file,g(1:i)(sum),0);
      if (gid2(i)<0) {
        for (j=1;j<=(i-1);j++) status = _H5Gclose(gid2(j));
        if (has2bclose) h5close,file;
        error,"Unable to create groupParent (already exist?)";
      }
    }
    gid = gid2(0);
  }

  // check that group2link2 exists

  gid2link2 = _H5Gopen(file,group2link2);
  if (gid2link2<0) {
    if (anyof(gid2)) {
      for (j=1;j<=numberof(gid2);j++) status = _H5Gclose(gid2(j));
    } else status=_H5Gclose(gid);
    if (has2bclose) h5close,file;
    error,"Unable to open destination group (has to be a group, not dataset)";
  }

  // now we can link
  slink = _H5Glink2(gid2link2, group2link2, linktype, gid, group);

  if (anyof(gid2)) {
    for (j=1;j<=numberof(gid2);j++) status = _H5Gclose(gid2(j));
  } else status=_H5Gclose(gid);
  status=_H5Gclose(gid2link2);
  if (has2bclose) h5close,file;
  if (slink<0) error,"Unable to link groups";
}


//::::::::::::::::::::::::::::::::::::


func h5delete(file,object)
/* DOCUMENT h5delete,file,object
   Unlink or delete an object in a HDF5 file.

   file:     file name (string) or file handle (from h5open)
   object:   object name (string)

   SEE ALSO: h5write, h5read, h5link, h5info
 */
{
  // Open FILE
  if (structof(file)==string) {
    has2bclose=1;
    file = h5open(file,"a");
  }

  status=_H5Gunlink(file, object);

  if (has2bclose) h5close,file;
  // if (status<0) error,"Unable to link groups";
}
h5unlink=h5delete;


//::::::::::::::::::::::::::::::::::::


func h5version(void)
{
  res = _H5version();
  if (am_subroutine()) {
    write,format="libhdf5 version %d.%d.%d\n",res(1),res(2),res(3);
  } else return res;
}


//::::::::::::::::::::::::::::::::::::


func h5old2new(files,inplace=,verbose=,force=)
/* DOCUMENT h5old2new(file,inplace=,verbose=,force=)
   Convert hdf5 files produced with hdf5 version <= 0.6.1 to
   hdf5 file compatible with version 0.6.2 and later.

   Files produced with yorick-hdf5 v<=0.6.1 suffer from an
   issue in the dimension that are reported to external HDF5
   utilities. The dimension vector is swapped, i.e. an array
   [10,20] will appear as an array [20,10] to an external HDF5
   reader (e.g. h5dump), but the elements themselves are not
   swapped, resulting in a completely different looking array.

   The "old" format files were perfectly fine within yorick
   as the same bug was present in the input and output. Only
   compatibility with external hdf5 tools was affected.

   As there is no way to know with which version of the plugin
   a file has been written, I can not correct this automatically
   when reading old files with the new plugin version. However,
   I provide a utility function (h5old2new()) that will convert
   "old file" (written with v<=0.5.1) to the new, more correct
   format.

   files: scalar or vector string
   inplace: will rename the converted file to the original name
            when done. Beware! This should be safe, but I haven't
            tested all possible scenario. This will erase your
            original data. I encourage you to check this conversion
            function on a few files before using this option
   verbose: 0: no output
            1: only prints out filename
            2: print out file and object names while processing
   force:   Normally, if this function encounters the attribute
            "Generated by yorick hdf5 plugin version"
            (plugin_version_string) and this is set to
            something higher than "0.6.2", this function will
            refuse to process the file (because it is not supposed
            to suffer from the swapped dims issue). Use force=1
            to force processing.

   SEE ALSO:
 */
{
  if (verbose==[]) verbose=1; // default at least print out filename

  for (n=1;n<=numberof(files);n++) {

    file = files(n);
    fin = h5open(file);
    all = h5info(fin,silent=1,att=1);

    // check if this file has been written with a version
    // of the plugin for which this problem was fixed (>=0.6.2)
    // if so, skip the file (unless force is set)
    if ((*all(1).aname!=[]) &&   // all(1) is always root ("/")
        (anyof(*all(1).aname==plugin_version_string))) {
      file_plugin_version = h5aread(fin,"/",plugin_version_string);
      ymajor = yminor = ymicro = 0;
      sread,file_plugin_version,format="%d.%d.%d",ymajor, yminor, ymicro;
      version = ymajor*10000+yminor*100+ymicro;
      if (version>=602) {
        write,format="WARNING: %s should not need conversion,",file;
        if (force) {
          write,format="%s\n","but you have set force=1";
          //  write,format="%s\n","         I assume you know what you're doing";
        } else {
          write,format="%s\n"," skipping.";
          continue;
        }
      }
    }


    fileout = streplace(file,strfind(".h5",file), ".new.h5");
    remove,fileout;  // shamelessly
    fout = h5open(fileout,"w");

    natt=0;
    for (i=1;i<=numberof(all);i++) {
      if ((*all(i).aname)!=[]) natt+=numberof(*(all(i).aname));
    }

    inplacestr = (inplace?" inplace ":"");
    if (verbose==1) write,format="---> Converting %s%s...",file,inplacestr;
    else if (verbose>1) {
      write,format="---> Converting %s%s(found %d elements + %d attr.):\n", \
        file,inplacestr,numberof(all),natt;
    }

    // convert: loop on all items:
    for (i=1;i<=numberof(all);i++) {
      if (verbose>1) write,format="%-9s: %s\n",all(i).objectType,all(i).name;
      if (all(i).objectType=="GROUP") {
        // let's go ahead and create the group, so that
        // we can write possible attributes
        h5write,fout,all(i).name+"/",[]; // create group
      } else if (all(i).objectType=="DATASET") {
        data = h5read(fin,all(i).name,pre062=1);
        h5write,fout,all(i).name,data;
      } else if (all(i).objectType=="SOFTLINK") {
        // it should be safe to write it now, as
        // in the initial file creation, the link
        // can only have been created after the target
        // object (is that sure?)
        h5link,fout,all(i).name,all(i).target,H5G_LINK_SOFT;
      } else if (all(i).objectType=="HARDLINK") {
        // same
        h5link,fout,all(i).name,all(i).target,H5G_LINK_HARD;
      }
      // process possible attributes
      if ((*all(i).aname)!=[]) { // there are some
        for (j=1;j<=numberof(*all(i).aname);j++) {
          if (verbose>1)                                        \
            write,format="  ATTRIBUTE: %s\n",(*all(i).aname)(j);
          // read the attribute
          adata = h5aread(fin,all(i).name,(*all(i).aname)(j),pre062=1);
          // write
          h5awrite,fout,all(i).name,(*all(i).aname)(j),adata;
        }
      }
    }
    if (verbose>0) {
      if (inplace) write,"";
      else write,format="done, results in %s\n",fileout;
    }

    h5close,fin;
    h5close,fout;
    if (inplace) rename,fileout,file;
  } // end loop on files
}

//::::::::::::::::::::::::::::::::::::
//::::::UTILITY FUNCTIONS:::::::::::::
//::::::::::::::::::::::::::::::::::::


func yotype(tid,&h5type) {

  tclass = _H5Tget_class(tid);

  if (tclass < 0) {
    error,"Invalid datatype";
  } else {

    tsize=_H5Tget_size(tid);
    if (hdf5_debug) write,format="tclass=%d  tsize=%d\n",tclass,tsize;

    if (tclass == H5T_INTEGER) {
      if (tsize==sizeof(long) )  {h5type=H5T_NATIVE_LONG;   return 0l;}
      if (tsize==sizeof(int)  )  {h5type=H5T_NATIVE_INT;    return 0n;}
      if (tsize==sizeof(short))  {h5type=H5T_NATIVE_SHORT;  return 0s;}
      if (tsize==sizeof(char) )  {h5type=H5T_NATIVE_CHAR;   return '0';}
      // read 64bits long on a 32 bits OS:
      if (tsize==8 )             {h5type=H5T_NATIVE_LONG;   return 0l;}
    } else if (tclass == H5T_FLOAT) {
      if (tsize==sizeof(float))  {h5type=H5T_NATIVE_FLOAT;  return 0.0f;}
      if (tsize==sizeof(double)) {h5type=H5T_NATIVE_DOUBLE; return 0.0;}
    } else if (tclass == H5T_STRING) {
      h5type=H5T_C_S1;
      return "";
    } else  {
      //      print,"Unknown Datatype";
      return -1;
    }
    error,"Unknown or invalid datatype";
  }
}


func h5off(void)
/* DOCUMENT h5ooff
   Flushes all data to disk, closes file identifiers, and cleans up memory.

   SEE ALSO:
 */
{
  extern _hdf5file;
  _H5close;
  _hdf5file=[];
}

/**********************************************/
/* DEFINE BUILTINS AND EXTERNS H5 DEFINITIONS */
/**********************************************/

extern _H5Eon;
extern _H5Eoff;
extern _H5open;
extern _H5close;
extern _H5version;

// FILE APIs:
extern _H5Fcreate;
extern _H5Fopen;
extern _H5Fclose;

// GROUP APIs:
extern _H5Gget_linkval;
extern _H5Gopen;
extern _H5Gclose;
extern _H5Gcreate;
extern _H5Gget_num_objs;  // numobj = _H5Gget_num_objs(gid)
extern _H5Gget_objname_by_idx;
extern _H5Gget_objtype_by_idx;
extern _H5Gget_objtype_by_name;
extern _H5Glink2;
extern _H5Gunlink;

// PROPERTY LIST APIs:
extern _H5Pcreate; //int H5Pcreate(int cls_id )
extern _H5Pset_deflate; //int H5Pset_deflate(int plist, int level)
extern _H5Pset_chunk;

// ATTRIBUTE APIs:
extern _H5Acreate;
extern _H5Adelete;
extern _H5Aget_num_attrs;
extern _H5Aget_type;
extern _H5Aget_space;
extern _H5Aget_name;
extern _H5Aopen_idx;
extern _H5Aopen_name;
extern _H5Aread;
extern _H5Awrite;
extern _H5Aclose;

// DATASET API:
extern _H5Dclose;
extern _H5Dcreate;
extern _H5Dopen;
extern _H5Dget_space;
extern _H5Dget_type;
extern _H5Dwrite;
extern _H5Dread;

// DATASPACE APIs:

extern _H5Sclose
extern _H5Screate
extern _H5Sget_simple_extent_ndims;
extern _H5Sget_simple_extent_type;
extern _H5Screate_simple;
extern _H5Sget_simple_extent_dims;

// Datatype APIs
//**************
extern _H5Tcopy;
extern _H5Tget_class;
extern _H5Tget_size;
extern _H5Tset_cset;
extern _H5Tset_size;
extern _H5Tset_strpad;


// special read function for Attributes and Dataset string reads:
extern _H5Areads;
extern _H5Dreads;


// The following types are dynamically assigned at the hdf5 library
// compile time, so I need to resort to function calls here.
extern _H5T_C_S1;              H5T_C_S1=_H5T_C_S1();
extern _H5T_NATIVE_CHAR;       H5T_NATIVE_CHAR=_H5T_NATIVE_CHAR();
extern _H5T_NATIVE_SHORT;      H5T_NATIVE_SHORT=_H5T_NATIVE_SHORT();
extern _H5T_NATIVE_INT;        H5T_NATIVE_INT=_H5T_NATIVE_INT();
extern _H5T_NATIVE_LONG;       H5T_NATIVE_LONG=_H5T_NATIVE_LONG();
extern _H5T_NATIVE_FLOAT;      H5T_NATIVE_FLOAT=_H5T_NATIVE_FLOAT();
extern _H5T_NATIVE_DOUBLE;     H5T_NATIVE_DOUBLE=_H5T_NATIVE_DOUBLE();
extern _H5T_IEEE_F32BE;        H5T_IEEE_F32BE=_H5T_IEEE_F32BE();
extern _H5T_IEEE_F32LE;        H5T_IEEE_F32LE=_H5T_IEEE_F32LE();
extern _H5T_IEEE_F64BE;        H5T_IEEE_F64BE=_H5T_IEEE_F64BE();
extern _H5T_IEEE_F64LE;        H5T_IEEE_F64LE=_H5T_IEEE_F64LE();
extern _H5T_STD_I8BE;          H5T_STD_I8BE=_H5T_STD_I8BE();
extern _H5T_STD_I8LE;          H5T_STD_I8LE=_H5T_STD_I8LE();
extern _H5T_STD_I16BE;         H5T_STD_I16BE=_H5T_STD_I16BE();
extern _H5T_STD_I16LE;         H5T_STD_I16LE=_H5T_STD_I16LE();
extern _H5T_STD_I32BE;         H5T_STD_I32BE=_H5T_STD_I32BE();
extern _H5T_STD_I32LE;         H5T_STD_I32LE=_H5T_STD_I32LE();
extern _H5T_STD_I64BE;         H5T_STD_I64BE=_H5T_STD_I64BE();
extern _H5T_STD_I64LE;         H5T_STD_I64LE=_H5T_STD_I64LE();
extern _H5T_STD_U8BE;          H5T_STD_U8BE=_H5T_STD_U8BE();
extern _H5T_STD_U8LE;          H5T_STD_U8LE=_H5T_STD_U8LE();
extern _H5T_STD_U16BE;         H5T_STD_U16BE=_H5T_STD_U16BE();
extern _H5T_STD_U16LE;         H5T_STD_U16LE=_H5T_STD_U16LE();
extern _H5T_STD_U32BE;         H5T_STD_U32BE=_H5T_STD_U32BE();
extern _H5T_STD_U32LE;         H5T_STD_U32LE=_H5T_STD_U32LE();
extern _H5T_STD_U64BE;         H5T_STD_U64BE=_H5T_STD_U64BE();
extern _H5T_STD_U64LE;         H5T_STD_U64LE=_H5T_STD_U64LE();
extern _H5T_STD_B8BE;          H5T_STD_B8BE=_H5T_STD_B8BE();
extern _H5T_STD_B8LE;          H5T_STD_B8LE=_H5T_STD_B8LE();
extern _H5T_STD_B16BE;         H5T_STD_B16BE=_H5T_STD_B16BE();
extern _H5T_STD_B16LE;         H5T_STD_B16LE=_H5T_STD_B16LE();
extern _H5T_STD_B32BE;         H5T_STD_B32BE=_H5T_STD_B32BE();
extern _H5T_STD_B32LE;         H5T_STD_B32LE=_H5T_STD_B32LE();
extern _H5T_STD_B64BE;         H5T_STD_B64BE=_H5T_STD_B64BE();
extern _H5T_STD_B64LE;         H5T_STD_B64LE=_H5T_STD_B64LE();
extern _H5T_STD_REF_OBJ;       H5T_STD_REF_OBJ=_H5T_STD_REF_OBJ();
extern _H5T_UNIX_D32BE;        H5T_UNIX_D32BE=_H5T_UNIX_D32BE();
extern _H5T_UNIX_D32LE;        H5T_UNIX_D32LE=_H5T_UNIX_D32LE();
extern _H5T_UNIX_D64BE;        H5T_UNIX_D64BE=_H5T_UNIX_D64BE();
extern _H5T_UNIX_D64LE;        H5T_UNIX_D64LE=_H5T_UNIX_D64LE();
extern _H5P_DATASET_CREATE;    H5P_DATASET_CREATE=_H5P_DATASET_CREATE();

H5F_ACC_RDONLY = 0x0000;  /* absence of rdwr => rd-only */
H5F_ACC_RDWR   = 0x0001;  /* open for read and write    */
H5F_ACC_TRUNC  = 0x0002;  /* overwrite existing files   */
H5F_ACC_EXCL   = 0x0004;  /* fail if file already exists*/
H5F_ACC_DEBUG  = 0x0008;  /* print debug info	     */
H5F_ACC_CREAT  = 0x0010;  /* create non-existing files  */

extern _H5P_DEFAULT;           H5P_DEFAULT=_H5P_DEFAULT();
//extern _H5T_DEFAULT;           H5T_DEFAULT=_H5T_DEFAULT();

//H5P_DEFAULT    = 0;
H5T_DEFAULT    = 0;

extern _H5S_NO_CLASS;          H5S_NO_CLASS=_H5S_NO_CLASS();  /* error */
extern _H5S_SCALAR;            H5S_SCALAR=_H5S_SCALAR();   /* scalar variable */
extern _H5S_SIMPLE;            H5S_SIMPLE=_H5S_SIMPLE();   /* simple data space */

//H5S_NO_CLASS   = -1;  /* error */
//H5S_SCALAR     = 0;   /* scalar variable */
//H5S_SIMPLE     = 1;   /* simple data space */

extern _H5T_NO_CLASS;          H5T_NO_CLASS=_H5T_NO_CLASS();  /* error */
extern _H5T_INTEGER;           H5T_INTEGER=_H5T_INTEGER();    /* integer types */
extern _H5T_FLOAT;             H5T_FLOAT=_H5T_FLOAT();        /* floating-point types */
extern _H5T_TIME;              H5T_TIME=_H5T_TIME();          /* date and time types */
extern _H5T_STRING;            H5T_STRING=_H5T_STRING();      /* character string types */
extern _H5T_BITFIELD;          H5T_BITFIELD=_H5T_BITFIELD();  /* bit field types */
extern _H5T_OPAQUE;            H5T_OPAQUE=_H5T_OPAQUE();      /* opaque types */
extern _H5T_COMPOUND;          H5T_COMPOUND=_H5T_COMPOUND();  /* compound types */
extern _H5T_REFERENCE;         H5T_REFERENCE=_H5T_REFERENCE();/* reference types  */
extern _H5T_ENUM;              H5T_ENUM=_H5T_ENUM();          /* enumeration types */
extern _H5T_VLEN;              H5T_VLEN=_H5T_VLEN();          /* Variable-Length types */
extern _H5T_ARRAY;             H5T_ARRAY=_H5T_ARRAY();        /* Array types */


H5T_VARIABLE   = -1;  /* Indicate that a string is variable length (null- */
                      /* terminated in C, instead of fixed length) */

/* 2009sep16: HDF5 was broken. This is because the typedef
   for the following const was changed in the last hdf5 APIs,
   and I stupidly declared it in here, instead of getting them
   from hdf5 at build time. Thus I have rewritten this (below).
   Here is how it appeared in previous version (<=0.7.1) of
   this plugin:
   H5G_UNKNOWN    = -1;
   H5G_LINK       = 0;  // now 3
   H5G_GROUP      = 1;  // now 0
   H5G_DATASET    = 2;  // now 1
   H5G_TYPE       = 3;  // now 2
   and here is how I coded it now: */
extern _H5G_UNKNOWN;   H5G_UNKNOWN=_H5G_UNKNOWN();
extern _H5G_GROUP;     H5G_GROUP=_H5G_GROUP();
extern _H5G_DATASET;   H5G_DATASET=_H5G_DATASET();
extern _H5G_TYPE;      H5G_TYPE=_H5G_TYPE();
extern _H5G_LINK;      H5G_LINK=_H5G_LINK();


H5G_LINK_ERROR	= -1; /* link types used by H5Glink2 */
H5G_LINK_HARD	= 0;
H5G_LINK_SOFT	= 1;

H5T_STR_NULLTERM = 0;

H5F_SCOPE_LOCAL	 = 0; /* specified file handle only */
H5F_SCOPE_GLOBAL = 1; /* entire virtual file */


_H5Eoff;            /* Error reporting OFF by default */
