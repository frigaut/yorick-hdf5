/*
 * hdf5.c
 * wrapper routines for the hdf5 c library
 *
 * $Id: hdf5.c,v 1.2 2010-04-15 02:46:29 frigaut Exp $
 *
 * Author: Francois Rigaut.
 * Written 2004
 * last revision/addition: 2007dec26
 *
 * Copyright (c) 2003, Francois RIGAUT (frigaut@gemini.edu, Gemini
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
 *
 * $Log: hdf5.c,v $
 * Revision 1.2  2010-04-15 02:46:29  frigaut
 *
 * updated to v0.8.0
 *
 * Revision 1.1.1.1  2007/12/27 15:10:25  frigaut
 * Initial Import - yorick-hdf5
 *
 */

#include <stdio.h>
#include <string.h> /* For strcmp() */
#include <stdlib.h> /* For EXIT_FAILURE, EXIT_SUCCESS */
#include "hdf5.h"
#include "ydata.h"
#include "pstdlib.h"

void Y__H5Eon()   { H5Eset_auto((H5E_auto_t)H5Eprint,stderr); }
void Y__H5Eoff()  { H5Eset_auto(NULL,NULL); }
void Y__H5close() { H5close(); }
void Y__H5open()  { H5open(); }

void Y__H5version()
{
  unsigned majnum,minnum,relnum;
  H5get_libversion ( &majnum, &minnum, &relnum);
  Array *a= PushDataBlock(NewArray(&longStruct, ynew_dim(3L, 0)));
  a->value.l[0]=(long)majnum;
  a->value.l[1]=(long)minnum;
  a->value.l[2]=(long)relnum;
}



void Y__H5Fcreate(int nArgs)
{
  char *filename = YGetString(sp-nArgs+1);
  long mode = YGetInteger(sp-nArgs+2);
  long create_id = YGetInteger(sp-nArgs+3);
  long access_id = YGetInteger(sp-nArgs+4);
  int status;
  status=H5Fcreate(filename, (uint) mode, (hid_t) create_id, (hid_t) access_id);
  PushIntValue(status);
}

void Y__H5Fopen(int nArgs)
{
  char *filename = YGetString(sp-nArgs+1);
  long flags = YGetInteger(sp-nArgs+2);
  long access_id = YGetInteger(sp-nArgs+3);
  int status;
  status=H5Fopen(filename, (uint) flags, (hid_t) access_id);
  PushIntValue(status);
}

void Y__H5Fclose(int nArgs)
{
  long file_id = YGetInteger(sp-nArgs+1);
  int status;
  H5Fflush((hid_t) file_id, H5F_SCOPE_LOCAL);
  status=H5Fclose((hid_t) file_id);
  PushIntValue(status);
}


void Y__H5Areads(int nArgs)
{
  long attid = YGetInteger(sp-nArgs+1);
  Dimension *strdims = 0;
  char **data=  YGet_Q(sp-nArgs+2,0,&strdims);
  long nelem = YGetInteger(sp-nArgs+3);

  hid_t atype;
  void  **buf[nelem];
  int i;

  atype = H5Tcopy(H5T_C_S1);
  H5Tset_size(atype,H5T_VARIABLE);
  H5Tset_strpad(atype,H5T_STR_NULLTERM);
  H5Tset_cset(atype,H5T_CSET_ASCII);

  H5Aread(attid,atype,&buf);

  Array *a= PushDataBlock(NewArray(&stringStruct,strdims));
  // below and 134: added (char *) on 2009/07/16
  for (i=0;i<nelem;i++) a->value.q[i] = p_strcpy((char *)buf[i]);

  //free(buf);

  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Dreads(int nArgs)
{
  long did = YGetInteger(sp-nArgs+1);
  Dimension *strdims = 0;
  char **data=  YGet_Q(sp-nArgs+2,0,&strdims);
  long nelem = YGetInteger(sp-nArgs+3);

  hid_t atype;
  void  **buf[nelem];
  int i;

  atype = H5Tcopy(H5T_C_S1);
  H5Tset_size(atype,H5T_VARIABLE);
  H5Tset_strpad(atype,H5T_STR_NULLTERM);
  H5Tset_cset(atype,H5T_CSET_ASCII);

  H5Dread(did,atype,0,0,0,&buf);

  Array *a= PushDataBlock(NewArray(&stringStruct,strdims));
  for (i=0;i<nelem;i++) a->value.q[i] = p_strcpy((char *)buf[i]);

  PopTo(sp-nArgs-1);
  Drop(nArgs);
}


void Y__H5Gget_linkval(int nArgs)
{
  long loc_id = YGetInteger(sp-nArgs+1);
  char *gname = YGetString(sp-nArgs+2);
  long size = YGetInteger(sp-nArgs+3);
  char *value = YGetString(sp-nArgs+4);

  PushIntValue((long)H5Gget_linkval((hid_t) loc_id, gname, (size_t)size, value));
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Gopen(nArgs)
{
  long loc_id = YGetInteger(sp-nArgs+1);
  char *gname = YGetString(sp-nArgs+2);

  PushIntValue((long)H5Gopen((hid_t)loc_id, gname));
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Gclose(nArgs)
{
  long gid = YGetInteger(sp-nArgs+1);

  PushIntValue((long)H5Gclose((hid_t)gid));
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Gcreate(nArgs)
{
  long loc_id = YGetInteger(sp-nArgs+1);
  char *gname = YGetString(sp-nArgs+2);
  long size_hint = YGetInteger(sp-nArgs+3);

  PushIntValue((long)H5Gcreate((hid_t)loc_id, gname, (size_t)size_hint));
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Gget_num_objs(nArgs)
{
  long gid = YGetInteger(sp-nArgs+1);
  hsize_t num_obj=0;

  H5Gget_num_objs((hid_t)gid, &num_obj);
  PushIntValue((long)num_obj);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Gget_objname_by_idx(int nArgs)
{
  long loc_id = YGetInteger(sp-nArgs+1);
  long idx    = YGetInteger(sp-nArgs+2);
  char *name  = YGetString(sp-nArgs+3);
  long size   = YGetInteger(sp-nArgs+4);

  H5Gget_objname_by_idx((hid_t)loc_id, (hsize_t)idx,name,(size_t)size);
  Drop(nArgs);
}


void Y__H5Gget_objtype_by_idx(int nArgs)
{
  long loc_id = YGetInteger(sp-nArgs+1);
  long idx    = YGetInteger(sp-nArgs+2);

  PushIntValue((long)H5Gget_objtype_by_idx((hid_t)loc_id, (hsize_t)idx));
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Gget_objtype_by_name(int nArgs)
{
  long loc_id = YGetInteger(sp-nArgs+1);
  char *name  = YGetString(sp-nArgs+2);
  Dimension *dims = 0;
  long *objnum = YGet_L(sp-nArgs+3,0, &dims);

  H5G_stat_t   statbuf;
  hbool_t      followlink=0;
  H5Gget_objinfo((hid_t)loc_id,name,followlink,&statbuf);

  objnum[0] = statbuf.objno[0];
  objnum[1] = statbuf.objno[1];

  PushIntValue((long)statbuf.type);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Glink2(int nArgs)
{
  long curr_loc_id = YGetInteger(sp-nArgs+1);
  char *curname    = YGetString(sp-nArgs+2);
  long link_type   = YGetInteger(sp-nArgs+3);
  long new_loc_id  = YGetInteger(sp-nArgs+4);
  char *newname    = YGetString(sp-nArgs+5);

  PushIntValue((long)H5Glink2((hid_t)curr_loc_id, curname, 
			      (H5G_link_t)link_type, (hid_t)new_loc_id, 
			      newname));
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Gunlink(int nArgs)
{
  long loc_id = YGetInteger(sp-nArgs+1);
  char *name    = YGetString(sp-nArgs+2);

  PushIntValue((long)H5Gunlink((hid_t)loc_id, name)); 
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Pcreate(int nArgs)
{
  long cls_id = YGetInteger(sp-nArgs+1);

  PushIntValue((long)H5Pcreate((hid_t)cls_id)); 
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Pset_deflate(int nArgs)
{
  long plist = YGetInteger(sp-nArgs+1);
  long level = YGetInteger(sp-nArgs+2);

  PushIntValue((long)H5Pset_deflate((hid_t)plist,(int)level)); 
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}



//herr_t H5Pset_chunk(hid_t plist, int ndims, const hsize_t * dim)

void Y__H5Pset_chunk(int nArgs)
{
  long plist=YGetInteger(sp-nArgs+1);
  long ndims=YGetInteger(sp-nArgs+2);
  Dimension *tmpdims = 0;
  long *dim=YGet_L(sp-nArgs+3,0,&tmpdims);

  hsize_t hdim[5];

  long status,i;

  for (i=0;i<ndims;i++) hdim[i]=(hsize_t)dim[i];

  status=(long)H5Pset_chunk((hid_t)plist,(int)ndims, hdim);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Acreate(hid_t loc_id, const char *name, hid_t type_id, hid_t space_id, hid_t create_plist)
void Y__H5Acreate(int nArgs)
{
  long loc_id=YGetInteger(sp-nArgs+1);
  char *name=YGetString(sp-nArgs+2);
  long type_id=YGetInteger(sp-nArgs+3);
  long space_id=YGetInteger(sp-nArgs+4);
  long create_plist=YGetInteger(sp-nArgs+5);
  
  long status;

  status=(long)H5Acreate((hid_t)loc_id, name, (hid_t)type_id, 
			 (hid_t)space_id,(hid_t)create_plist);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Adelete(hid_t loc_id, const char *name)

void Y__H5Adelete(int nArgs)
{
  long loc_id=YGetInteger(sp-nArgs+1);
  char *name=YGetString(sp-nArgs+2);
  
  long status;

  status=(long)H5Adelete((hid_t)loc_id, name);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}


//int H5Aget_num_attrs(hid_t loc_id)

void Y__H5Aget_num_attrs(int nArgs)
{
  long loc_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Aget_num_attrs((hid_t)loc_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Aget_type(hid_t attr_id)

void Y__H5Aget_type(int nArgs)
{
  long attr_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Aget_type((hid_t)attr_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Aget_space(hid_t attr_id)

void Y__H5Aget_space(int nArgs)
{
  long attr_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Aget_space((hid_t)attr_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Aget_name(int nArgs)
{
  long attr_id=YGetInteger(sp-nArgs+1);
  long buf_size=YGetInteger(sp-nArgs+2);
  char *buf=YGetString(sp-nArgs+3);
  
  long status;

  status=(long)H5Aget_name((hid_t)attr_id, (size_t)buf_size, buf);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Aopen_idx(hid_t loc_id, unsigned int idx)

void Y__H5Aopen_idx(int nArgs)
{
  long loc_id=YGetInteger(sp-nArgs+1);
  long idx=YGetInteger(sp-nArgs+2);
  
  long status;

  status=(long)H5Aopen_idx((hid_t)loc_id, (unsigned int)idx);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Aopen_name(hid_t loc_id, const char *name)

void Y__H5Aopen_name(int nArgs)
{
  long loc_id=YGetInteger(sp-nArgs+1);
  char *name=YGetString(sp-nArgs+2);
  
  long status;

  status=(long)H5Aopen_name((hid_t)loc_id, name);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Aread(hid_t attr_id, hid_t mem_type_id, void *buf)

void Y__H5Aread(int nArgs)
{
  long attr_id=YGetInteger(sp-nArgs+1);
  long mem_type_id=YGetInteger(sp-nArgs+2);
  
  long status;

  status=(long)H5Aread((hid_t)attr_id, (hid_t)mem_type_id, yarg_sp(0));

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5Awrite(int nArgs)
{
  long attr_id=YGetInteger(sp-nArgs+1);
  long mem_type_id=YGetInteger(sp-nArgs+2);

  long status;

  status=(long)H5Awrite((hid_t)attr_id, (hid_t)mem_type_id, yarg_sp(0));

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Aclose(hid_t attr_id)

void Y__H5Aclose(int nArgs)
{
  long attr_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Aclose((hid_t)attr_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Dclose(hid_t dataset_id)

void Y__H5Dclose(int nArgs)
{
  long dataset_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Dclose((hid_t)dataset_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Dcreate(hid_t loc_id, const char *name, hid_t type_id, 
//                hid_t space_id, hid_t create_plist_id)

void Y__H5Dcreate(int nArgs)
{
  long loc_id=YGetInteger(sp-nArgs+1);
  char *name=YGetString(sp-nArgs+2);
  long type_id=YGetInteger(sp-nArgs+3);
  long space_id=YGetInteger(sp-nArgs+4);
  long create_plist_id=YGetInteger(sp-nArgs+5);
  
  long status;

  status=(long)H5Dcreate((hid_t)loc_id, name, (hid_t)type_id, 
			 (hid_t)space_id,(hid_t)create_plist_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Dopen(hid_t loc_id, const char *name)

void Y__H5Dopen(int nArgs)
{
  long loc_id=YGetInteger(sp-nArgs+1);
  char *name=YGetString(sp-nArgs+2);
  
  long status;

  status=(long)H5Dopen((hid_t)loc_id, name);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Dget_space(hid_t dataset_id)

void Y__H5Dget_space(int nArgs)
{
  long dataset_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Dget_space((hid_t)dataset_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Dget_type(hid_t dataset_id)

void Y__H5Dget_type(int nArgs)
{
  long dataset_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Dget_type((hid_t)dataset_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Dread(hid_t dataset_id, hid_t mem_type_id, hid_t mem_space_id, 
//               hid_t file_space_id, hid_t xfer_plist_id, void * buf)

void Y__H5Dread(int nArgs)
{
  long dataset_id=YGetInteger(sp-nArgs+1);
  long mem_type_id=YGetInteger(sp-nArgs+2);
  long mem_space_id=YGetInteger(sp-nArgs+3);
  long file_space_id=YGetInteger(sp-nArgs+4);
  long xfer_plist_id=YGetInteger(sp-nArgs+5);
  
  long status;

  status=(long)H5Dread((hid_t)dataset_id, (hid_t)mem_type_id, 
		       (hid_t)mem_space_id, (hid_t)file_space_id, 
		       (hid_t)xfer_plist_id, yarg_sp(0));

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Dwrite(hid_t dataset_id, hid_t mem_type_id, hid_t mem_space_id, 
//                hid_t file_space_id, hid_t xfer_plist_id, const void * buf)

void Y__H5Dwrite(int nArgs)
{
  long dataset_id=YGetInteger(sp-nArgs+1);
  long mem_type_id=YGetInteger(sp-nArgs+2);
  long mem_space_id=YGetInteger(sp-nArgs+3);
  long file_space_id=YGetInteger(sp-nArgs+4);
  long xfer_plist_id=YGetInteger(sp-nArgs+5);
  
  long status;

  status=(long)H5Dwrite((hid_t)dataset_id, (hid_t)mem_type_id, 
			(hid_t)mem_space_id, (hid_t)file_space_id, 
			(hid_t)xfer_plist_id, yarg_sp(0));

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Sclose(hid_t space_id)

void Y__H5Sclose(int nArgs)
{
  long space_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Sclose((hid_t)space_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Screate(H5S_class_t type)

void Y__H5Screate(int nArgs)
{
  long type=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Screate((H5S_class_t)type);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//int H5Sget_simple_extent_ndims(hid_t space_id)

void Y__H5Sget_simple_extent_ndims(int nArgs)
{
  long space_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Sget_simple_extent_ndims((hid_t)space_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//H5S_class_t H5Sget_simple_extent_type(hid_t space_id)

void Y__H5Sget_simple_extent_type(int nArgs)
{
  long space_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Sget_simple_extent_type((hid_t)space_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}


//hid_t H5Screate_simple(int rank, const hsize_t * dims, 
//                       const hsize_t * maxdims)

void Y__H5Screate_simple(int nArgs)
{
  long rank=YGetInteger(sp-nArgs+1);
  Dimension *dimsdims = 0;
  long *dims=YGet_L(sp-nArgs+2,0,&dimsdims);
  long ismaxdims = YNotNil(sp-nArgs+2);
  Dimension *dimsmaxdims = 0;
  long *maxdims=YGet_L(sp-nArgs+2,1,&dimsmaxdims);

  hsize_t hdims[5];  
  hsize_t hmaxdims[5];  

  long status,i;

  for (i=0;i<rank;i++) {
    hdims[i] = (hsize_t)dims[i];
    if (ismaxdims) {
      hmaxdims[i] = (hsize_t)maxdims[i];
    } else { hmaxdims[i] = (hsize_t)0; }
  }

  status=(long)H5Screate_simple((int)rank, hdims, hmaxdims);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}


//int H5Sget_simple_extent_dims(hid_t space_id, hsize_t *dims, 
//                              hsize_t *maxdims)

void Y__H5Sget_simple_extent_dims(int nArgs)
{
  long space_id=YGetInteger(sp-nArgs+1);
  Dimension *dimsdims = 0;
  long *dims=YGet_L(sp-nArgs+2,0,&dimsdims);
  long ismaxdims = YNotNil(sp-nArgs+2);
  Dimension *dimsmaxdims = 0;
  long *maxdims=YGet_L(sp-nArgs+3,1,&dimsmaxdims);
  
  hsize_t hdims[5];  
  hsize_t hmaxdims[5];  
  long status,i,rank;

  rank=(long)H5Sget_simple_extent_ndims((hid_t)space_id);

  if (rank<0) {
    PushIntValue(rank);
    PopTo(sp-nArgs-1);
    Drop(nArgs);
  }

  status=(long)H5Sget_simple_extent_dims((hid_t)space_id,hdims,hmaxdims);

  for (i=0;i<rank;i++) {
    dims[i] = (long)hdims[i];
    if (ismaxdims) {
      maxdims[i] = (long)hmaxdims[i];
    } else { maxdims[i] = (long)0; }
  }

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//hid_t H5Tcopy(hid_t type_id)

void Y__H5Tcopy(int nArgs)
{
  long type_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Tcopy((hid_t)type_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}


//H5T_class_t H5Tget_class(hid_t type_id)

void Y__H5Tget_class(int nArgs)
{
  long type_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Tget_class((hid_t)type_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//size_t H5Tget_size(hid_t type_id)

void Y__H5Tget_size(int nArgs)
{
  long type_id=YGetInteger(sp-nArgs+1);
  
  long status;

  status=(long)H5Tget_size((hid_t)type_id);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}


//herr_t H5Tset_cset(hid_t type_id, H5T_cset_t cset)

void Y__H5Tset_cset(int nArgs)
{
  long type_id=YGetInteger(sp-nArgs+1);
  long cset=YGetInteger(sp-nArgs+2);
  
  long status;

  status=(long)H5Tset_cset((hid_t)type_id, (H5T_cset_t)cset);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Tset_size(hid_t type_id, size_tsize)

void Y__H5Tset_size(int nArgs)
{
  long type_id=YGetInteger(sp-nArgs+1);
  long size=YGetInteger(sp-nArgs+2);

  long status;

  status=(long)H5Tset_size((hid_t)type_id, (size_t)size);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

//herr_t H5Tset_strpad(hid_t type_id, H5T_str_t strpad)

void Y__H5Tset_strpad(int nArgs)
{
  long type_id=YGetInteger(sp-nArgs+1);
  long strpad=YGetInteger(sp-nArgs+2);
  
  long status;

  status=(long)H5Tset_strpad((hid_t)type_id, (H5T_str_t)strpad);

  PushIntValue(status);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}


/************************************************************/

void Y__H5T_C_S1(int nArgs)
{
  PushIntValue((long)H5T_C_S1);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_NATIVE_CHAR(int nArgs)
{
  PushIntValue((long)H5T_NATIVE_CHAR);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_NATIVE_SHORT(int nArgs)
{
  PushIntValue((long)H5T_NATIVE_SHORT);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_NATIVE_INT(int nArgs)
{
  PushIntValue((long)H5T_NATIVE_INT);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_NATIVE_LONG(int nArgs)
{
  PushIntValue((long)H5T_NATIVE_LONG);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_NATIVE_FLOAT(int nArgs)
{
  PushIntValue((long)H5T_NATIVE_FLOAT);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_NATIVE_DOUBLE(int nArgs)
{
  PushIntValue((long)H5T_NATIVE_DOUBLE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_IEEE_F32BE(int nArgs)
{
  PushIntValue((long)H5T_IEEE_F32BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_IEEE_F32LE(int nArgs)
{
  PushIntValue((long)H5T_IEEE_F32LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_IEEE_F64BE(int nArgs)
{
  PushIntValue((long)H5T_IEEE_F64BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_IEEE_F64LE(int nArgs)
{
  PushIntValue((long)H5T_IEEE_F64LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I8BE(int nArgs)
{
  PushIntValue((long)H5T_STD_I8BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I8LE(int nArgs)
{
  PushIntValue((long)H5T_STD_I8LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I16BE(int nArgs)
{
  PushIntValue((long)H5T_STD_I16BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I16LE(int nArgs)
{
  PushIntValue((long)H5T_STD_I16LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I32BE(int nArgs)
{
  PushIntValue((long)H5T_STD_I32BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I32LE(int nArgs)
{
  PushIntValue((long)H5T_STD_I32LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I64BE(int nArgs)
{
  PushIntValue((long)H5T_STD_I64BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_I64LE(int nArgs)
{
  PushIntValue((long)H5T_STD_I64LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U8BE(int nArgs)
{
  PushIntValue((long)H5T_STD_U8BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U8LE(int nArgs)
{
  PushIntValue((long)H5T_STD_U8LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U16BE(int nArgs)
{
  PushIntValue((long)H5T_STD_U16BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U16LE(int nArgs)
{
  PushIntValue((long)H5T_STD_U16LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U32BE(int nArgs)
{
  PushIntValue((long)H5T_STD_U32BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U32LE(int nArgs)
{
  PushIntValue((long)H5T_STD_U32LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U64BE(int nArgs)
{
  PushIntValue((long)H5T_STD_U64BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_U64LE(int nArgs)
{
  PushIntValue((long)H5T_STD_U64LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B8BE(int nArgs)
{
  PushIntValue((long)H5T_STD_B8BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B8LE(int nArgs)
{
  PushIntValue((long)H5T_STD_B8LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B16BE(int nArgs)
{
  PushIntValue((long)H5T_STD_B16BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B16LE(int nArgs)
{
  PushIntValue((long)H5T_STD_B16LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B32BE(int nArgs)
{
  PushIntValue((long)H5T_STD_B32BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B32LE(int nArgs)
{
  PushIntValue((long)H5T_STD_B32LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B64BE(int nArgs)
{
  PushIntValue((long)H5T_STD_B64BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_B64LE(int nArgs)
{
  PushIntValue((long)H5T_STD_B64LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_STD_REF_OBJ(int nArgs)
{
  PushIntValue((long)H5T_STD_REF_OBJ);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_UNIX_D32BE(int nArgs)
{
  PushIntValue((long)H5T_UNIX_D32BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_UNIX_D32LE(int nArgs)
{
  PushIntValue((long)H5T_UNIX_D32LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_UNIX_D64BE(int nArgs)
{
  PushIntValue((long)H5T_UNIX_D64BE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5T_UNIX_D64LE(int nArgs)
{
  PushIntValue((long)H5T_UNIX_D64LE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}
void Y__H5P_DATASET_CREATE(int nArgs)
{
  PushIntValue((long)H5P_DATASET_CREATE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_NO_CLASS(int nArgs)
{
  PushIntValue((long)H5T_NO_CLASS);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_INTEGER(int nArgs)
{
  PushIntValue((long)H5T_INTEGER);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_FLOAT(int nArgs)
{
  PushIntValue((long)H5T_FLOAT);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_TIME(int nArgs)
{
  PushIntValue((long)H5T_TIME);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_STRING(int nArgs)
{
  PushIntValue((long)H5T_STRING);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_BITFIELD(int nArgs)
{
  PushIntValue((long)H5T_BITFIELD);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_OPAQUE(int nArgs)
{
  PushIntValue((long)H5T_OPAQUE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_COMPOUND(int nArgs)
{
  PushIntValue((long)H5T_COMPOUND);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_REFERENCE(int nArgs)
{
  PushIntValue((long)H5T_REFERENCE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_ENUM(int nArgs)
{
  PushIntValue((long)H5T_ENUM);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_VLEN(int nArgs)
{
  PushIntValue((long)H5T_VLEN);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5T_ARRAY(int nArgs)
{
  PushIntValue((long)H5T_ARRAY);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5G_UNKNOWN(int nArgs)
{
  PushIntValue((long)H5G_UNKNOWN);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5G_GROUP(int nArgs)
{
  PushIntValue((long)H5G_GROUP);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5G_DATASET(int nArgs)
{
  PushIntValue((long)H5G_DATASET);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5G_TYPE(int nArgs)
{
  PushIntValue((long)H5G_TYPE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5G_LINK(int nArgs)
{
  PushIntValue((long)H5G_LINK);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5P_DEFAULT(int nArgs)
{
  PushIntValue((long)H5P_DEFAULT);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

/*void Y__H5T_DEFAULT(int nArgs)
{
  PushIntValue((long)H5T_DEFAULT);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
  }*/

void Y__H5S_NO_CLASS(int nArgs)
{
  PushIntValue((long)H5S_NO_CLASS);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5S_SCALAR(int nArgs)
{
  PushIntValue((long)H5S_SCALAR);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

void Y__H5S_SIMPLE(int nArgs)
{
  PushIntValue((long)H5S_SIMPLE);
  PopTo(sp-nArgs-1);
  Drop(nArgs);
}

