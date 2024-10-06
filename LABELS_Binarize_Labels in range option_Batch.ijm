#@ File (label="Select mask directory", style = "directory") input
#@ File (label="Select output directory", style = "directory") output
#@ String (label="filter by suffix", value="Object Predictions.tiff") suffix
#@ String (label="Prefix to add", value="mk") tag
#@ String (label="Labels to Exclude, separated by commas", value="3,4") labels

run("3D Manager");
run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");

setBatchMode(true);
InputList = getFileList(input);
print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
 	if (endsWith(InputList[l], suffix)) {
 		open(input+File.separator+InputList[l]);
 		Img=getTitle();
 	
 	//Erase the unwanted labels
		run("Select Label(s)", "label(s)="+labels);
		// clear the 3D manager
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Delete();
		// Add Labels
		Ext.Manager3D_AddImage();
		// erase unwanted cells from the Identities images of all other labels (k is different from i)
		Ext.Manager3D_Count(Nb_of_objects);
		selectWindow(Img);
		for (k = 0; k < Nb_of_objects; k++) {
				Ext.Manager3D_Select(k);
				Ext.Manager3D_FillStack(0, 0, 0);
			}

	//Binarize the image
		getStatistics(area, mean, min, max, std, histogram);
		setThreshold(1, max);
		run("Convert to Mask", "method=Default background=Dark black");
	// Save the result	
		saveAs("tiff", output+File.separator+tag+Img);
	}
}