#@ String(value="FLUORESCENCE IMAGES", visibility="MESSAGE") hints
#@ File (label="Fluorescence Images directory", style = "Directory") Dir
#@ String(label="Channels names, separated by comma (,)") Channels
#@ String(value="SEGMENTATION MASKS", visibility="MESSAGE") hints2
#@ File (label="segmentation masks directory", style = "Directory") Mask_Dir
#@ String(label="Antigen of segmentation images (as prefix, e.g. WFA-; leave blank if absent)",value="WFA-") ChRefTag
#@ String(label="Segmentation name (to name the results)") AnalysisTag
#@ String(label="Tag of segmented mask (at the end of the file name)",value="Simple Segmentation") SegTag
#@ String(label="Gray value of the segmentation to analyze (set 0 to join all)") label_value
#@ String(value="ATLAS 16-BIT IMAGES", visibility="MESSAGE") hints3
#@ File (label="Atlas Directory", style = "Directory") Atlas_Dir
#@ String(label="Tag of Atlas Images (in the file name)") AtlasTag
#@ String(value="OUTPUTS", visibility="MESSAGE") hints4
#@ File (label="Directory to Save Results", style = "Directory") Save_Dir
#@ String(value="Indicate channel names separated by comma (e.g. PV,WFA)", visibility="MESSAGE") hints5
#@ String(label="Save Segmentation Cropped fluorescence images for channels: ") Save_SegCrop
#@ String(value="Atlas ROIs are expected in Atlas_ROIs folder inside the Result folder", visibility="MESSAGE") hints6
#@ Boolean(label="Use Pre-calculated Atlas ROIs: ") PreBakedROIs

/* This Macro analyze segmentation masks of brian sections, from one or multiple brains, aligned to a brain atlas. 
 *  In each area and section it extract the area and MGV values over the desired channels (up to 4), and save a csv file with multiple infromation by area and section
 *  Right and left emispheres results are summed togheter (cannot be easily separated).
 *   Different animals can be anailized togheter
 *  The macro iterates through the ATLAS images and retrive the Fluorescence and Mask images base on the file names.
 *  For this reason the file name MUST strictly adhere to the following rules:
 * 	 All image tyoes images must have a common base name we will refer as ImageName, formatted as follows: 
 * 	 
 *    				GroupName.ID_tag_sNNN (NNN is the number of the section with a 3 digits formatting)
 *    				
 *    FLUORESCENCE IMAGE:
 *    	Image name must be strictly formatted to this template:
 *  	Antigen-ImageName.tif 
 * 		e.g.(Dapi-FmrKO.6_quickNII_s130.tif)
 * 		This format is adapted from that required for QuikNII alignement and can be obtained by exporting images from TrakEM2 with the macro: EXPORT flat_Filter Patch_write to file 3.1.py
 * 		Multiple channels can be analyzed, list the channels in the corresponding dialog box, separated by commas.
 * 		
 * 	  ATLAS IMAGE
 * 	  	Atlas images are exptected as 16-bit tif images where gray values indicate the brain area (according to any code, the code is not translated into areas names within the macro). 
 * 	  	the name must be identical to that of the corresponding image with the addition of an atlas tag separated by an underscore "_"
 * 	  	ImageName_atlasTag.tif
 * 	  	(WFA-FmrKO.6_quickNII_s130_atlas.tif)
 * 	  	The images can be scaled and have different aspect ratios, thay will be all scaled to fit the original image.
 * 	  	
 * 	  MASK
 * 	  	Mask is expected as 8-bit tif, can contain more than one object, codified by different gray level, but only one is analyzed at each run.
 * 	  	The gray level of the mask to analyze must be specified in the corresponding dialog. To merge all the masks into one set it to 0.
 * 	  	Prefix-ImageName_segmentationTag.tif 
 * 	  	prefix: if Ilastik is used to obtain the mask, the prefix will correspond to the one of the segmented channel
 * 	  	segmentationTag: if Ilastik is used to obtain the mask, the default tag added at the end of the name is "Simple Segmentation")
 * 	  	(WFA-FmrKO.6_quickNII_s130_atlas.tif)
 * 	  	
 * Note that the areas will be converted to ROIs, however if this step waas already done it can be avoided by chosing the option "use pre-calcluated Atlas ROIs"
 * In any  case the Atlas folder MUST be available, as this is the reference to iterate all the sections aligned to the atlas. 
 * These images however are usually obtained on scaled images and do not occupy a lot of space.
 * 	  	
 */

//show ops variables names to the autocmpletion function
Dir=Dir
Channels=Channels
Mask_Dir=Mask_Dir
Atlas_Dir=Atlas_Dir
ChRefTag=ChRefTag
AnalysisTag=AnalysisTag
label_value=label_value

// WFA meglio in cartella per conto suo, così apriamo prima quella e facciamo tutto di conseguenza
// in alternativa si potrebbe aprire prima l'atlante e poi cercare i vari canali, o aprire il multitiff e scegliere i canali. 
// Questo forse velocizzerebbe anche l'analisi delle fluo su tutti, tanto bisognerà tenerli aperti in contemporanea.

//Tolto il .tif dallo zeta level e aggiunta colonna per condition e specimen name.

//close all images and release memory from RAM
if(nImages>0){
	waitForUser("Warning! All Images will be closed!");
}
run("Close All");
call("java.lang.System.gc");
run("Clear Results");
roiManager("reset");

//create csv Directories
CSV_Dir= Save_Dir +File.separator+"csv";
Seg_Dir= Save_Dir +File.separator+"PNN_crop";
Atlas_10perc_Dir= Save_Dir +File.separator+"Atlas_10perc";
Atlas_ROIs_Dir= Save_Dir +File.separator+"Atlas_ROIs";
File.makeDirectory(CSV_Dir);
File.makeDirectory(Seg_Dir);
File.makeDirectory(Atlas_10perc_Dir);
File.makeDirectory(Atlas_ROIs_Dir);

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

list = getFileList(Atlas_Dir);

for (k = 0; k < list.length; k++) {
	//print(Dir+File.separator + list[k]);
	if (endsWith(list[k], ".tif")) { 				
	
		// get names, this will be used as a base to find ROIs, Identities and Predictions		
		open(Atlas_Dir+File.separator+list[k]);
		getStatistics(area, mean, min, max, std, histogram);
		if (mean>0) { // the atlas do contain some areas to analyze
			Atlas_Img=getImageID();
			getDimensions(Atlas_width, Atlas_height, Atlas_channels, Atlas_slices, Atlas_frames);
			tit = getTitle();
			titWext= File.nameWithoutExtension;
		
		// Remove the atlas tag to get the base name
			BaseName=replace(titWext,AtlasTag,"");
			
			print("X___X___X___X___X___X___X___X___X___Processing: " + BaseName + "X___X___X___X___X___X___X___X___X__" );
			
			// Extract slice details from the filename
			// Names are expectd to be like: Specimen Name_ImageType_zLevel_other stuff
			// e.g. Fmr-Ko2_quickNII_s072.png
			splittedName=split(BaseName, "_");
			Specimen=splittedName[0];
			print("Specimen: "+Specimen);
			zString = getSubstring(tit, "_s", AtlasTag);
			zValue = NaN; //or whatever to tell you that you could not read the value
					 if(zString!="") {
			   			zValue=parseInt(zString); //parseFloat if not always an integer value
					 }
					 	 
			print("Z-level: "+zValue);
	
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
					getDimensions(Original_width, Original_height, Original_channels, Original_slices, Original_frames);// Get the dimensions to calculate the scale factor between atlas and Original Images
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
		
			
		//-------------------------------	CONVERT THE ATLAS TO ROIS-------------------------------------------------
		
		// Calculate the scale factor for the images
				roiManager("reset");
				scale_factorX=Original_width/Atlas_width;
				scale_factorY=Original_height/Atlas_height;
				print("Scale Factor: "+ scale_factorX+ " "+ scale_factorY);
		
		// Pre-calculated ROIs are expected in the same folder where the macro would have save them
			if (PreBakedROIs==true){
				roiManager("open", Atlas_ROIs_Dir + File.separator + BaseName + "_atlasROIs.zip");
				number_of_Areas=roiManager("count");
				} else {
		
			// Use 3D manager to import each area and convert them to ROIs (could be avoided but is easier to work with)
				print("Reading Map..");
				selectImage(Atlas_Img);
				Ext.Manager3D_SelectAll();
				Ext.Manager3D_Delete();
				Ext.Manager3D_AddImage();
				Ext.Manager3D_Count(nb);
				//print("Regions identified:" + nb);
				for (i = 0; i < nb; i++) {
					Ext.Manager3D_Select(i);
					newImage("Untitled", "8-bit black", Atlas_width, Atlas_height, 1);
					Ext.Manager3D_FillStack(255, 255, 255);
					run("Convert to Mask");
					run("Create Selection");
					roiManager("add");
					run("Close"); // it was commented in a previous version of the macro but I don't know why.. check it out!
				}
					
			// Name ROIs according to the MGV value and than Scale them on the original image
				selectImage(Atlas_Img);
				number_of_Areas=roiManager("count");
				print("Number of ROIs:" + number_of_Areas);
				//skip Segmentation ROI that should not to be scaled
				for (v=0; v<number_of_Areas; v++) {
					selectImage(Atlas_Img);
					roiManager("Select", v);
					run("Set Measurements...", "mean display reDirect=None decimal=4");
					roiManager("Measure");
					MGV=getResult("Mean", 0);
					roiManager("Select", v);
					roiManager("rename", MGV);
					selectImage(FluoImages[0]);
					roiManager("Select", v);
					run("Scale... ", "x="+scale_factorX+" y="+scale_factorY);
					Roi.setName(MGV);
				    roiManager("Add");
				    run("Clear Results");
				}
				
				// Delete non scaled ROIs
				for (i = number_of_Areas - 1; i >= 0; i--) {
				 	roiManager("Select", i);
				 	roiManager("Delete");
		 			}
		 			
		 		// The first ROI of the atlas include all other areas (don't know exactly why..)	
		 		roiManager("Select", 0);
				roiManager("rename", "Whole_Section");
				
				//Save The atlas ROIs
				roiManager("save", Atlas_ROIs_Dir + File.separator + BaseName + "_atlasROIs.zip");
			}
		//-------------------------------	ANALYZE MGV --------------------------------------------------------
		 		
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
		//-------------------------------  DELETE FLUORESCENCE OUTSIDE THE SEGMENTATION   ----------------------------------------------
				
				//Convert to an array the list of channels to save
				Save_SegCropArray=split(Save_SegCrop, ",");
				
				//Convert the Segmentation to Mask and invert it
				open(Mask_path);
				if (label_value>0){
					setThreshold(label_value, label_value, "raw");
				}		
				Mask=getImageID();
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
				
		//-------------------------------	SAVE SCALED ATLAS IMAGES --------------------------------------------------------
				
				// Save a 10um/px Atlas Image
				selectImage(Atlas_Img);
				run("Select None");
				run("Scale...", "x="+scale_factorX/10+" y="+scale_factorY/10+" interpolation=None create");
				saveAs("Tiff", Atlas_10perc_Dir+ File.separator + BaseName + "_Atlas10um.tif");
		
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