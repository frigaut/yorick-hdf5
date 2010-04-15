#include "hdf5.i"
g = [[1,2,3],[4,5,6],[7,8,9],[10,11,12]];
gt=transpose(g);
f = h5open("h5yorout.h5","w");
h5write, f,"base/g",g;
h5write, f,"base/gt",gt;
h5write, f,"base/dummy",1.;
// attributes
h5awrite, f,"base/dummy","g as attribute",g;
h5awrite, f,"base/dummy","attribute#2",[1,2,3];
h5awrite, f,"base/dummy","attribute#3","this is a string";
h5close, f;
"g";info,g; nprint,g*1.; g(*);
"gt";info,gt; nprint,gt*1.;
system,"h5dump h5yorout.h5";

"g read";gr=h5read("h5yorout.h5","base/g"); info,gr; nprint,gr*1.;
"gt read";gtr=h5read("h5yorout.h5","base/gt"); info,gtr; nprint,gtr*1.;

write,"\n\n\n###### Dataset ########";
write,"g:\nInput";
nprint,g*1.;
write,"\nh5dump of g:";
system,"h5dump -d /base/g h5yorout.h5";
write,"\ng as read back:";
nprint,gr*1.;

write,"\n\n\n###### Attribute #######";
write,"g:\nInput";
nprint,g*1.;
write,"\nh5dump of g:";
system,"h5dump -a \"/base/dummy/g as attribute\" h5yorout.h5";
write,"\ng as read back:";
gar=h5aread("h5yorout.h5","base/dummy","g as attribute");
info,gar;
nprint,gr*1.;

quit
