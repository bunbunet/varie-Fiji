//@ String(value="INPUT-OUTPUT FILES", visibility="MESSAGE") hints
//@ File (label="Select Mask directory", style = "directory") input_Seg
//@ File (label="Select ROIs directory", style = "directory") input_ROI
//@ File (label="Select directory to save Results", style = "directory") Out_dir
//@ Boolean(label="Save Segmentation as ROI ") MaskRoiSave
//@ String(value="TAGS AND FORMATS", visibility="MESSAGE") hints2
//@ String(label="Masks file format", value=".tif") SegFormat
//@ String(label="Original image file format", value=".tiff") Original_Format
//@ String(label="Tag of segmentated mask", value="Simple Segmentation") SegTag
//@ String(label="Tag of ROIs file", value="_ROIs.zip") RoiTag
//@ String(label="label grey value", value="1") label
//@ String(label="Name of the analysis", value="T5a10dQ5W") analysis_name

// This script automatically calculate the area and MGV of staining from single slice image.
// It require 1) a .zip file containing the ROIs, 2) the image of the mask with segmentation
// Specimen and section information will be extracted from file name:
// The file name is expected as follow: Staining Name-Experimental Group-Specimen ID _ section number _ everithing else.file format
// Avoid using "-" in the file names for anything else.
// Output files include a single csv file with all the results and individual csvs for each section
// Users can also choose to save a ROI file of the segmention for each ROI for later use, 
// that will be saved in a new folder inside the segmentation folder

setBatchMode(true);

// create directory to save results and segmentation ROIs
SegRoiDir = input_Seg + File.separator +"Segmentation_ROis";
CSV_Dir= Out_dir +File.separator+"csv";
File.makeDirectory(SegRoiDir);
File.makeDirectory(CSV_Dir);

//-----------------------------DEFINE VARIABLES, IMAGES AND ROI NAMES----------------------

run("Set Measurements...", "area mean display redirect=None decimal=3");

//Inizialize arrays to store full result list
var Experimental_Groups_all=newArray(); // Experimental Group as indicated in the file name
var Specimens_all=newArray();			// Specimen Name as indicated in the file name;
var Antigens_all=newArray();			// Antigen Name as indicated in the file name;
var zLevels_all=newArray();        		// section index as indicated in file name
var ROI_names_all=newArray(); 	  		//ROI name 
var Areas_all=newArray();   			//Area in pixels of the Segmentation in the ROI
var MGVs_all=newArray();      			// Mean Gray Value of the whole stain by ROI

// Define an Array to store the name of files fo which ROIs Predictions or Identities were not found
fileNotFound=newArray();

//-------------------------------------OPEN FILE AND CHECK FILE EXISTENCE---------------------------

list = getFileList(input_Seg);

for (k = 0; k < list.length; k++) {
	if (endsWith(list[k], SegFormat)) { 
		//print(Dir+File.separator + list[k]);
		open(input_Seg+File.separator+list[k]);
		Mask=getImageID();
		tit = getTitle();
		titWext = File.nameWithoutExtension();
		// recover the name of the original image
		tit=replace(tit, SegTag, "");
		tit=replace(tit, SegFormat,Original_Format );
		
		//Parse the image name to extract slice and specimen details
		//First remove the antigen name
		NameWantigen=split(tit, "-");
		Antigen=NameWantigen[0];
		splittedName=split(NameWantigen[1], "_");
		Specimen=splittedName[0];
		zLevel=splittedName[1];
		zLevel=replace(zLevel,"z", "");
		EG_Split=split(Specimen,".");
		Experimental_Group=EG_Split[0];

		//Report file status
		print("X_X_X_X_X_X_X_X_X_X_X_X_ Processing : X_X_X_X_X_X_X_X_X_X_X_X_X_");
		print("	Specimen:"+Specimen);
		print("	Experimental Group:"+Experimental_Group);
		print("	Z-level:",zLevel);
		//print("	Antigen:",Antigen);

		//Check the existence of properly named files for ROIs and Mak
		ROI_path =input_ROI + File.separator + tit + RoiTag;
		print("searching:"+ tit + RoiTag);
		if(File.exists(ROI_path)) {
			print("found");
		}
		
//--------------- IF EVERITHING IS OK START THE MEASUREMENTS ONE SECTION AT THE TIME--------------------------------------------------
		if(File.exists(ROI_path)) {	
						
		//Inizialize Variables to store individual Sections Measurements
			var Experimental_Groups=newArray(); // Experimental Group as indicated in the file name
			var Specimens=newArray();			// Specimen Name as indicated in the file name;
			var zLevels=newArray();        		// section index as indicated in file name
			var Antigens=newArray();			// Antigen Name as indicated in the file name;
			var ROI_names=newArray(); 	  		//ROI name 
			var Areas=newArray();   			//Area in pixels of the Segmentation in the ROI
			
		//Open ROIs and count them
			run("Clear Results");
			roiManager("reset");
			roiManager("open", ROI_path);
			nROIs=roiManager("count");
			
		//convert Segmentation image to Mask
			//convert segmentation to mask
			selectImage(Mask);
			setThreshold(label,label);
			setOption("BlackBackground", false);
			run("Convert to Mask");
			run("Grays");

		// MEASURE ALL ROIs //
		// The strategy is to generate a mask of the segmentation under the area of the ROI
		// This create multiple masks, if the ROIs are numerous, an alternative strategy would be to create a single mask 
		// and measure MGV of the segmentation to calculate the Area. (AreaRegion*(MGV mask/255))
		
		// Measure segmentation area in each ROI
			selectImage(Mask);
			for(i=0; i<nROIs; i++) {
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
		
		// Convert to selection the segmentes area in each ROI
		if(MaskRoiSave){
			selectImage(Mask);
			run("Create Selection");
			run("Make Inverse");
			if (selectionType() !=-1){
				roiManager("Add");
				for(i=0; i<nROIs; i++) {
					selectImage(Mask);
					roiManager("Select", i);
					ROI_name=Roi.getName;
					roiManager("Select", newArray(i,nROIs));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", i+nROIs+1);
					roiManager("rename", ROI_name+"-"+Antigen);	
				}
			}
			roiManager("save", SegRoiDir+ File.separator + tit + "_ROIs_mask.zip");
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

//Save the Table of the all the Sections
			for(i=0;i<Experimental_Groups_all.length;i++){
				setResult("Experimental_Group", i, Experimental_Groups_all[i]);
				setResult("Specimen", i, Specimens_all[i]);
				setResult("zLevel", i, zLevels_all[i]);
				setResult("Antigen", i, Antigens_all[i]);
				setResult("ROI_name", i, ROI_names_all[i]);
				setResult("Area", i, Areas_all[i]);
					}					
			saveAs("Results", Out_dir+File.separator+analysis_name+"_Quantif_ALL.csv");

//Print File Not found List
			run("Clear Results");
			for(i=0;i<fileNotFound.length;i++){
				setResult("Files lacking something", i, fileNotFound[i]);
				}
			saveAs("Results", Out_dir+File.separator+analysis_name+"FilesNotFound.csv");	
		
print("Done!");	
