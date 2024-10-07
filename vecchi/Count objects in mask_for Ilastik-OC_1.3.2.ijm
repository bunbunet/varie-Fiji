#@ File (label="Select Predictions and Identities directory", style = "directory") Mask_dir 
#@ File (label="Select Predictions and Identities directory", style = "directory") ROI_dir 
#@ String(label="Tag of result table") ResTag
#@ String(label="Gray value of label to analyze") label_value


// to implement in case of multiple labels
// convert lists to arrays (must be separated by ",")
//labels_values=split(labels_values,",");
//labels_names=split(labels_names,",");


setBatchMode(true);
list=getFileList(Dir);

function ProcessMask() { 
// Option 1 Close filter
//	run("Options...", "iterations=4 count=3 black do=Close");

//Option 2 Gaussian Blur
/*
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Gaussian Blur...", "sigma=5");
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
*/
}

Images=newArray();
ROI_names=newArray();
Objects=newArray();

for (k = 0; k < list.length; k++) {
	print(Dir+File.separator + list[k]);
	if (endsWith(list[k], ".zip")) { 					
	// get names, this will be used as a base to find ROIs, Identities and Predictions		
	open(Dir+File.separator+list[k]);
	WFA=getImageID();
	getDimensions(Original_width, Original_height, Original_channels, Original_slices, Original_frames);
	tit = getTitle();
	titWext= File.nameWithoutExtension;
	print("Processing: " + tit);

	Mask_path = Mask_dir + File.separator + titWext + "_Object Predictions.tiff";
	if(File.exists(Mask_path)){
		print("Mask file found");
	}
	Ident_path = Mask_dir+File.separator+ titWext+"_Object Identities.tiff";
	if(File.exists(Mask_path)){
		print("Identities file found");
	}
	ROI_path=ROI_dir + File.separator + titWext+".zip";
	if(File.exists(ROI_path)){
		print("ROI file found");
	}
	run("3D Manager");
	// set measurements options, all objects are counted, including those touching the borders (exclude_objects_on_edges_xy is not included)
	run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) bounding_box drawing=Contour");
		
	if(File.exists(Mask_path) && File.exists(ROI_path) && File.exists(Ident_path)) {

		// Open Identities and Predictions
		open(Mask_path);
		Predictions=getImageID();
		open(Ident_path);
		Identities=getImageID();
		selectImage(Predictions);
		
		// Erase cells assigned to un-selected labels from the Object Identities Imgege.
		setThreshold(label_value, label_value);// Select the label 
		run("Create Selection");
		run("Make Inverse");
		roiManager("reset");
		roiManager("Add");
		selectImage(Identities);
		roiManager("Select", 0);
		setBackgroundColor(0, 0, 0);
		roiManager("Fill");
		roiManager("reset");
		// Add Identities to the 3D manager
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Save(Dir+ File.separator + tit+"_3Droi_"+ResTag+"_ALL.zip");
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_SelectAll();
		// Convert 3D ROIs to a single ROI and save it
		newImage("Temp", "8-bit black", Original_width, Original_height, 1);
		Ext.Manager3D_FillStack(255, 255, 255);
		run("Create Selection");
		roiManager("Add");
		roiManager("select", 0);
		roiManager("save", Dir+ File.separator + tit + "_roi_"+ResTag+"_ALL.roi");
		roiManager("reset");
		close("Temp");
		// Open the image associated ROIs
		roiManager("Open", ROI_path);
		count=roiManager("count");
		for (v=0; v<count; v++) {
			selectImage(Identities);
			roiManager("Select", v);
			ROI_name=Roi.getName;
			//import nuclei in 3D manager
			Ext.Manager3D_SelectAll();
			Ext.Manager3D_Delete();
			Ext.Manager3D_AddImage();
			Ext.Manager3D_Count(Nb_of_objects);
			Number_of_objects=Nb_of_objects;
			print(Number_of_objects);
			//Ext.Manager3D_Save(Dir+ File.separator + tit+"_3Droi_"+ResTag+"_"+i+".zip");
			Images=Array.concat(Images,titWext);
			Objects=Array.concat(Objects,Number_of_objects);
			ROI_names=Array.concat(ROI_names,ROI_name);
			run("Clear Results");
		}
	}
	run("Close All");
	}
}

for (i = 0; i < Images.length; i++) {
	setResult("Image", i, Images[i]);
	setResult("ROI", i, ROI_names[i]);
	setResult("Object n°", i, Objects[i]);
}

saveAs("Results", Dir+File.separator+ResTag+"_Counted_Objects.csv");