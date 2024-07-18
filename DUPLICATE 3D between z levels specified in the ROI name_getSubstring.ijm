// This Macro export a duplicate substack from rois in witch the first and last slice
// are indicated in the ROI name as _zSTART-END_ (.ie con_nbl_n_starter_roi_z75-216_)


dir=getDirectory("Choose a Directory");

for (i=0; i<roiManager("count"); ++i) {
	roiManager("Select", i);
	name=getInfo("roi.name");
	zStringMIN = getSubstring(name, "_z", "-");
	zStringMAX = getSubstring(name, "-", "_");
	zValue = NaN; //or whatever to tell you that you could not read the value
		if(zStringMIN!="") {
   			zValueMIN=parseInt(zStringMIN); //parseFloat if not always an integer value
   			zValueMAX=parseInt(zStringMAX);
				print ("MIN:"+zValueMIN+";MAX:"+zValueMAX);
				run("Duplicate...", "duplicate slices="+zValueMIN+"-"+zValueMAX);
				saveAs("tif", dir+name+"_"+".tif");
				close();
}
}


function getSubstring(string, prefix, postfix) {
   start=indexOf(name, prefix)+lengthOf(prefix);
   end=start+indexOf(substring(name, start), postfix);
   if(start>=0&&end>=0)
     return substring(name, start, end);
   else
     return "";
}