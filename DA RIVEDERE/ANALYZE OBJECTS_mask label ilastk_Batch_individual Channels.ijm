#@ String(label="Assay name") Assay_name
#@ String(value="DIRECTORIES, can be only one if fluo image are the ONLY ONE with .tif extension", visibility="MESSAGE") hints1
#@ File (label="Select stacks directory", style = "directory") input
#@ File (label="Select ROIs directory", style = "directory") ROIs_dir
#@ File (label="Select Predictions and Identities directory", style = "directory") Mask_dir 
#@ File (label="Select directory to save Results", style = "directory") dir
#@ String(value="TAGS", visibility="MESSAGE") hints2
#@ String (label="Predictions & Identitis tag (before original file name) (write x to skip)") tag
#@ String (label="ROIs tag (after original file name) (write x to skip)") ROItag
#@ String(value="Labels and Channels. SEPARATE NAMES WITH COMMA (,)", visibility="MESSAGE") hints3
#@ String(label="Label Names (1 to n)") labels_names
#@ String(label="Channels names, separated by comma (,)") channels_names

// file format of the fluorescence images 
image_format=".tif";

/* This macro measure the fluorescence intensity and the number of objects in .tif segmented stack images for up to six channel images.
 * all files present in a folder can be processed in batch. To count in subregions a .zip file associated to each image can be provided, otherwise the full image will be quantified
 * For each image it require separate files containing objects masks Identities, for individual objects, and predictions (for multiple objects categories), as can be obtainind after Ilastik object classification 
 * Source image and ROIs can be in the same folder as long as the original image has unique extension (.tif). 

FILE NAMES REQUIREMENTS:
for each fluorescence image, image segmentations and rois are retriesved based on the original fluorescence name following the scheme:
	Single Channel Image: ChannelName-Fluorescence image name + .tif
 	ROI: Fluorescence image Name + ROI-tag + .zip;
	Predictions: Mask-tag + Fluorescence image Name + "_Object Predictions.tiff";
	Identities = Mask-tag + Fluorescence image Name +"_Object Identities.tiff";

Examples
Sp8-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1.tif
BrdU-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1.tif
Sp8-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1_Object Identities.tiff
Sp8-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1_Object Predictions.tiff
P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1_MAX_ROIs.zip


INSTALLED PLUGINS REQUIREMENTS:
Requires 3D suite and MorpholibJ */

setBatchMode(true);

if(ROItag=="x"){
	ROItag="";
}

if(tag=="x"){
	tag="";
}

// convert lists to arrays (must be separated by ",")
labels_names=split(labels_names,",");
channels_names=split(channels_names, ",");
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

// Define an Array to store the name of files fo which ROIs Predictions or Identities were not found
fileNotFound=newArray();

// Defne an array to store the name of the already processed (considering that each include several files all in the same folder)
fileProcessed=newArray();

InputList = getFileList(input);
print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
	if (endsWith(list[l], image_format)) {
		// Get the Basename
		SplitName=split(InputList[l],"-");
		BaseName="";
		for(s = 1; s<SplitName.length; s++){
			BaseName=BaseName+SplitName[s];
		}
		// remove the extension from the BaseName
		BaseName=StripExtension(BaseName);
		
	//------ PROCESS ONLY IF IMAGES WITH THE SAME BASE NAME HAVE NOT ALREADY BEEN PROCESSED-------------
		if(!contains(fileProcessed,BaseName)) {
			// if not,add it to the list of already processed images
			fileProcessed=Array.concat(fileProcessed,BaseName);
		
	//-------CHECK ROIs, OBJECT PREDIICTIONS AND IDENTITIS FILES EXISTENCE----------------------
			print("X___X___X___X___X___X___X___X___X___Analyzng: " + BaseName+"X___X___X___X___X___X___X___X___X___");
			// Define the path of ROIs Predictions and Identities and check thier existence
			ROI_path =ROIs_dir+ File.separator + BaseName + ROItag + ".zip";
			Mask_path = Mask_dir + File.separator + tag +"-"+ BaseName + "_Object Predictions.tiff";
			Ident_path = Mask_dir+File.separator+ tag +"-"+ BaseName+"_Object Identities.tiff";
			
			
			print("searching " + BaseName + ROItag + ".zip");
			if(File.exists(ROI_path)){
				print("			ROI file found!");
			} else{
				print("			ROIs file not found, the entire image area will be analyzed");
			}
			print("searching "+ tag + BaseName + "_Object Predictions.tiff");
			if(File.exists(Mask_path)){
				print("			Object Predictions file found!");
			} else{
				print("			!File not Found");
			}
			print("searching "+ tag + BaseName +"_Object Identities.tiff");
			if(File.exists(Ident_path)){
				print("			Object Identities file found!");
			} else{
				print("			!File not Found");
			}
				
	//------------ OPEN THE FLUORESCENCE CHANNELS AND ADD THEIR IDs TO AN ARRAY----------------------
					
			// Images are opened by iterating in the list of prefixes indicated in the options 
			// separated by a "-" from the BaseName according to the scheme chName-Base name.tif
			
			FluoImages=newArray();
		
			for (i=0; i<channel_names.length;i++) {
				Img= channel_names[i]+"-" + BaseName + ".tif";
				Img_path=input + File.separator + Img;
				print("Searching: " + Img_path);
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
			
	//--------------IF ALL NECESSARY FILES ARE THERE START PROCESSING -----------------------------
		
			if(File.exists(Mask_path) && File.exists(Ident_path) &&FluoImages.length>0){
					
			// Open the image associated ROIs
			roiManager("reset");
			if(File.exists(ROI_path)){
				roiManager("Open", ROI_path);
				print("opening ROI file");
			} else {
				selectImage(FluoImage);
				run("Select All");
				roiManager("Add");
				roiManager("select", 0);
				roiManager("Rename", "all");
				print("selecting the entire image");	
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
								
	//---------------PROCESS NUCLEI----------------------------------------------------------
				
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
			var ch6_mgv=newArray();
		
			run("3D Manager");
			run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");
				
			// Open Predictions(Mask) and Identities. Identities will be duplicated to
			open(Mask_path);
			Predictions=getImageID();
				
			// Create an Idendity image for each label in which other labes are erased (supposing a black background). 
				
				/*NOTE that this is not optimal as 16-bit images can be large, thus increasing processing time and limiting the number of labels that can be processed 
				 The best option would be to simply add to the 3Dmanager different sets for each label, filtering them by selecting the labels
				 This could be done easily making each label as a selection and than adding to 3D manager, but than filtering also by the area ROIs become trickier 
				 and I'm thus leaving it for duture developments. */
			for (i = 0; i < number_of_labels; i++) {
				open(Ident_path);
				rename("Identities_"+i+1);
				run("Properties...", "pixel_width="+pw+" pixel_height="+ph+" voxel_depth="+pd);
			}
			for (i = 0; i < number_of_labels; i++) {
				selectImage(Predictions);
				run("Select Label(s)", "label(s)="+i+1);
				Temp=getTitle();
				Ext.Manager3D_SelectAll();
				Ext.Manager3D_Delete();
				Ext.Manager3D_AddImage();
					// erase unwanted cells from the Identities images of all other labels 
				for (k = 0; k < number_of_labels; k++) {
					if(k+1 != i+1){
						selectWindow("Identities_"+k+1);
						Ext.Manager3D_Select(0);
						Ext.Manager3D_FillStack(0, 0, 0);
					}
				}
				close(Temp);
			}
					
				
	//-----------------ANALYZE INDIVIDUAL CHANNELS WITH Process Nuclei Function---------------------
				selectImage(FluoImage);
				if(Orig_channels>1){		
					run("Split Channels");
				}
				
				// Complete cells (enterely included in the volume) MUST BE processed first, 
				// they must contain the tag "Complete"
				// At each passage the processed cells are earased from the original mask
				// In this way the remaining cells are the incomplete cells.
				// filling can be de-activated by setting the last variable to 0 (1 is for filling)
				// the variable required by "Process_Nuclei" function are: (LABEL,ROI,Nuclei_tag,Area_tag,complete_tag,filling)
				// complete_tag must be either "Complete" or "Incomplete".
				// see below for further information on the function variables
				
				
				// Loop trough labels and ROIs to Process Nuclei
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
				
				// create results Table with all SegObj nuclei measurements and annotations
				run("Clear Results");
				for(i=0;i<SegObj_labels.length;i++){
					setResult("GroupM", i, Group);
					setResult("Specimen", i, Specimen);
					setResult("AnimalId", i, AnimalId);
					setResult("SlideCoordinates", i, SlideCoord);
					setResult("zLevel", i, zLevel);
					setResult("pz", i, pz);
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
				
				}		
				saveAs("Results", CSV_Dir+File.separator+tit+"_SegObj_measurements_.csv"); 
			}else{
				fileNotFound=Array.concat(tit,fileNotFound);
			}	
  		}
	}
  // before start processing a new file close all and release memory
  			run("Close All");
			call("java.lang.System.gc");
}

print("Files lacking Rois or Masks: "); 
Array.print(fileNotFound);
print("Done!");


//---------------------------------------PROCESS NUCLEI FUNCTION (FOR STACKS)--------------------------

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

//import nuclei in 3D manager
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
	Ext.Manager3D_Save(ROIs3D_Dir+ File.separator + tit+"_SegObjobj_3Droi_"+Type_tag+".zip");
	Ext.Manager3D_Measure();
	Ext.Manager3D_SaveResult("M",TXT_Dir + File.separator + tit+"_SegObjobj_Volumes_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("M");

// Measure fluorescence levels in channels
// As I think variables cannot be declared dynamically over for loops in macro language, I  use if statement to process the channels (up to 4)
	
	if(Orig_channels==1){
		selectImage(FluoImage);
	} else {
		selectWindow("C1-"+tit);
	}
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

function StripExtension(filename){
	NameSplit=split(file,".");
	fileWext=NameSplit[0];
	for (i = 1; i < NameSplit.length-1; i++) {
		fileWext=fileWext+"."+NameSplit[i];
	}
	return fileWext;
}

function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}
