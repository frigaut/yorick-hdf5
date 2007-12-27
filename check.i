// $Id: check.i,v 1.1.1.1 2007-12-27 15:10:25 frigaut Exp $

require,"hdf5.i";
require,"fits.i";

//plug_dir,".";

dfname = "data.h5";

func checkhdf5(notiming=,keep=)
/* DOCUMENT checkhdf5(notiming=,keep=)
   keep=1  does not delete h5 files.
   SEE ALSO:
 */
{
  if (notiming==[]) notiming=1;
  d1 = span(0,60,100);
  d2 = random_n(100);
  d3 = 5.678;
  d4 = ["history list","written on 2005nov8"];
  a1 = 20.6;
  a2 = "minutes";
  a3 = [1,3,1,4,2,2];
  c=["blue","red","cyan"];

  // create file with data:
  write,"Creating data.h5 with data";
  f = h5open(dfname,"w");
  h5write,f,"/2005mar04/time",d1;
  h5write,f,"/2005mar04/data",d2;
  h5write,f,"/2005mar04/dewpoint",d3;
  h5write,f,"/2005mar04/firsthalf/21hr/dewpoint",d3;
  h5close,f;
  
  f = h5open(dfname,"a"); // check append
  h5write,f,"/2005mar04/comments",d4;
  h5write,f,"/2005mar05/name with blanks",8.97;
  write,"\nNow adding comment attributes";
  h5awrite,f,"/2005mar04","Temp on this date",a1;
  h5awrite,f,"/2005mar04/time","Units",a2;
  h5awrite,f,"/2005mar04","cups of coffee",a3;
  h5awrite,f,"/2005mar04","colors",c;
  h5close,f;

  h5awrite,dfname,"/2005mar04/time","Units2",a2;

  write,"Reading attribute color";
  c1=h5aread(dfname,"/2005mar04","colors");
  if (!allof(c==c1)) error,"Read attribute data != written data";
  write,"Deleting attribute color";
  h5adelete,dfname,"/2005mar04","colors";


  write,"\nRunning h5info";
  h5info,dfname,att=1;


  write,"\nAdding soft and hard links";
  h5link,dfname,"/bestdata","/2005mar04";
  h5link,dfname,"/multiple/path/bestdata","/2005mar04";
  h5link,dfname,"/21hr","/2005mar04/firsthalf/21hr";
  h5link,dfname,"/HL","/2005mar04",0;
  h5info,dfname,att=1;

  write,"\nTesting reads";
  d = h5read(dfname,"/2005mar04/time");
  if (!allof(d==d1)) error,"Read data != written data";
  d = h5read(dfname,"/2005mar04/data");
  if (!allof(d==d2)) error,"Read data != written data";
  d = h5read(dfname,"/2005mar04/dewpoint");
  if (!allof(d==d3)) error,"Read data != written data";
  d = h5read(dfname,"/2005mar04/comments");
  if (!allof(d==d4)) error,"Read data != written data";
  a = h5aread(dfname,"/2005mar04","Temp on this date");
  if (!allof(a==a1)) error,"Read attribute != written attribute";
  a = h5aread(dfname,"/2005mar04/time","Units");
  if (!allof(a==a2)) error,"Read attribute != written attribute";
  a = h5aread(dfname,"/2005mar04","cups of coffee");
  if (!allof(a==a3)) error,"Read attribute != written attribute";
  d = h5read(dfname,"/HL/time");
  if (!allof(d==d1)) error,"Read data != written data for hard link";
  d = h5read(dfname,"/bestdata/time");
  if (!allof(d==d1)) error,"Read data != written data for soft link";
  write,"all Read OK and identical to written data";

  write,"\nTesting compression";
  dim = 256;
  x= (indgen(dim)-dim)*array(1.0f,dim)(-,);
  y = transpose(x);
  ar=float(exp(-(sqrt(x^2.+y^2.)/12.))*20.);
  h5write,"zip.h5","/image",ar,zip=3;
  ar1=h5read("zip.h5","/image");
  if (!allof(d==d1)) error,"Read data != written data for compression";
  write,"Read Compressed OK and identical to written data";
  h5write,"nozip.h5","/image",ar;

  write,"\nTesting writing strings";
  s=["A fight is a contract that takes two people to honor.",\
     "A combative stance means that you've accepted the contract.",\
     "In which case, you deserve what you get.",\
     "  --  Professor Cheng Man-ch'ing"];
  h5write,"strings.h5","/StringsEx",s;
  h5info,"strings.h5";
  sr = h5read("strings.h5","/StringsEx");
  if (!allof(s==sr)) error,"Read data != written data for string";
  write,"Read OK and identical to written string data";
  
  if (!notiming) {
    write,"\nTiming";
    dim = 1024;
    x= (indgen(dim)-dim)*array(1.0f,dim)(-,);
    y = transpose(x);
    ar=float(exp(-(sqrt(x^2.+y^2.)/12.))*20.);
    write,"Writing...";
    pause,100;
    tic;h5write,"nozip.h5","/image",ar;t=tac();
    tic;h5write,"nozip.h5","/image",ar;t=tac();
    write,format="hdf5 %d^2 float write: %fs\n",dim,t;
    pause,100;
    tic;fits_write,"nozip.fits",ar,overwrite=1;t=tac();
    tic;fits_write,"nozip.fits",ar,overwrite=1;t=tac();
    write,format="stock fits %d^2 float write: %fs\n",dim,t;
    write,"Reading...";
    pause,100;
    tic;d=h5read("nozip.h5","/image");t=tac();
    tic;d=h5read("nozip.h5","/image");t=tac();
    write,format="hdf5 %d^2 float read: %fs\n",dim,t;
    pause,100;
    tic;d=fits_read("nozip.fits");t=tac();
    tic;d=fits_read("nozip.fits");t=tac();
    write,format="stock fits dim^2 float read: %fs\n",dim,t;
  }

  if (!keep) {
    remove,"data.h5";
    remove,"strings.h5";
    remove,"nozip.h5";
    remove,"zip.h5";
  }
}
checkhdf5;
//if (!keep) system,"rm "+dfname+" zip.h5 nozip.h5 strings.h5";

func checkmemleaks
{
  for (i=1;i<=10;i++) {
    checkhdf5,notiming=1;
    if (i==2) {
      ystats = yorick_stats();
      ystats = yorick_stats();
    }
  }
  if (nallof((ystats2=yorick_stats())==ystats)) {
    write,"memory leak?";
    write,ystats;
    write,ystats2;
  } else write,"\nNo memory leaks detected";
}
