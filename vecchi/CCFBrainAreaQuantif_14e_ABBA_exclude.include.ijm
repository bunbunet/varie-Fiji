@ String(value="FLUORESCENCE IMAGES", visibility="MESSAGE") hints
#@ File (label="Fluorescence Images directory", style = "Directory") Dir
#@ String(label="Channels names, separated by comma (,)") Channels
#@ String(value="SEGMENTATION MASKS", visibility="MESSAGE") hints2
#@ File (label="segmentation masks directory", style = "Directory") Mask_Dir
#@ String(label="Prefix of segmentation images (e.g. WFA-) leave blank if absent") ChRefTag
#@ String(label="Tag of segmented mask (after the base name e.g. Simple Segmentation)") SegTag
#@ String(label="Segmentation name (to name the results)") AnalysisTag
#@ Integer(label="Label gray level: ", value="") lbl
#@ String(value="ATLAS ROIs", visibility="MESSAGE") hints3
#@ File (label="Atlas Directory", style = "Directory") Atlas_Dir
#@ Boolean(label="Exclude Areas indicated in areas_to_exclude.csv?  (in the ROIs directory)") Exclude
#@ Boolean(label="Include only Areas indicated in areas_to_include.csv? (in the ROIs directory)") Include
#@ String(value="OUTPUTS", visibility="MESSAGE") hints4
#@ File (label="Directory to Save Results", style = "Directory") Save_Dir
#@ String(value="Indicate channel names separated by comma (e.g. PV,WFA)", visibility="MESSAGE") hints5
#@ String(label="Save Segmentation Cropped fluorescence images for channels: ") Save_SegCrop


/* This Macro analyze the area and staining intensity in a binary mask. exclude
 *  All files referring to the same section must share a base name, e.g. "Basename=GroupName.specimenID_otherDetails_zX"
 *  It expect as inputs:
 *  	1) ROI set for each section as a .zip file including all the files.
 *  							This file shlould be named as Basename.zip
 *  	2) 8-bit (single channels) Fluorescence images named as "channel Name-Basename.tif".
 *  							Up to 4 channels can be used (more can be added modifying the macro), 
 *  							the names of the channels must be specified, separated by comma in the macro options (e.g. WFA,PV,DAPI)
 *  	3) 8-bit binary mask with the segmentation
 *  	
The macro iterates in the folder containing the ROI sets and than search the associated files in the folders specified by the user.
*/
//show ops variables names to the autocmpletion function
Dir=Dir
Channels=Channels
Mask_Dir=Mask_Dir
Atlas_Dir=Atlas_Dir
ChRefTag=ChRefTag
AnalysisTag=AnalysisTag

// WFA meglio in cartella per conto suo, così apriamo prima quella e facciamo tutto di conseguenza
// in alternativa si potrebbe aprire prima l'atlante e poi cercare i vari canali, o aprire il multitiff e scegliere i canali. 
// Questo forse velocizzerebbe anche l'analisi delle fluo su tutti, tanto bisognerà tenerli aperti in contemporanea.

//Tolto il .tif dallo zeta level e aggiunta colonna per condition e specimen name.


//close all images and release memory from RAM
if(nImages>0){
	waitForUser("Warning! All Images, ROIs and Results windows will be closed!");
}
run("Close All");
call("java.lang.System.gc");
run("Clear Results");
roiManager("reset");

//create csv Directories
CSV_Dir= Save_Dir +File.separator+"csv";
Seg_Dir= Save_Dir +File.separator+"PNN_crop";
File.makeDirectory(CSV_Dir);
File.makeDirectory(Seg_Dir);


setBatchMode(true);

//-----------------------------EXTRACT SECTION DETAILS IMAGES AND ROI NAMES----------------------

fileNotFound=newArray();

run("3D Manager");
run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");
Ext.Manager3D_SelectAll();
Ext.Manager3D_Delete();
roiManager("reset");
run("Clear Results");

// LOOP TROUGH ALL EXISTING SECTIONS
// The logic is to loop trough atlas images, check the existence of corresponding files and analyze them

// Loop through the Atlas ROIs produced by the Macro that analyzed segmentation
list=getFileList(Atlas_Dir);

//-----------------------Loop over ROIs files and check the existence of associated Predictions and Identities---

for (k = 0; k < list.length; k++) {
	print(Atlas_Dir+File.separator + list[k]);
	if (endsWith(list[k], ".zip")) { 
							
		// get Zvalue and specimen name
		// Names are expectd to be like: Specimen Name_ImageType_zLevel_other stuff
		// e.g. Fmr-Ko2_quickNII_s072.png
		roiManager("Open", Atlas_Dir+File.separator+list[k]);
		titWext= list[k];
		BaseName=replace(titWext,".tif.zip","");// the ABBA zip file include also the .tif extension of the original image
		splittedName=split(BaseName, "_");
		Specimen=splittedName[0];
		print("Specimen: "+Specimen);
		zString = getSubstring(titWext, "_z", "_");
		zValue = NaN; //or whatever to tell you that you could not read the value
			 if(zString!="") {
	   			zValue=parseInt(zString); //parseFloat if not always an integer value
			 }
			 		 		 	
		print("X_X_X_X_X_X_X_X_X_X_X_X_X_X_ Processing: " + BaseName + " X_X_X_X_X_X_X_X_X_X_X_X_X_X_X"); 


//------------ CHECK THE EXISTENCE OF FLUORESCENCE IMAGES AND SEGMENTATION MASKS FILES----------------------
	
	// FLUORESCENCE IMAGES
		// Open all the fluorescence images with the prefix indicated in the options (expect channels to be written at the beginning of the file name, separated by a "-"
		// according to the scheme: chName-Base name.tif
	
	channel_names=split(Channels, ",");
	FluoImages=newArray();
	
	for (i=0; i<channel_names.length;i++) {
		Img= channel_names[i]+"-" + BaseName + ".tif";
		Img_path=Dir + File.separator + Img;
		if(File.exists(Img_path)) {
			open(Img_path);
			tit=getImageID();
			FluoImages=Array.concat(FluoImages,tit);
			getDimensions(Original_width, Original_height, Original_channels, Original_slices, Original_frames);// This may be deleted
		} else {
			fileNotFound=Array.concat(Img,fileNotFound); // Files not found are added to not found array
		}
	}
	print(FluoImages.length + " Channels Found");

	// SEGMENTION IMAGES
		// Two types of segmentated masks (from Ilastik) are expected: 
		// Whole area, Individual Objects (divided into identities encoding the indivudual objects and predictions encoding the object types)
	// Staining Area
	Mask_path = Mask_Dir + File.separator + ChRefTag + BaseName + "_" + SegTag + ".tiff"; // Chase the corresponding segmentation Image
	if(File.exists(Mask_path)) {
		print(SegTag+" found");
	} else {
			fileNotFound=Array.concat(Mask_path,fileNotFound); // Files not found are listed in an array
	}

//-----------------------CHEK IF ALL NECESSARY FILES ARE THERE BEFORE STARTING -----------------------------

	if(File.exists(Mask_path) && FluoImages.length>0){

//-----------------------------------------------------------------------------------------------------------
//----------------------------------	ANALYZE THE IMAGE   -------------------------------------------------
//-----------------------------------------------------------------------------------------------------------
	
//--------------Initialize local arrays to store the results of each section---------------------------------
		
		var Region_indexes=newArray(); // Atlas Region index (16-bit grayscale value)
		var Region_areas=newArray();   // Area in pixels of the Atlas Regions
		var Seg_areas=newArray();      // Area of the segmentated mask by Region
		var Ch1_MGVs=newArray();       // Mean Gray Value of the whole Ch1 stain by Region
		var Ch2_MGVs=newArray();	   // Mean Gray Value of the whole Ch2 stain by Region
		var Ch3_MGVs=newArray();	   // Mean Gray Value of the whole Ch3 stain by Region
		var Ch4_MGVs=newArray();	   // Mean Gray Value of the whole Ch4 stain by Region
		var Seg_Ch1MGVs=newArray();    // Mean Gray Value of the Ch1 stain inside the mask by Region
		var Seg_Ch2MGVs=newArray();    // Mean Gray Value of the Ch2 stain inside the mask by Region
		var Seg_Ch3MGVs=newArray();    // Mean Gray Value of the Ch3 stain inside the mask by Region
		var Seg_Ch4MGVs=newArray();    // Mean Gray Value of the Ch3 stain inside the mask by Region
		
// Note that it could be nice to dynamically create variables only for existing channels, but I'm not sure if and how can be don in macro language
// However, Through conditional statements the macro can adapt to images having up to four channels. 

//-------------------------------	ANALYZE MGV --------------------------------------------------------
 		
		run("Set Measurements...", "area mean reDirect=None decimal=4");

// If the option was selected, Delete from ROI manager the areas listed in the areas_to_exclude.txt file that is expected in the ROIs directory
// the ROI names are expected on a single lines separated by commas
if (Exclude) {
	areas_to_exclude=split(File.openAsString(Atlas_Dir+File.separator+"areas_to_exclude.txt"), ",");
	 for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		Region_index=Roi.getName;
		if (contains(areas_to_exclude,Region_index)) {
			roiManager("delete");
		}
	}
} 

// If the option was selected, Delete from ROI manager the areas NOT listed in the areas_to_include.txt file that is expected in the ROIs directory
// the ROI names are expected on a single lines separated by commas
if (Include) {
	areas_to_include=split(File.openAsString(Atlas_Dir+File.separator+"areas_to_include.txt"), ",");
	 for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		Region_index=Roi.getName;
		if (!contains(areas_to_include,Region_index)) {
			roiManager("delete");
		}
	}
} 


 	number_of_Areas=roiManager("count");
 	print("Number of Rois: ", number_of_Areas);
 			
 	//Analyze Atlas ROIs Area and total MGV 
 		print("Collect Values");
 		for (v=0; v<number_of_Areas; v++) {
 			run("Clear Results");
 			selectImage(FluoImages[0]);
 			roiManager("Select", v);
 			Region_index=Roi.getName;
	 		roiManager("Measure");
	 		
	 		//Get the measures and then fill multiple parallel arrays 
	 		//with the results of each area (to tabulate on the same row)
	 		Region_area=getResult("Area", 0);
	 		Region_indexes=Array.concat(Region_index,Region_indexes);
			Region_areas=Array.concat(Region_area,Region_areas);
			//Measure MGV of channel 1
	 		Ch1_MGV=getResult("Mean", 0);
	 		Ch1_MGVs=Array.concat(Ch1_MGV,Ch1_MGVs);
	 		
 		}
	 		// Analyze Additional channels if present
	 	if (FluoImages.length>1) {
	 	selectImage(FluoImages[1]);			
			for (v=0; v<number_of_Areas; v++) {
				run("Clear Results");
	 			roiManager("Select", v);
	 			roiManager("Measure");
	 			Ch2_MGV=getResult("Mean", 0);
		 		Ch2_MGVs=Array.concat(Ch2_MGV,Ch2_MGVs);
	 			}
	 		} 		
	 	if (FluoImages.length>2) {
	 	selectImage(FluoImages[2]);			
			for (v=0; v<number_of_Areas; v++) {
				run("Clear Results");
	 			roiManager("Select", v);
	 			roiManager("Measure");
	 			Ch3_MGV=getResult("Mean", 0);
	 			Ch3_MGVs=Array.concat(Ch3_MGV,Ch3_MGVs);
	 			}
	 		}	
	 	if (FluoImages.length>3) {
	 	selectImage(FluoImages[3]);			
			for (v=0; v<number_of_Areas; v++) {
				run("Clear Results");
	 			roiManager("Select", v);
	 			roiManager("Measure");
	 			Ch4_MGV=getResult("Mean", 0);
	 			Ch4_MGVs=Array.concat(Ch4_MGV,Ch4_MGVs);
	 			}
 			}
//-------------------------------  DELETE FLUORESCENCE OUTSIDE THE SEGMENTATION   ----------------------------------------------
		
		//Convert to an array the list of channels to save
		Save_SegCropArray=split(Save_SegCrop, ",");
		
		//Convert the Segmentation to Mask and invert it

		open(Mask_path);
		Mask=getImageID();
		setThreshold(lbl, lbl, "raw");
		run("Convert to Mask");
		run("Invert");
		run("Grays");
		//Loop trough all the images to delete signal outside the segmented area
		for (i = 0; i < FluoImages.length; i++) {
			imageCalculator("Subtract", FluoImages[i],Mask);
			//Save the Channels indicated by the user
			for (j = 0; j < Save_SegCropArray.length; j++) {
				if(channel_names[i]==Save_SegCropArray[j]){
					selectImage(FluoImages[i]);
					saveAs("Tiff", Seg_Dir + File.separator + channel_names[i] + "_" + BaseName + AnalysisTag + "_only.tif");	
				}
			  }
			}
			
// --------------------------Analyze the area and MGV of the segmention in each Atlas ROIs-------------------------------------

 				
		// Analyze MGV in channel 1	segmented area
		// ( as we already populated the Area and 
				
		for (v=0; v<number_of_Areas; v++) {
			selectImage(FluoImages[0]);	
			run("Clear Results");
 			roiManager("Select", v);
 			roiManager("Measure");	
			Seg_Ch1MGV=getResult("Mean", 0);
			Seg_Ch1MGVs=Array.concat(Seg_Ch1MGV,Seg_Ch1MGVs);	
 		}
 		// Analyze Additional channels if present
	 	if (FluoImages.length>1) {
	 		selectImage(FluoImages[1]);			
		for (v=0; v<number_of_Areas; v++) {
			run("Clear Results");
 			roiManager("Select", v);
 			roiManager("Measure");	
			Seg_Ch2MGV=getResult("Mean", 0);
			Seg_Ch2MGVs=Array.concat(Seg_Ch2MGV,Seg_Ch2MGVs);
	 		}
	 	} 
	 	if (FluoImages.length>2) {
	 		selectImage(FluoImages[2]);			
		for (v=0; v<number_of_Areas; v++) {
			run("Clear Results");
 			roiManager("Select", v);
 			roiManager("Measure");	
			Seg_Ch3MGV=getResult("Mean", 0);
			Seg_Ch3MGVs=Array.concat(Seg_Ch3MGV,Seg_Ch3MGVs);
	 		}
	 	} 
	 	if (FluoImages.length>3) {
	 		selectImage(FluoImages[3]);			
		for (v=0; v<number_of_Areas; v++) {
			run("Clear Results");
 			roiManager("Select", v);
 			roiManager("Measure");	
			Seg_Ch4MGV=getResult("Mean", 0);
			Seg_Ch4MGVs=Array.concat(Seg_Ch4MGV,Seg_Ch4MGVs);
	 		}
	 	} 
	 	
//-------------------------------	ANALYZE SEGMENTATION AREA --------------------------------------------------------
		// using the formula Area of the Mask= AreaRegion*(MGV of the white filled Segmentation Mask/255)
		
		run("Select None");
		run("Clear Results");
		selectImage(Mask);
		run("Invert");
		for (v=0; v<number_of_Areas; v++) {
 			roiManager("Select", v);
 			roiManager("Measure");
 			Region_area=getResult("Area", 0);
			Region_MGV=getResult("Mean", 0);
			Seg_area= Region_area*(Region_MGV/255);
			Seg_areas=Array.concat(Seg_area,Seg_areas);
			run("Select None");
			run("Clear Results");
 		}
		
//-------------------------------	SAVE RESULTS --------------------------------------------------------
		print("Writing Result Table");		
			//Save the Table of the individual Section
			for(i=0;i<Region_indexes.length;i++){
				setResult("Specimen", i, Specimen);
				setResult("Section.ID", i, zValue);
				setResult("Region.Index", i, Region_indexes[i]);
				setResult("Region_Area", i, Region_areas[i]);
				setResult(AnalysisTag + "_Area", i, Seg_areas[i]);
				AreaFraction=Seg_areas[i]/Region_areas[i];
				setResult(AnalysisTag + "_Area_Fraction",i,AreaFraction);
				setResult(channel_names[0] + "_MGV", i, Ch1_MGVs[i]);
				setResult(channel_names[0]+"_" + AnalysisTag+".MGV", i, Seg_Ch1MGVs[i]/AreaFraction); 
				//MGV of the segmented area were collected over the entire area, but keeping only the pixels inside the mask and and must thus be scaled by the Mask Area Fraction
				
				if(FluoImages.length>1){
				setResult(channel_names[1] + "_MGV", i, Ch2_MGVs[i]);
				setResult(channel_names[1]+"_" + AnalysisTag+"_MGV", i, Seg_Ch2MGVs[i]/AreaFraction);
				}
				if(FluoImages.length>2){
				setResult(channel_names[2] + "_MGV", i, Ch3_MGVs[i]);
				setResult(channel_names[2]+"_" + AnalysisTag+"_MGV", i, Seg_Ch3MGVs[i]/AreaFraction);
				}
				if(FluoImages.length>3){
				setResult(channel_names[3] + "_MGV", i, Ch4_MGVs[i]);
				setResult(channel_names[3]+"_" + AnalysisTag+"_MGV", i, Seg_Ch4MGVs[i]/AreaFraction);
				}
			}
					
			saveAs("Results", CSV_Dir+File.separator+BaseName+"_CCF_Quantif_"+AnalysisTag+".csv"); 
											
	}// END OF THE INDIVUDUAL SLICE PROCESSING BLOCK
			
		//close all images and release memory from RAM
			run("Close All");
			call("java.lang.System.gc");
			roiManager("reset");
			run("Clear Results");	

	}
}// END OF SLICES PROCESSING FOR LOOP

for(i=0;i<fileNotFound.length;i++){
	setResult("FileName", i, fileNotFound[i]);
}
saveAs("Results", CSV_Dir+File.separator+"CCF_Quantif_"+AnalysisTag+"_FileNotFound.csv"); 

print("D O N E !");

//---------------------------------------------------------F U N C T I O N S------------------------------------------------------------------------

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
				
// This function find a string 
// This function find a string 
function getSubstring(string, prefix, postfix) {
   start=indexOf(string, prefix)+lengthOf(prefix);
   end=start+indexOf(substring(string, start), postfix);
   if(start>=0&&end>=0)
     return substring(string, start, end);
   else
     return "";
}

function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}