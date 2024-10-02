//@ File (label = "Iutput directory", style = "directory") dir
//@ File (label = "Output directory", style = "directory") dirOut
//@String(label = "rotation", choices={"0", "90-left", "90-Right", "180"}, style="radioButtonHorizontal") _ROTATION_

//@ Boolean(label="Register images?") register
//@ Float (label = "Display Range MIN", value = "10") Display_MIN
//@ Float (label = "Display Range MAX", value = "220") Display_MAX
//@ int (label = "Montage Number of columns", value = "4") columns
//@ int (label = "Montage Unsharp Radius", value = "30") radius
//@ Float (label = "Montage Unsharp mask*10", value = "7") mask

// This Macro process png files of block face cryostat pictures.
// Picture names are expected as Specimen_zX_Y_series_K. Where z is the progressive number of the images and K is the series number
// The macro calibrate, rotate and crop the pictures. It also produce a montage image for each series

dirReg=dirOut+File.separator+"reg"+File.separator;
MontDir=dirOut+File.separator+"Montage"+File.separator;
File.makeDirectory(MontDir);
File.makeDirectory(dirReg);

// Iterate over the images to get a name for the import image sequence command
// and the number of series
series_List=newArray; // array storing the series number of all images, max= number of series
PngHead=newArray();

function rotate() {
	if (_ROTATION_== "90-Right"){
		run("Rotate 90 Degrees Right");
	}
	if (_ROTATION_== "90-Left"){
		run("Rotate 90 Degrees Left");
	}
	if (_ROTATION_== "180"){
		run("Rotate... ", "angle=180 grid=1 interpolation=None");
	}
	 
}


list = getFileList(dir);
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], ".png")){
		name=split(list[i], "_");
		ser=split(name[4],"."); //extract the series number
		series_List=Array.concat(series_List,ser[0]);
		PngHead=Array.concat(PngHead,list[i]);
	}
}

if (register==true){
run("Register Virtual Stack Slices", "source=["+dir+"] output=["+dirReg+"] feature=Rigid registration=[Rigid                -- translate + rotate                  ] shrinkage");	
}

if(register==false){
	run("Image Sequence...","open=["+dir+File.separator+PngHead[1]+"] sort use");
}

run("Clear Results");
roiManager("reset");
setTool("line");
waitForUser("Draw a a 5mm line");
run("Measure");
length= getResult("Length", 0);
PixelSize=5000/length;
print(PixelSize);
setTool("rectangle");
waitForUser("Draw a ROI around the specimen");
roiManager("Add");
roiManager("Save", dirOut+File.separator+"Pi_porcessed_ROI.roi");
close();

setBatchMode(true);
if (register==true){
	list = getFileList(dirReg);

for (i=0; i<list.length; i++) { 	
     	if (endsWith(list[i], ".tif")) {
     	open(dirReg+File.separator+list[i]);
		imgName=getTitle();
		Name=replace(imgName,".png","");    
		run("Properties...", "channels=1 slices=1 frames=1 unit=micron pixel_width="+PixelSize+" pixel_height="+PixelSize+" voxel_depth=50");
			//Crop
		roiManager("select", 0);
		run("Crop");
			//Rotate
		rotate();
			//Preprocessing
		run("Unsharp Mask...", "radius="+Unsharp_radius+" mask="+Unsharp_mask);
		setMinAndMax(Display_MIN, Display_MAX);
		saveAs("Tiff", dirOut+File.separator+Name);
     	}  
	}
}
	
if (register==false){
list = getFileList(dir);

for (i=0; i<list.length; i++) { 	
     	if (endsWith(list[i], ".png")) {
     	open(dir+File.separator+list[i]);
		imgName=getTitle();
		Name=replace(imgName,".png","");    
		run("Properties...", "channels=1 slices=1 frames=1 unit=micron pixel_width="+PixelSize+" pixel_height="+PixelSize+" voxel_depth=50");
			//Crop
		roiManager("select", 0);
		run("Crop");
			//Rotate
		rotate();
			//Preprocessing
		//run("Unsharp Mask...", "radius="+Unsharp_radius+" mask="+Unsharp_mask);
		setMinAndMax(Display_MIN, Display_MAX);
		saveAs("Tiff", dirOut+File.separator+Name);
     	}  
	}
}	

// Produce a montage images
Array.getStatistics(series_List, min, max, mean, stdDev);
series=max; // get the number of seires
mask=mask/10;
title=split(PngHead[1], "_");
title=title[0];

setBatchMode(true); 
section_series = round(lengthOf(list)/series);
rows= round(section_series/columns)+1;
setForegroundColor(0, 0, 0);
setBackgroundColor(0, 0, 0);

for (i = 1; i < series+1; i++) {
	run("Image Sequence...","open=["+dirOut+File.separator+PngHead[1]+"] sort file=series_"+i+".tif");
	rotate();
	run("Make Montage...", "columns="+columns+" rows="+rows+" scale=1 label font=48 use");
	run("Unsharp Mask...", "radius="+radius+" mask="+mask+"");
	run("Brightness/Contrast...");
	saveAs("tiff", MontDir+title+"series_"+i);
	saveAs("jpeg", MontDir+title+"series_"+i);
	run("Enhance Contrast", "saturated=0.35");
	//setMinAndMax(96, 218);
}
