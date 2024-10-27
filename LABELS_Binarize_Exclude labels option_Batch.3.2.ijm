#@ File (label="Select mask directory", style = "directory") input
#@ File (label="Select output directory", style = "directory") output
#@ String (label="filter by string (separated by _ in the original name)", value="Object Predictions.tiff") filter
#@ Boolean (label= "remove filter strning from the output file name?") remove
#@ String (label="Prefix to add", value="mk") tag
#@ String (label="Labels to Exclude, separated by commas", value="3,4") labels

/*
 * This Macro gets a list of label images in which one or more gray levels identify specific objects types, 
 * as those exported by Ilastik as Object predictions. All labels but those indicated by the user will be assigned the value of 255.
 */

labels=split(labels,",");

run("3D Manager");
run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");

setBatchMode(true);
InputList = getFileList(input);
print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
 	Name_split=split(InputList[l], "_");
 	if(contains(Name_split,filter)){
 		open(input+File.separator+InputList[l]);
 		Img=getTitle();
 		getDimensions(width, height, channels, slices, frames);
 	
 	//Erase the unwanted labels
 	 for (i = 0; i <labels.length; i++) {
		setThreshold(labels[i], labels[i], "raw"); //must be a string
		for (s = 0; s < slices; s++) {
			setSlice(s+1);
			run("Create Selection");
			setForegroundColor(0, 0, 0);
			if(selectionType()!=-1){ 
				run("Fill", "slice");
				}
			run("Select None");
			}
		}

	//Binarize the image
		getStatistics(area, mean, min, max, std, histogram);
		setThreshold(1, max);
		run("Convert to Mask", "method=Default background=Dark black");
	// Save the result	
		if(remove){
			Img=replace(Img,"_"+filter,"");
		}
		
		saveAs("tiff", output+File.separator+tag+Img);
	}
}
print("Done!");

function contains(array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}