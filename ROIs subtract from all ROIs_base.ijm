roiManager("reset");
setTool("polygon");
waitForUser("draw areas to exclude than click ok");
run("Make Inverse");
roiManager("Add");
roiManager("select", 0);
roiManager("rename", "crop_inverted");
roiManager("Open", "C:/Users/feder/Documents/Image Analysis/Fede_Macros/CCF_Nutil DiY/Prova cut out ROI/RoiSet.zip");
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