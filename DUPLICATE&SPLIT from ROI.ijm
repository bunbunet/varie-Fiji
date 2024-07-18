// This macro save crops, with their channels splitted and renamed, of an open image as defined by the ROIs in the ROI manager.
// For each ROI the saved image will be named as follow:
//	channel-Image Name_ROI name.tif
// the name of the channels che be specified in the Array ch

// Set the name of the Channels (in order from 1 to n)
ch=newArray("DAPI","GLUT4","WFA","PV");
dir=getDirectory("Choose a Directory");
img=getTitle();
getDimensions(width, height, channels, slices, frames);
roiManager("save", dir+File.separator+img+".zip");
for (i=0; i<roiManager("count"); ++i) {
	selectImage(img);
	roiManager("Select", i);
	name=getInfo("roi.name");
	run("Duplicate...", "title="+name+" duplicate");
	run("Split Channels");
	for (c = 0; c < channels; c++) {
		selectImage("C"+c+1+"-"+name);
        saveAs("Tif", dir+File.separator+ch[c]+"-"+img+"_"+name+".tif");
        close();
    	}
   }           
