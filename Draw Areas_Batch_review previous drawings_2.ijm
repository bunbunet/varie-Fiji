//@ File (label = "TIF directory", style = "directory") dir
//@ File (label = "ROIs directory", style = "directory") ROI_dir
//@ String(label="ROIs tag at the end of images name)", value="MAX_ROIs.zip") tag
//@ Boolean(label="Do a MAX projection to draw?") max

// This Macro open previously drown areas allow to draw and save ROIs for multiple areas in all images in a folder 
// ROIs are expected with the same name of the image, or with the addition of a tag at the end.
// To undo all the chages, delete all the ROIs and as for NOT deleting the files
// It is recommended to keep a copy of the original ROIs before undergoing any change with this macro

run("Brightness/Contrast...");

waitForUser("SAVE ALL UNSAVED CHANGES TO ROIs") ;

list = getFileList(dir);
for (i = 0; i < list.length; i++) {
	 if (endsWith(list[i], ".tif")){
	 	 roiManager("reset") ;
	 	 print(i + ": " + dir+list[i]);
         open(dir+File.separator+list[i]);
         Original_image =getImageID();
         titWext= File.nameWithoutExtension;

 		if(max==true){
         	run("Z Project...", "projection=[Max Intensity]");
         	selectImage(Original_image);
         	close(); 
         }
         if(File.exists(ROI_dir+ File.separator +titWext+"_"+tag+".zip")){
		 	roiManager("Open", ROI_dir+ File.separator +titWext+"_"+tag+".zip");        
			 roiManager("Show All");
			 waitForUser("Adjust ROIs than click ok to Save them?"); 
			 if(roiManager("count")>0){
			  	roiManager("save", ROI_dir+ File.separator +titWext+"_"+tag+".zip") ;
		     } else {
			  	
			  	if(getBoolean("ROI manager empty, do you want to delete the ROIs file?")){
			  		File.delete(ROI_dir+ File.separator +titWext+"_"+tag+".zip");
			  	} else{
			  		waitForUser("ROI file will be left as it was before")
			  	}
			  }
         } else{
         	print("ROIs file not found");
         }
		 close(); 	
		 }
	 }
