#@ File (label="Select mask directory", style = "directory") input
#@ File (label="Select output directory", style = "directory") output
#@ String (label="filter by suffix") suffix
#@ Integer (label="Lower label") Lower
#@ Integer (label="Upper label") Upper

setBatchMode(true);
InputList = getFileList(input);
print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
 	if (endsWith(InputList[l], suffix)) {
 		open(input+File.separator+InputList[l]);
 		Name=getTitle();
		//Binarize the image
		setThreshold(Lower, Upper);
		run("Convert to Mask", "method=Default background=Dark black");	
		saveAs("tiff", output+File.separator+Name);
	}
}