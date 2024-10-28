#@ File (label="images directory", style = "directory") input
#@ File (label="cropped images output directory", style = "directory") output
#@ File (label="ROIs directory", style = "directory") ROIs_dir
#@ String (label="Crop tag to add to cropped images") CROPtag
#@ float (label="scale factor") scaleFactor

// The ROI name must be the same of the image withtheaddition of a ROI tag at the end, separated by an "_"
//Other "_" can exist in the same as long as the ROItag is in the last position.

// file format of the fluorescence images 
image_format=".tif";

setBatchMode(true);

InputList = getFileList(input);
print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
	if (endsWith(InputList[l], ".roi")) {
		// Get the Basename
		ROItag=split(InputList[l],"_");
		splitTag=split(ROItag,"_");
		BaseName=splitTag[0];
		for (i = 1; i < splitTag.length-1; i++) {
			BaseName=BaseName+"_"+splitTag[i];
		}

		ROItag=splitTag[splitTag.length-1];
		ROItag=replace(ROItag,".roi","");
		
		BaseName=replace(InputList[l],"_"+ROItag+".roi"); 
		Img_path=input+File.separator+BaseName;
		print("X___X___X___X___X___X___X___X___X___Analyzng: " + BaseName+"X___X___X___X___X___X___X___X___X___");
		if(File.exists(ROI_path)){
				print("			Image file found!");
				open(Img_path);
				roiManager("reset");
				roiManager("Open", ROIs_dir+File.separator+InputList[l]);
				roiManager("select", 0);
				run("Scale... ", "x=4 y=4");
				run("Crop");
				saveAs("TIF", output+File.separator+BaseName+"_"+ROItag+".tif");
		} else{
			print("			ROIs file not found, the entire image area will be analyzed");
		} 
}

print("Done!");