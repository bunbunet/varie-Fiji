#@ File (label="Fluorescence Images directory", style = "Directory") Dir
#@ File (label="ROIs Directory", style = "Directory") Atlas_Dir 
#@ String(label="Prefix of segmentation images (e.g. WFA-) leave blank if absent") ChRefTag
#@ String(label="Fluo Images file format") format
#@ String(label="ROIs tag") RoiTag

if(nImages>0){
	waitForUser("Warning! All Images will be closed!");
}
run("Close All");
call("java.lang.System.gc");
run("Clear Results");
roiManager("reset");

list=getFileList(Dir);

//-----------------------Loop over ROIs files and check the existence of associated Predictions and Identities---

for (k = 0; k < list.length; k++) {
	print(Dir+File.separator + list[k]);
	if (endsWith(list[k], format)) { 
		open(Dir+File.separator + list[k]);
			titWext=File.nameWithoutExtension;
			BaseName=replace(titWext,ChRefTag,"");
			RoiName=BaseName+RoiTag+".zip";
			RoiPath=Atlas_Dir+File.separator+RoiName;
			
			roiManager("reset");
			setTool("polygon");
			run("Brightness/Contrast...");
			run("Enhance Contrast", "saturated=0.35");
			waitForUser("draw areas to exclude than click ok");
			run("Make Inverse");
			roiManager("Add");
			roiManager("select", 0);
			roiManager("rename", "crop_inverted");
			roiManager("Open", RoiPath);
			nRois=roiManager("count");
			lastROI=nRois;
			print("number of ROIs: " + nRois);
			//loop through all the ROIs, add the cropped version and delete the old one
			for (i = 1; i < nRois; i++) {
				roiManager("select",1);
				name=Roi.getName;
				roiManager("select", newArray(0,1));
				roiManager("AND");
			  	if (selectionType()==-1){// if there is no area left outside the crop
			  		print(i+"-"+name + " deleted");
			  		lastROI=lastROI-1;//the total number of ROIs is reduced by 1
			  	} else {
			  		roiManager("add");
					roiManager("select",lastROI);
					roiManager("rename", name);
			  	}
			  	roiManager("deselect");
				roiManager("select",1);
				roiManager("delete");	
			}
			roiManager("deselect");
			roiManager("select", 0);
			roiManager("delete")
			roiManager("save", RoiPath);
			run("Close All");
		}
	}
