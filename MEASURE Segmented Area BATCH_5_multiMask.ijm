//@ String(value="INPUT-OUTPUT FILES", visibility="MESSAGE") hints
//@ File (label="Select Mask directory", style = "directory") input_Seg
//@ File (label="Select ROIs directory", style = "directory") input_ROI
//@ File (label="Fluorescence Images directory", style = "Directory") Dir
//@ String(label="Channels names, separated by comma (,)") Channels
//@ String(label="Save cropped masks for these channels: (separated by comma (,) leave blank to skip)") Save_SegCrop
//@ File (label="Select directory to save Results", style = "directory") Out_dir
//@ Boolean(label="Segmentations are already Binary (do not convert to Mask") BinaryMask
//@ String(value="TAGS AND FORMATS", visibility="MESSAGE") hints2
//@ String(label="Masks file format", value=".tif") SegExt
//@ String(label="Original image file format", value=".tiff") FluoExt
//@ String(label="Tag of segmentated mask", value="Simple Segmentation") SegTag
//@ String(label="Tag of ROIs file", value="_ROIs.zip") RoiTag
//@ String(label="label grey value", value="1") label

// This script automatically calculate the area and MGV of staining from single slice image in multiple ROIs
// It iterates through the masks, find the corresponding channles images and caluclate the MGV value for each. 
// 1) the image of the mask with segmentation
// 2) the channel images
// Specimen and section information will be extracted from file name:
// The file name is expected as follow: Staining Name-Experimental Group-Specimen ID _ section number _ everithing else.file format
// Avoid using "-" in the file names for anything else. Modify the script for different naming schemes
// Output files include a single csv file with all the results and individual csv for each section
// Users can also choose to save a ROI file of the segmention for each ROI for later use, 
// that will be saved in a new folder inside the segmentation folder

/* NAMING EXAMPLES 
Standard
 MASKS:
	GFAP-QA1W.3_z10_Axio10xMAX_Simple Segmentation.tiff
	NesGF-QA1W.3_z10_Axio10xMAX_Simple Segmentation.tiff
	Nestin-QA1W.3_z10_Axio10xMAX_Simple Segmentation.tiff
ROI:
	QA1W.3_z10_Axio10xMAX_ROIs.zip
FLUO IMAGES:
	GFAP-QA1W.3_z10_Axio10xMAX.tiff
	GFP-QA1W.3_z10_Axio10xMAX.tiff
	Nestin-QA1W.3_z10_Axio10xMAX.tiff
	SOX2-QA1W.3_z10_Axio10xMAX.tiff

(modification, to more quickly handle multiple sepcimens extracted from the same .czi):
 MASKS:
	GFAP-QA1W_z3a_Axio10xMAX_Simple Segmentation.tiff
	NesGF-QA1W_z3a_Axio10xMAX_Simple Segmentation.tiff
	Nestin-QA1W_z3a_Axio10xMAX_Simple Segmentation.tiff
ROI:
	QA1W_z3a_Axio10xMAX_ROIs.zip
FLUO IMAGES:
	GFAP-QA1W_z3a_Axio10xMAX.tiff
	GFP-QA1W_z3a_Axio10xMAX.tiff
	Nestin-QA1W_z3a_Axio10xMAX.tiff
	SOX2-QA1W_z3a_Axio10xMAX.tiff

*/

setBatchMode(true);

// create directory to save results and cropped images
CSV_Dir= Out_dir +File.separator+"csv";
Crop_Dir= Dir + File.separator + "Masks_Crops"
File.makeDirectory(Crop_Dir);
File.makeDirectory(CSV_Dir);

run("Set Measurements...", "area mean display redirect=None decimal=3");

// Define an Array to store the name of files fo which ROIs Predictions or Identities were not found
fileNotFound=newArray();

//-------------------------------------OPEN FILE AND CHECK FILE EXISTENCE---------------------------

// Iterate through Masks
list = getFileList(input_Seg);

for (k = 0; k < list.length; k++) {
	if (endsWith(list[k], SegExt)) { 
		//print(Dir+File.separator + list[k]);
		open(input_Seg+File.separator+list[k]);
		Mask=getImageID();
		
		// EXTRACT BASE NAME OF THE ORIGINAL IMAGE FROM THE MASK NAME
		// extract also slice and specimen details
		
		titMask = getTitle();
		titMaskWext = File.nameWithoutExtension();
		//First remove the antigen name
		SplitMaskType=split(titMaskWext, "-");
		MaskType=SplitMaskType[0]; // The prefix of the Mask indicating the segmentated objects (e.g. antigen)
		splittedName=split(SplitMaskType[1], "_");
		/* STANDARD NAMING SCHEME
		Specimen=splittedName[0];
		zLevel=splittedName[1];
		zLevel=replace(zLevel,"z", "");
		EG_Split=split(Specimen,".");
		Experimental_Group=EG_Split[0];
		*/
		// Modification
		zLevel=splittedName[1];
		zLevel=replace(zLevel,"z", "");
		Specimen=splittedName[0]+"." + zLevel;
		EG_Split=split(Specimen,".");
		Experimental_Group=EG_Split[0];
		
		// recover the name of the original image (without extension)
		BaseName=replace(SplitMaskType[1], SegTag, "");

		//Report file status
		print("X_X_X_X_X_X_X_X_X_X_X_X_ Processing : X_X_X_X_X_X_X_X_X_X_X_X_X_");
		print("                         "+BaseName+FluoExt);
		print("	Specimen:"+Specimen);
		print("	Experimental Group:"+Experimental_Group);
		print("	Z-level:",zLevel);
		//print("	Antigen:",Antigen);

		//Check the existence of properly named files for ROIs and Mak
		ROI_path =input_ROI + File.separator + BaseName + RoiTag;
		print("searching:"+ BaseName + RoiTag);
		if(File.exists(ROI_path)) {
			print("found");
		}

		// SEARCH AND OPEN FLUORESCENCE CHANNELS
		channel_names=split(Channels, ",");
		FluoImages=newArray();
		
		for (i=0; i<channel_names.length;i++) {
			Img= channel_names[i]+"-" + BaseName + FluoExt;
			Img_path=Dir + File.separator + Img;
			print("searching:"+ Img);
			if(File.exists(Img_path)) {		
				open(Img_path);
				FluoImage=getImageID();
				FluoImages=Array.concat(FluoImages,FluoImage);
				getDimensions(Original_width, Original_height, Original_channels, Original_slices, Original_frames);
			} else {
				fileNotFound=Array.concat(Img,fileNotFound); // Files not found are added to not found array
			}
		}
		print(FluoImages.length + " Channels Found");


//-----------------------CHEK IF ALL NECESSARY FILES ARE THERE BEFORE STARTING -----------------------------

	if(File.exists(ROI_path) && FluoImages.length>0){
			
		//--------------Initialize local arrays to store the results of each Mask---------------------------------
		
		var Region_indexes=newArray(); // ROI names
		var Region_areas=newArray();   // ROI Area in pixels
		var Seg_areas=newArray();      // Area of the segmentated mask by ROI
		
		var Ch1_MGVs=newArray();       // Mean Gray Value of the whole Ch1 stain by Region
		var Ch2_MGVs=newArray();	   // Mean Gray Value of the whole Ch2 stain by Region
		var Ch3_MGVs=newArray();	   // Mean Gray Value of the whole Ch3 stain by Region
		var Ch4_MGVs=newArray();	   // Mean Gray Value of the whole Ch4 stain by Region
		var Seg_Ch1MGVs=newArray();    // Mean Gray Value of the Ch1 stain inside the mask by Region
		var Seg_Ch2MGVs=newArray();    // Mean Gray Value of the Ch2 stain inside the mask by Region
		var Seg_Ch3MGVs=newArray();    // Mean Gray Value of the Ch3 stain inside the mask by Region
		var Seg_Ch4MGVs=newArray();    // Mean Gray Value of the Ch3 stain inside the mask by Region
		
		//See the write result section for the full list of variables in the table 
		
// Note that it could be nice to dynamically create variables only for existing channels, but I'm not sure if and how can be don in macro language
// However, Through conditional statements the macro can adapt to images having up to four channels. 
			
			
		// Open ROIs and count them
			run("Clear Results");
			roiManager("reset");
			roiManager("open", ROI_path);
			number_of_Areas=roiManager("count");
			
		// If it is not already binary, convert Segmentation image to Mask
			if(BinaryMask==false){
				selectImage(Mask);
				setThreshold(label,label);
				setOption("BlackBackground", true);
				run("Convert to Mask");
				run("Grays");
			}

//-------------------------------	ANALYZE MGV OVER ENTIRE ROIs --------------------------------------------------------
 		
	run("Set Measurements...", "area mean reDirect=None decimal=4");
 		
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
 			
//-------------------------- MEASURE MGV UNDER THE MASK IN EACH ROI -------------------------------------
 
// The strategy is to eliminate in each channel the fluorescence outside the mask and than measure again the MGV over the ROIs (exactly as before)
 			
//------------------------------- DELETE FLUORESCENCE OUTSIDE THE SEGMENTATION   ----------------------------------------------
		
		// Invert the Mask
		selectImage(Mask);
		run("Invert");
		
		//Convert to an array the list of channels to save
		Save_SegCropArray=split(Save_SegCrop, ",");
		
		//Loop trough all the images to delete signal outside the segmented area
		for (i = 0; i < FluoImages.length; i++) {
			imageCalculator("Subtract", FluoImages[i],Mask);
			//Save the Channels indicated by the user
			for (j = 0; j < Save_SegCropArray.length; j++) {
				if(channel_names[i]==Save_SegCropArray[j]){
					selectImage(FluoImages[i]);
					saveAs("Tiff", Crop_Dir + File.separator + channel_names[i] + "-" + BaseName +"_"+ MaskType + "_only.tif");		
				}
			  }
			}
			
// -------------------------- Measure MGV -------------------------------------
	
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
	 	
//-------------------------------	ANALYZE SEGMENTATION AREA  --------------------------------------------------------
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
			for(i=0;i<Region_indexes.length;i++){ // Iterate through ROIs, there will be one row per ROI results
				setResult("Image.ID", i, BaseName);// Original Image Name, can be used to merge the results
				setResult("Specimen", i, Specimen);// Specimen Name
				setResult("Section.ID", i, zLevel);// Z level of the image
				setResult("Mask", i, MaskType);    // Prefix of the Mask image
				setResult("Region.Index", i, Region_indexes[i]); // Name of the ROI
				setResult("Region_Area", i, Region_areas[i]);    // Area of the ROI
				setResult(MaskType + "_Area", i, Seg_areas[i]);  // Area of the Mask
				AreaFraction=Seg_areas[i]/Region_areas[i];
				setResult(MaskType + "_Area_Fraction",i,AreaFraction); // Area Fraction of the Mask
				setResult(channel_names[0] + "_MGV", i, Ch1_MGVs[i]);     // MGV of the ROI
				setResult(channel_names[0]+"_" + MaskType+".MGV", i, Seg_Ch1MGVs[i]/AreaFraction); // MGV of the Mask in the ROI
				//MGV of the segmented area were collected over the entire area, but keeping only the pixels inside the mask and and must thus be scaled by the Mask Area Fraction
				
				if(FluoImages.length>1){
				setResult(channel_names[1] + "_MGV", i, Ch2_MGVs[i]);
				setResult(channel_names[1]+"_" + MaskType+"_MGV", i, Seg_Ch2MGVs[i]/AreaFraction);
				}
				if(FluoImages.length>2){
				setResult(channel_names[2] + "_MGV", i, Ch3_MGVs[i]);
				setResult(channel_names[2]+"_" + MaskType+"_MGV", i, Seg_Ch3MGVs[i]/AreaFraction);
				}
				if(FluoImages.length>3){
				setResult(channel_names[3] + "_MGV", i, Ch4_MGVs[i]);
				setResult(channel_names[3]+"_" + MaskType+"_MGV", i, Seg_Ch4MGVs[i]/AreaFraction);
				}
			}
					
			saveAs("Results", CSV_Dir+File.separator+BaseName+"_Masks_Quantif_"+MaskType+".csv"); 
											
	}// END OF THE INDIVUDUAL SLICE PROCESSING BLOCK
			
		//close all images and release memory from RAM
			run("Close All");
			call("java.lang.System.gc");
			roiManager("reset");
			run("Clear Results");	

}}// END OF SLICES PROCESSING FOR LOOP

for(i=0;i<fileNotFound.length;i++){
	setResult("FileName", i, fileNotFound[i]);
}
saveAs("Results", CSV_Dir+File.separator+"_Quantif_"+MaskType+"_FileNotFound.csv"); 

print("D O N E !");








/*

// MEASURE ALL ROIs //
		// The strategy is to generate a mask of the segmentation under the area of the ROI
		// This create multiple masks, if the ROIs are numerous, an alternative strategy would be to create a single mask 
		// and measure MGV of the segmentation to calculate the Area. (AreaRegion*(MGV mask/255))
		
		// Measure segmentation area in each ROI
			selectImage(Mask);
			for(i=0; i<number_of_Areas; i++) {
				run("Clear Results");
				roiManager("Select", i);
				ROI_name=Roi.getName;
				roiManager("measure");
				AreaROI=getResult("Area", 0);
				MgvROI=getResult("Mean", 0);
				Area=AreaROI*(MgvROI/255);
				//Populate arrays to store ROI result
				Experimental_Groups = Array.concat(Experimental_Group,Experimental_Groups);
				Specimens = Array.concat(Specimen,Specimens);
				zLevels = Array.concat(zLevel,zLevels);
				Antigens = Array.concat(Antigen,Antigens);
				ROI_names = Array.concat(ROI_name,ROI_names);
				Areas = Array.concat(Area,Areas);
			}
		
				
		//Save the Table of Individual Section Results
		run("Clear Results");
		for(i=0;i<Experimental_Groups.length;i++){
			setResult("Experimental_Group", i, Experimental_Groups[i]);
			setResult("Specimen", i, Specimens[i]);
			setResult("zLevel", i, zLevels[i]);
			setResult("Antigen", i, Antigens[i]);
			setResult("ROI_name", i, ROI_names[i]);
			setResult("Area", i, Areas[i]);
					}					
			saveAs("Results", CSV_Dir+File.separator+tit+"_Quantif.csv");

		//Populate the Global Arrays
		Experimental_Groups_all=Array.concat(Experimental_Groups,Experimental_Groups_all);
		Specimens_all=Array.concat(Specimens,Specimens_all);
		zLevels_all=Array.concat(zLevels,zLevels_all);
		Antigens_all=Array.concat(Antigens,Antigens_all);
		ROI_names_all=Array.concat(ROI_names,ROI_names_all);
		Areas_all=Array.concat(Areas,Areas_all);
		
			run("Close All");
			call("java.lang.System.gc");
 		}
 		//If some of the associated files was not found the original image is added to the non found list
 		else {
 			fileNotFound=Array.concat(tit,fileNotFound);
 			print(ROI_path + " Not Found");
 		}
  }
}

//Print File Not found List
			run("Clear Results");
			for(i=0;i<fileNotFound.length;i++){
				setResult("Files lacking something", i, fileNotFound[i]);
				}
			saveAs("Results", Out_dir+File.separator+analysis_name+"FilesNotFound.csv");	
		
print("Done!");	

*/