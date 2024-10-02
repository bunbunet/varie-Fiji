//@ File (label = "Input directory", style = "directory") Input
//@ File (label = "Output directory", style = "directory") dir

// Set the name of the Channels (in order from 1 to n)
ch=newArray("DAPI","SOX9","KI67","GFAP");

// This macro iterate in all images of a folder, that are expected as multichannel,
// save crops, with their channels splitted and renamed, of an open image as defined by the ROIs in the ROI manager.
// For each ROI the saved image will be named as follow:
//	channel-Image Name_ROI name.tif
// the name of the channels che be specified in the Array ch

list = getFileList(Input);
for (m = 0; m < list.length; m++) {
	run("Close All");
	roiManager("reset");
	open(dir+File.separator+list[m]);
	img=getTitle();
	getDimensions(width, height, channels, slices, frames);
	if (channels==1) {
		print("this image has only 1 channel, it will be saved as X-");
	}
	waitForUser("Click OK to save and open next image");
	roiManager("save", dir+File.separator+img+".zip");
	for (i=0; i<roiManager("count"); ++i) {
		selectImage(img);
		roiManager("Select", i);
		name=getInfo("roi.name");
		run("Duplicate...", "title="+name+" duplicate");
		if (channels==1) {
			saveAs("Tif", dir+File.separator+"X"+"-"+img+"_"+name+".tif");
	        close();
		} else {
		run("Split Channels");
		for (c = 0; c < channels; c++) {
			selectImage("C"+c+1+"-"+name);
	        saveAs("Tif", dir+File.separator+ch[c]+"-"+img+"_"+name+".tif");
	        close();
	    	}
	    }    
     } 
} 
