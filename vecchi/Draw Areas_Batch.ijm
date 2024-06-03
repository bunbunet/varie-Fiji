@ File (label = "Input directory", style = "directory") dir

// This Macro allow to draw and save ROIs for multiple areas in all images in a folder 
// Add the name of the areas that you want to draw in the array list (between "" and separated by commas)
Areas=newArray("Neurogenic","SVZ","STR");
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
         roiManager("reset") ;
	     setTool("polygon");
		 tit = getTitle();
		 Original_image =getImageID();
		 for (j =0; j<Areas.length; j++) {
		 	waitForUser("Draw the"+Areas[j]+" contour than click OK");
		 	roiManager("Add");
		 	roiManager("Select", j);
		 	roiManager("rename",Areas[j]);
		 }
	  roiManager("save", dir+ File.separator +tit+"_ROIs.zip") ;
	  close(); 	
		 }
	 }
