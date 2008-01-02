%define name yorick-hdf5
%define version 0.6.1
%define release gemini2007dec31

Summary: yorick HDF5 plugin
Name: %{name}
Version: %{version}
Release: %{release}
Source0: %{name}-%{version}.tar.bz2
License: BSD
Group: Development/Languages
Packager: Francois Rigaut <frigaut@gemini.edu>
Url: http://www.maumae.net/yorick/doc/plugins.php
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: yorick >= 2.1 hdf5 >= 1.5


%description
 HDF5 is the yorick interface plugin to the NCSA Hierarchical Data Format
 version 5. It includes function for reading, writing, updating, getting
 information on HDF5 files.

 man page:
 DATA I/O:
 h5read(fname,target)                     return data
 h5write,fname,fullpath,data,zip=         write data
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
 h5off                              close all reference to the h5 library.
     
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


%prep
%setup -q

%build
yorick -batch make.i
make
if [ -f check.i ] ; then
   mv check.i %{name}_check.i
fi;

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/lib/yorick/lib
mkdir -p $RPM_BUILD_ROOT/usr/lib/yorick/i0
mkdir -p $RPM_BUILD_ROOT/usr/lib/yorick/i-start
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/yorick-hdf5

install -m 755 hdf5.so $RPM_BUILD_ROOT/usr/lib/yorick/lib
install -m 644 *.i $RPM_BUILD_ROOT/usr/lib/yorick/i0
install -m 644 *_start.i $RPM_BUILD_ROOT/usr/lib/yorick/i-start
install -m 644 hdf5doc.txt $RPM_BUILD_ROOT/usr/share/doc/yorick-hdf5

rm $RPM_BUILD_ROOT/usr/lib/yorick/i0/*_start.i


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/usr/lib/yorick/lib/hdf5.so
/usr/lib/yorick/i0/*.i
/usr/lib/yorick/i-start/*_start.i
/usr/share/doc/yorick-hdf5/hdf5doc.txt

%changelog
* Mon Dec 31 2007 <frigaut@users.sourceforge.net>
- new distro directory structure
- updated cvs
