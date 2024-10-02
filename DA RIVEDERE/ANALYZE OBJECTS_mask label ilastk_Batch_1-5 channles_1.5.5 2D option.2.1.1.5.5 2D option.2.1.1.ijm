#@ String(label="Assay name") Assay_name
#@ String(value="DIRECTORIES, can be only one if fluo image are the ONLY ONE with .tif extension", visibility="MESSAGE") hints1
#@ File (label="Select stacks directory", style = "directory") input
#@ Boolean (label="Use an ROI file?") ROIs_no_ROIs
#@ File (label="Select ROIs directory", style = "directory") ROIs_dir
#@ File (label="Select Mask Directory", style = "directory") Mask_dir 
#@ Boolean (label="Extract individual objects (connected component analysis") split_mask
#@ File (label="Select directory to save Results", style = "directory") dir
#@ String(value="TAGS", visibility="MESSAGE") hints2
#@ String (label="Mask tag (before original file name) (leave blank to skip)") tag
#@ String (label="Mask tag (after original file name) e.g Simple Segmentation", value="Simple Segmentation") MaskTag
#@ String (label="ROIs tag (after original file name) (write x to skip)") ROItag
#@ String(value="Labels and Channels. SEPARATE NAMES WITH COMMA (,)", visibility="MESSAGE") hints3
#@ String(label="Label Names (1 to n)") labels_names
#@ String(label="Channel Names (Max 4)") channels_names
#@ Integer(label="Background gray level") background

// Add here processing to apply to the Mask
function ProcessMask() {
	//run("Options...", "iterations=2 count=2 do=Close stack");
}

if(ROItag=="x"){
	ROItag="";
}

/* This macro measure the fluorescence intensity and the number of objects in .tif segmented stack images for up to four channel images.
 * all files present in a folder can be processed in batch
 * For each image it require separate files containing objects masks Identities, for individual objects, and predictions (for multiple objects categories), 
 * as can be obtainind after Ilastik object classification 
 * Source image and ROIs can be in the same folder as long as the original image has unique extension (.tif). 

FILE NAMES REQUIREMENTS:
for each fluorescence image, image segmentations and rois are retriesved based on the original fluorescence name following the scheme:
 	ROI: Fluorescence image Name + ROI-tag + .zip;
	Predictions: Mask-tag + Fluorescence image Name + "_Object Predictions.tiff";
	Identities = Mask-tag + Fluorescence image Name +"_Object Identities.tiff";

INSTALLED PLUGINS REQUIREMENTS:
Requires 3D suite and MorpholibJ */

setBatchMode(true);

// convert lists to arrays (must be separated by ",")
labels_names=split(labels_names,",");
channels_names=split(channels_names,",");
number_of_labels=labels_names.length;

//create csv and txt directories
TXT_Dir= dir +File.separator+Assay_name+"_3D manager_full_results";
CSV_Dir= dir +File.separator+Assay_name+"_Images_Measurements_csv";
ROIs_Areas= dir +File.separator+Assay_name+"_ROIs_areas_csv";
ROIs3D_Dir=dir+File.separator+Assay_name+"_3D_ROIs";

File.makeDirectory(TXT_Dir);
File.makeDirectory(CSV_Dir);
File.makeDirectory(ROIs3D_Dir);
File.makeDirectory(ROIs_Areas);

print(Assay_name);
print("input folders");
print("        "+input);
print("        "+ROIs_dir);
print("        "+Mask_dir);
print("saving results to:" + dir);


//-----------------------------DEFINE VARIABLES, IMAGES AND ROI NAMES----------------------

// Define an Array to store the name of files fo which ROIs Predictions or Identities were not found
fileNotFound=newArray();

InputList = getFileList(input);
print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
 if (endsWith(InputList[l], ".tif")) { 			
	// get names, this will be used as a base to find ROIs, Identities and Predictions
			
	open(input+File.separator+InputList[l]);
	getDimensions(Orig_width, Orig_height, Orig_channels, Orig_slices, Orig_frames);
	getPixelSize(unit, pw, ph, pd);
	FluoImage=getImageID();
	tit = getTitle();
	titWext= File.nameWithoutExtension;
	print("X___X___X___X___X___X___X___X___X___Processing: " + tit+"X___X___X___X___X___X___X___X___X___");
	
	// Define the path of ROIs and Mask and check thier existence
	ROI_path =ROIs_dir+ File.separator + titWext + ROItag + ".zip";
	print("searching: "+ titWext + ROItag + ".zip");
	if(ROIs_no_ROIs){
		print("ROIs file not required");
		ROI_go=true;
	} else{
		if (File.exists(ROI_path));
		ROI_go=true;
		print("ROIs file found");
	}
	Mask_path = Mask_dir + File.separator + tag + titWext + "_"+ MaskTag + ".tiff";
	print("searching: "+ tag + titWext + "_"+ MaskTag + ".tiff");
	if(File.exists(Mask_path)){
		print("Prediction file found");
	}

	// If all files exists the image is processed, otherwise its name is added to the file_not_found list

	if(ROI_go && File.exists(Mask_path)) {							
		
		// Extract slice details from the filename
		// Names are expectd to be composed by: ExperimentalGroup.ID_Region_zLevel_pz_ other stuff
		// e.g. Healthy.7_STRdx_z87_pz3_c2r1_2nd Round_merging.lif_1.tif
		splittedName=split(tit, "_");
		Specimen=splittedName[0];
		splittedAnimal=split(splittedName[0],".");
		Group=splittedAnimal[0];

		// Open the image associated ROIs or Select all 
		roiManager("reset");
		if (ROIs_no_ROIs==false) {
			run("Select All");
			Roi.setName("ALL");
			roiManager("Add");
		} else {
		roiManager("Open", ROI_path);
		}
		
		// create an array with the ROIs names, that will be passed to the Process Nuclei Function
		ROI_names=newArray();
		Area_value=newArray();
		run("Set Measurements...", "area display redirect=None decimal=4");
		number_of_ROIs=roiManager("count");
		for (i=0; i<number_of_ROIs;i++){
			run("Clear Results");
			roiManager("select", i);
			ROI_name=Roi.getName;
			ROI_names=Array.concat(ROI_names,ROI_name);
			run("Measure");
			Area=getResult("Area",0);
			Area_value=Array.concat(Area,Area_value);
		}	

		run("Clear Results");	
		for (i = 0; i < number_of_ROIs; i++) {
			setResult("GroupM", i, Group);
			setResult("Animal_id", i, Specimen);
			setResult("ImageName", i, tit);
			setResult("ROI_name", i, ROI_names[i]);
			setResult("Area", i, Area_value[i]);
		}
		saveAs("Results", ROIs_Areas+File.separator+tit+"_ROI_areas.csv"); 
		run("Clear Results");			
				
											
		//---------------PROCESS MASK----------------------------------------------------------
			
			//Set arrays to set results (set as global arrays in order to fill them within the user defined Process_Nuclei function)
			//Nuclei features
		var SegObj_labels=newArray();
		var SegObj_names=newArray();
		var SegObj_volumes=newArray();
		var SegObj_X=newArray();
		var SegObj_Y=newArray();
		var SegObj_Z=newArray();
		var SegObj_Zmin=newArray();
		var SegObj_Zmax=newArray();
			
			//Fluorescence measurements (additional channels can be added here, in the function and result table)
			//As far as I have undestood it is not possible to dynamically declare variables within  a for loop ( over all channels) in the macro language
		var ch1_mgv=newArray();
		var ch2_mgv=newArray();
		var ch3_mgv=newArray();
		var ch4_mgv=newArray();
		var ch5_mgv=newArray();
	
		run("3D Manager");
		run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");
			
		// Open Predictions(Mask) and Identities. Identities will be duplicated to
		open(Mask_path);
		Mask=getImageID();
		run("Properties...", "pixel_width="+pw+" pixel_height="+ph+" voxel_depth="+pd);
		
		if (split_mask) {
			// Create an Identity image for each label			
			getStatistics(area, mean, min, max, std, histogram);
			for (i = 1; i <= max; i++) {
				if(i!=background) {
					selectImage(Mask);
					run("Duplicate...", "duplicate");
					rename("Mask_"+i);
					setThreshold(i, i, "raw");
					run("Convert to Mask", "background=Dark");
					ProcessMask();
					run("3D Simple Segmentation", "low_threshold=1 min_size=200 max_size=-1");
					rename("Identities_"+i);
				}
			}
		}	
							
//-----------------ANALYZE INDIVIDUAL CHANNELS WITH Process Nuclei Function---------------------
			selectImage(FluoImage);
			run("Split Channels");
			
			// Complete cells (enterely included in the volume) MUST BE processed first, 
			// they must contain the tag "Complete"
			// At each passage the processed cells are earased from the original mask
			// In this way the remaining cells are the incomplete cells.
			// filling can be de-activated by setting the last variable to 0 (1 is for filling)
			// the variable required by "Process_Nuclei" function are: (LABEL,ROI,Nuclei_tag,Area_tag,complete_tag,filling)
			// complete_tag must be either "Complete" or "Incomplete".
			// see below for further information on the function variables
			
			// Loop trough labels and ROIs to Process Nuclei
			// If only one slice is present there is no need to distinguish between complete and incomplete cells
			if (Orig_slices<2){
					for (i = 0; i < number_of_labels; i++) {
						for(k = 0; k < number_of_ROIs; k++){
							Process_Nuclei(i+1,k,labels_names[i],ROI_names[k],"",1);
					}
				}
			}
			else{
				// Complete cells First
				for (i = 0; i < number_of_labels; i++) {
					for(k = 0; k < number_of_ROIs; k++){
						Process_Nuclei(i+1,k,labels_names[i],ROI_names[k],"Complete",1);
					}
				}
				
				// Incomplete cells Last
				for (i = 0; i < number_of_labels; i++) {
					for(k = 0; k < number_of_ROIs; k++){
						Process_Nuclei(i+1,k,labels_names[i],ROI_names[k],"Incomplete",1);
					}
				}
			}
					
			// create results Table with all SegObj nuclei measurements and annotations
			run("Clear Results");
			for(i=0;i<SegObj_labels.length;i++){
				setResult("Group", i, Group);
				setResult("Animal_id", i, Specimen);
				setResult("ImageName", i, tit);
				setResult("label", i, SegObj_labels[i]);
				setResult("name", i, SegObj_names[i]);
				split_names=split(SegObj_names[i],"_");
				setResult("ObjectType", i, split_names[0]);
				setResult("Area", i, split_names[1]);
				setResult("CompleteIncomplete", i, split_names[2]);
				setResult("volume", i, SegObj_volumes[i]);
				setResult("X", i, SegObj_X[i]);
				setResult("Y", i, SegObj_Y[i]);
				setResult("Z", i, SegObj_Z[i]);
				setResult("Zmin", i, SegObj_Zmin[i]);
				setResult("Zmax", i, SegObj_Zmax[i]);
				setResult(channels_names[0] + "_mgv",i, ch1_mgv[i]);
				if (Orig_channels>1) {
				setResult(channels_names[1] + "_mgv",i, ch2_mgv[i]);
				}
				if (Orig_channels>2) {
				setResult(channels_names[2] + "_mgv",i, ch3_mgv[i]);
				}
				if (Orig_channels>3) {
				setResult(channels_names[3] + "_mgv",i, ch4_mgv[i]);
				}
				if (Orig_channels>4) {
				setResult(channels_names[4] + "_mgv",i, ch5_mgv[i]);
				}
			
			}		
			saveAs("Results", CSV_Dir+File.separator+tit+"_SegObj_measurements_.csv"); 
		}
		else{
			fileNotFound=Array.concat(tit,fileNotFound);
		}	
  }
  // before starting with new file close all and release memory
  			run("Close All");
			call("java.lang.System.gc");
}

print("Files lacking Rois or Masks: "); 
Array.print(fileNotFound);
print("Done!");


//---------------------------------------PROCESS NUCLEI FUNCTION--------------------------

// This function add to 3D managers subset of nuclei from a user specified mask, export 3D ROIs and measurements
// The variable to specify are:
// LABEL: the gray value of the label
// ROI: the index of the ROI in the ROI manager
// Nucei_tag,Area_tag,complete_tag: the type of nuclei corresponding to the indicated labels and ROI
// Complete objects (enterely included in the volume) MUST BE processed first, they must contain the tag "Complete"
// If filling is activated, at each passage the processed objects are earased from the original mask, 
// thus if complete objects are processed first they will be erased from the Identity image and when it will be called again the function will process only the incomplete objects.
// filling can be de-activated by setting the last variable to 0 (1 is for filling)
// !Be careful! proper complete/incomplete objects distinction works only if the last focal plane is below the surface of the section! Dark planes will cause cells cutted at the surface to be listed as complete.
// !! This functions works on splitted channels, thus the command -  run("Split Channels"); -  should precede calling the function. !!

function Process_Nuclei(LABEL,ROI,Nuclei_tag,Area_tag,complete_tag,filling){
Type_tag=Nuclei_tag+"_"+Area_tag+"_"+complete_tag;


print("---------------------PROCESSING:"+Type_tag+ "------------------------");

//set the 3D manager options
// when processing complete cells the 3D manager is set as to exclude objects that touch the upper or lower focal plane. 

if(complete_tag=="Complete"){ 
	run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) bounding_box exclude_objects_on_edges_xy exclude_objects_on_edges_z drawing=Contour");
} else {
	run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) bounding_box exclude_objects_on_edges_xy drawing=Contour");
}

// select the image carrying the nuclei type 
selectImage("Identities_"+LABEL);

SegObj_seg=getImageID();
// also getting the title to close it at the end (I don't know how to close with the imageID
SegObj_seg_tit=getTitle();

//import nuclei in 3D manager, only those included in the selected ROIs will be imported
Ext.Manager3D_SelectAll();
Ext.Manager3D_Delete();
roiManager("Select", ROI);
Ext.Manager3D_AddImage();
Ext.Manager3D_Count(Nb_of_objects);
print("Number of Objects:",Nb_of_objects);

//The mask is processed only if it contains at least one object
if (Nb_of_objects>0){
	//rename 3D manager ROIs with the tags name
	Ext.Manager3D_SelectAll();
	Ext.Manager3D_Rename(Type_tag+"_");
	selectImage(SegObj_seg);
	
//loop over objects to append array with SegObj nuclei main features
	for(i=0;i<Nb_of_objects;i++){
		 Ext.Manager3D_Quantif3D(i,"Mean",label); // label gray level
		 SegObj_labels=Array.concat(SegObj_labels,label);
		 Ext.Manager3D_GetName(i,name); // quantification, use IntDen, Mean, Min,Max, Sigma
		 SegObj_names=Array.concat(SegObj_names,name);
		 Ext.Manager3D_Measure3D(i,"Vol",vol); // volume
		 SegObj_volumes=Array.concat(SegObj_volumes,vol);
		 Ext.Manager3D_Centroid3D(i,cx,cy,cz)
		 SegObj_X=Array.concat(SegObj_X,cx);
		 SegObj_Y=Array.concat(SegObj_Y,cy);
		 SegObj_Z=Array.concat(SegObj_Z,cz);
		 Ext.Manager3D_Bounding3D(i,x0,x1,y0,y1,z0,z1);
		 SegObj_Zmin=Array.concat(SegObj_Zmin,z0);
		 SegObj_Zmax=Array.concat(SegObj_Zmax,z1);
	}
// Save the 3D ROIs and the full Measure table	
	Ext.Manager3D_SelectAll();
	//Ext.Manager3D_Save(ROIs3D_Dir+ File.separator + tit+"_SegObjobj_3Droi_"+Type_tag+".zip");
	Ext.Manager3D_Measure();
	//Ext.Manager3D_SaveResult("M",TXT_Dir + File.separator + tit+"_SegObjobj_Volumes_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("M");

// Measure fluorescence levels in channels
// As I think variables cannot be declared dynamically over for loops in macro language, I  use if statement to process the channels (up to 4)

	selectWindow("C1-"+tit);
	// iterate to 3D manager window to collect individual values
	for(i=0;i<Nb_of_objects;i++){
		 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
		 ch1_mgv=Array.concat(ch1_mgv,mgv);
	}
	// Save the full quatification table	
		Ext.Manager3D_Quantif();
		Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tit+"_SegObjobj_"+channels_names[0]+"_"+Type_tag+".txt");
		Ext.Manager3D_CloseResult("Q");

	if (Orig_channels>1) {
		selectWindow("C2-"+tit);	
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch2_mgv=Array.concat(ch2_mgv,mgv);
		}
		// Save the full quatification table		
			Ext.Manager3D_Quantif();
			Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tit+"_SegObjobj_"+channels_names[1]+"_"+Type_tag+".txt");
			Ext.Manager3D_CloseResult("Q");
	}

	if (Orig_channels>2) {
		selectWindow("C3-"+tit);	
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch3_mgv=Array.concat(ch3_mgv,mgv);
		}
		// Save the full quatification table		
			Ext.Manager3D_Quantif();
			Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tit+"_SegObjobj_"+channels_names[2]+"_"+Type_tag+".txt");
			Ext.Manager3D_CloseResult("Q");
	}		

	if (Orig_channels>3) {
		selectWindow("C4-"+tit);	
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch4_mgv=Array.concat(ch4_mgv,mgv);
		}
		// Save the full quatification table		
			Ext.Manager3D_Quantif();
			Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tit+"_SegObjobj_"+channels_names[3]+"_"+Type_tag+".txt");
			Ext.Manager3D_CloseResult("Q");
	}
	
	if (Orig_channels>4) {
		selectWindow("C5-"+tit);	
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch5_mgv=Array.concat(ch5_mgv,mgv);
		}
		// Save the full quatification table		
			Ext.Manager3D_Quantif();
			Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tit+"_SegObjobj_"+channels_names[4]+"_"+Type_tag+".txt");
			Ext.Manager3D_CloseResult("Q");
	}

if (filling==1){
	selectImage(SegObj_seg);
	Ext.Manager3D_SelectAll();
	Ext.Manager3D_FillStack(0, 0, 0);
}

  }
  if(Nb_of_objects==0) {
		print("No objects found, processing aborted");
	}
	//close(SegObj_seg_tit);
}

// This function find a string 
function getSubstring(string, prefix, postfix) {
   start=indexOf(string, prefix)+lengthOf(prefix);
   end=start+indexOf(substring(string, start), postfix);
   if(start>=0&&end>=0)
     return substring(string, start, end);
   else
     return "";
}
