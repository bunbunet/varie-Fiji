//@ File (label="Select Fluorescence Images", style = "Directory") Dir
//@ File (label="Select Atlas Directory", style = "Directory") Atlas_Dir


//create Directories
Atlas_OutDir= Dir +File.separator+"Atlas_final";
File.makeDirectory(Atlas_OutDir);

setBatchMode(true);

//-----------------------------DEFINE VARIABLES, IMAGES AND ROI NAMES----------------------

fileNotFound=newArray();

list = getFileList(Dir);
run("3D Manager");
run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");
Ext.Manager3D_SelectAll();
Ext.Manager3D_Delete();
roiManager("reset");
run("Clear Results");


for (k = 0; k < list.length; k++) {
	print(Dir+File.separator + list[k]);
	if (endsWith(list[k], ".png")) { 				
	
	// get names, this will be used as a base to find ROIs, Identities and Predictions		
	open(Dir+File.separator+list[k]);
	WFA=getImageID();
	getDimensions(Original_width, Original_height, Original_channels, Original_slices, Original_frames);
	tit = getTitle();
	titWext= File.nameWithoutExtension;
	print("Processing: " + tit);
	
	// Define the path of Predictions and Identities and check thier existence
	//Ident_path = Mask_Dir+File.separator+titWext+"_Object Identities_.tiff"; // The Object Predictions are optional
	Atlas_path = Atlas_Dir+File.separator+titWext+"_nl.tif";

	print(Atlas_path);
	if(File.exists(Atlas_path)) {
		print("found");
	}
	
	if(File.exists(Atlas_path)) {
		
		roiManager("reset");

		//Convert Atlas labels into ROIs
		open(Atlas_path);
		Atlas_Img=getImageID();
		getDimensions(Atlas_width, Atlas_height, Atlas_channels, Atlas_slices, Atlas_frames);
		scale_factorX=Original_width/Atlas_width;
		scale_factorY=Original_height/Atlas_height;
		print("Scale Factor: "+ scale_factorX+ " "+ scale_factorY);
		// Increasing the size of the Atlas image before importing the labels in 3D manager takes ages
		// I decided to move to a more simple and classic IJ ROIs approach
		// run("Size...", "width="+Original_width+" height="+Original_height+" depth=1 interpolation=None");
		// Ext.Manager3D_AddImage();
		// A BIOP macro exists to add label image to ROI manager, the problem is that it reset the ROI manager and Soomt the traces!!!
		// run("Vectorize Label Image", "putinroimanager=true");
		// check also https://labelstorois.github.io/
		// I Did not try to Increase the size of the atlas image before running vectorize label image

		//In the end used the 3D manager and transfer 3Drois to Roi manager by filling and creating ROIs that will be subsequently scaled
		// for small ROIs it works smoothely
		print("Added Areas");
		run("3D Manager");
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nb);
		//print("Regions identified:" + nb);
		for (i = 0; i < nb; i++) {
			Ext.Manager3D_Select(i);
			newImage("Untitled", "8-bit black", Atlas_width, Atlas_height, 1);
			Ext.Manager3D_FillStack(255, 255, 255);
			run("Convert to Mask");
			run("Create Selection");
			roiManager("add");
			//run("Close");
			//close("Untitled");
			}
								
		//Scale ROIs and Name them according to MGV value
		selectImage(Atlas_Img);
		count=roiManager("count");
		print("Number of ROIs:" + count);
		for (v=1; v<count; v++) {
			selectImage(Atlas_Img);
			roiManager("Select", v);
			run("Set Measurements...", "mean display reDirect=None decimal=4");
			roiManager("Measure");
			MGV=getResult("Mean", 0);
			roiManager("Select", v);
			roiManager("rename", MGV);
			selectImage(WFA);
			roiManager("Select", v);
			run("Scale... ", "x="+scale_factorX+" y="+scale_factorY);
			Roi.setName(MGV);
		    roiManager("Add");
		    run("Clear Results");
		}
		
		// Delete non scaled ROIs
		for (i = count - 1; i >= 1; i--) {
		 	roiManager("Select", i);
		 	roiManager("Delete");
 			}
 			c=roiManager("count");
		// Save ROIs
		roiManager("save", Dir + File.separator + tit + "Atlas_ROIs.zip");
		
		// Save a 10um/px Atlas Image
		selectImage(Atlas_Img);
		run("Select None");
		run("Scale...", "x="+scale_factorX + " y="+scale_factorY + " interpolation=None create");
		saveAs("Tiff", Atlas_OutDir + File.separator + tit+"_Atlas.tif");
	
			run("Close All");
			call("java.lang.System.gc");
 		}
 		else {
 			fileNotFound=Array.concat(tit,fileNotFound);
 		}

	}
}
print("Files not found:");
Array.print(fileNotFound);
			
			run("Close All");
			call("java.lang.System.gc");

// function to return unique elements 
// could be used to iterate and sum all the values at the end of the analysis
function ArrayUnique(array) {
	array 	= Array.sort(array);
	array 	= Array.concat(array, 999999);
	uniqueA = newArray();
	i = 0;	
   	while (i<(array.length)-1) {
		if (array[i] == array[(i)+1]) {
			//print("found: "+array[i]);			
		} else {
			uniqueA = Array.concat(uniqueA, array[i]);
		}
   		i++;
   	}
	return uniqueA;
}
