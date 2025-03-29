//@ File (label = "Input directory", style = "directory") dir
//@ String(label="Specify the ROIs tag (will be added at the end of the name)", value="MAX_ROIs.zip") tag
//@ String(label="Names of the ROIs to draw (separated by comma)") Areas
//@ Boolean(label="Do a MAX projection to draw?") max


// This Macro allow to draw and save ROIs for multiple areas in all images in a folder 
// Images can be stack or single plane, MAX projection can be produced checking the "MAX project" option
// For convinience a list of predefined names is presented, however during drawing Areas can be skipped, other names can be added at will.
// Add the name of the areas that you want to draw in the array list called Areas (between "" and separated by commas)
Areas=split(Areas,",");
print("Areas to draw:");
for (j =0; j<Areas.length; j++) {
	print(Areas[j]);
}

waitForUser("SAVE ALL UNSAVED CHANGES TO ROIs") ;

list = getFileList(dir);
for (i = 0; i < list.length; i++) {
	 if (endsWith(list[i], ".tif")){
	 	 print(i + ": " + dir+list[i]);
         open(dir+File.separator+list[i]);
         Original_image =getImageID();
         getDimensions(width, height, channels, slices, frames);
         tit = getTitle();
         titWext= File.nameWithoutExtension;
         
         if(max==true){
         	run("Z Project...", "projection=[Max Intensity]");
         	selectImage(Original_image);
         	close(); 
         }
         //Enhance Contrast
         for (k = 0; k < channels; k++) {
         	Stack.setChannel(k);
         	run("Enhance Contrast...", "saturated=0.5");  	
         }
         
         // Set tools and windows
		 run("Channels Tool...");
         roiManager("reset") ;
	     setTool("polygon");
	     
	     // Draw areas
		 for (j =0; j<Areas.length; j++) {
		 	waitForUser("Draw the "+Areas[j]+" contour than click OK");
		 	// Check ROI existance (in case one was skipped)
		 	if(selectionType()!=-1){
			 	Roi.setName(Areas[j]);
			 	roiManager("Add");
			 	roiManager("Show All");
		 	}
		 }
	  waitForUser("Click OK to save");
	  // recreate the ugly name of the masks and single channel images
	  if(roiManager("count")>0){
	  	roiManager("save", dir+ File.separator +titWext+"_"+tag+".zip") ;
	  } else {
	  	print("No ROIs were drawn, nothing will be saved")
	  }
	  close(); 	
		 }
	 }
