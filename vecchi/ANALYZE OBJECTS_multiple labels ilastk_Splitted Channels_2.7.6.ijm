#@ String(label="Assay name") Assay_name
#@ String(value="DIRECTORIES, can be only one if fluo image are the ONLY ONE with .tif extension", visibility="MESSAGE") hints1
#@ File (label="Select stacks directory", style = "directory") input
#@ File (label="Select ROIs directory", style = "directory") ROIs_dir
#@ File (label="Select Predictions and Identities directory", style = "directory") Mask_dir 
#@ File (label="Select directory to save Results", style = "directory") dir
#@ Boolean(label="Add Group and Specimen names to result table (eg. Group.ID_other stuff)?") Group_Spec
#@ String(value="TAGS", visibility="MESSAGE") hints2
#@ String (label="Predictions & Identitis tag (before original file name) (write x to skip)") tag
#@ String (label="ROIs tag (after original file name) (write x to skip)") ROItag
#@ String(value="Labels and Channels. SEPARATE NAMES WITH COMMA (,)", visibility="MESSAGE") hints3
#@ String(label="Label Names (1 to n)") labels_names
#@ String(label="Channels names, separated by comma (,)") channels_names

// file format of the fluorescence images 
image_format=".tif";

/* This macro measure the fluorescence intensity and the number of objects in .tif segmented stack images for up to seven channel images.
 * (more channesl can be added manually inside the macro, unfortunatetly variables cannot be declared automatically in imageJ macro language)
 * all files present in a folder can be processed in batch. To count in subregions a .zip file associated to each image can be provided, otherwise the full image will be quantified
 * For each image it require separate files containing objects masks Identities, for individual objects, and predictions (for multiple objects categories), as can be obtainind after Ilastik object classification 
 * Source image and ROIs can be in the same folder as long as the original image has unique extension (.tif). 
 * By default objects on x-y edges are excluded while those toucing the z planed included, completely or incompletely included objects along the z axis can be filtered subsequently by the min and max Z of their bounding box, 
 * alternatively the process nuclei function allow to distinguish completely or incompletely included objects (in the z plane), 
 * uncomment the block at line 300 to activate this option

FILE NAMES REQUIREMENTS:
for each fluorescence image, image segmentations and rois are retriesved based on the original fluorescence name following the scheme:
	Single Channel Image: ChannelName-Fluorescence image name + .tif
 	ROI: Fluorescence image Name + ROI-tag + .zip;
	Predictions: Mask-tag + Fluorescence image Name + "_Object Predictions.tiff"; Labels are exptectetd to start from 1 and increment wthout gaps, as created by Ilastik.
	Identities = Mask-tag + Fluorescence image Name +"_Object Identities.tiff";

Example Names
Fluorescence Folder
Sp8-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1.tif
BrdU-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1.tif
NeuN-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1.tif
Mask Folder
Sp8-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1_Object Identities.tiff
Sp8-P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1_Object Predictions.tiff
ROIs folder
P29bP0.5_pz1_c5r2_z130_40Xsp512_merging_1_MAX_ROIs.zip


INSTALLED PLUGINS REQUIREMENTS:
Requires 3D suite and MorpholibJ 
*/


waitForUser("all Images, results and ROIs will be closed");
  // before start processing close all images and release memory
  			run("Close All");
  			roiManager("reset");
  			run("Clear Results");
			call("java.lang.System.gc");

setBatchMode(true);

if(ROItag=="x"){
	ROItag="";
}

if(tag=="x"){
	tag="";
} else{
	tag=tag+"-";
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
	if (endsWith(InputList[l], image_format)) {
		// Get the Basename
		SplitName=split(InputList[l],"-");
		BaseName="";
		for(s = 1; s<SplitName.length; s++){
			BaseName=BaseName+SplitName[s];
		}
		// remove the extension from the BaseName
		BaseName=StripExtension(BaseName);
		if(Group_Spec){
			Specimen=split(BaseName,"_");
			Specimen=Specimen[0];
			GroupM=split(Specimen,".");
			GroupM=GroupM[0];
		}
		
		
	//------ PROCESS ONLY IF IMAGES WITH THE SAME BASE NAME HAVE NOT ALREADY BEEN PROCESSED-------------
		if(!contains(fileProcessed,BaseName)) {
			// if not,add it to the list of already processed images
			fileProcessed=Array.concat(fileProcessed,BaseName);
		
	//-------CHECK ROIs, OBJECT PREDIICTIONS AND IDENTITIS FILES EXISTENCE----------------------
			print("X___X___X___X___X___X___X___X___X___Analyzng: " + BaseName+"X___X___X___X___X___X___X___X___X___");
			// Define the path of ROIs Predictions and Identities and check thier existence
			ROI_path =ROIs_dir+ File.separator + BaseName + ROItag + ".zip";
			Mask_path = Mask_dir + File.separator + tag + BaseName + "_Object Predictions.tiff";
			Ident_path = Mask_dir + File.separator+ tag + BaseName+"_Object Identities.tiff";
			
			
			print("searching " + BaseName +"-"+ ROItag + ".zip");
			if(File.exists(ROI_path)){
				print("			ROI file found!");
			} else{
				print("			ROIs file not found, the entire image area will be analyzed");
			}
			//print("searching "+Mask_path);
			print("searching "+ tag + BaseName +"-" + "_Object Predictions.tiff");
			if(File.exists(Mask_path)){
				print("			Object Predictions file found!");
			} else{
				print("			!File not Found");
			}
			print("searching "+ tag + BaseName +"-" + "_Object Identities.tiff");
			if(File.exists(Ident_path)){
				print("			Object Identities file found!");
			} else{
				print("			!File not Found");
			}
				
	//------------ OPEN THE FLUORESCENCE CHANNELS AND ADD THEIR IDs TO AN ARRAY----------------------
					
			// Images are opened by iterating in the list of prefixes indicated in the options 
			// separated by a "-" from the BaseName according to the scheme chName-Base name.tif
			
			var FluoImages=newArray();
		
			for (i=0; i<channels_names.length;i++) {
				Img= channels_names[i]+"-" + BaseName + ".tif";
				Img_path=input + File.separator + Img;
				print("Searching: " + Img);
				if(File.exists(Img_path)) {
					open(Img_path);
					print("Found!");
					tit=getTitle();
					FluoImages=Array.concat(FluoImages,tit);
					getDimensions(Original_width, Original_height, Original_channels, Original_slices, Original_frames);// Get the dimensions to calculate the scale factor between atlas and Original Images
					getVoxelSize(pw, ph, pd, unit);
				}
			}
			print(FluoImages.length + " Channels Found");
			
	//--------------IF ALL NECESSARY FILES ARE THERE START PROCESSING -----------------------------
		
			if(File.exists(Mask_path) && File.exists(Ident_path) &&FluoImages.length>0){
		
	//--------------PROCESS ROIs---------------------------	
		// Open the image associated ROIs
			roiManager("reset");
			if(File.exists(ROI_path)){
				roiManager("Open", ROI_path);
			} else {
				selectImage(FluoImages[0]);
				run("Select All");
				roiManager("Add");
				roiManager("select", 0);
				roiManager("Rename", "all");
			}	
		
		// create an array with the ROIs names, that will be passed to the Process Nuclei Function
			ROI_names=newArray();
		// create an array with the area values of each roi that will be saved as txt file
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
			
		// Save areas as a txt fle
			run("Clear Results");	
			for (i = 0; i < number_of_ROIs; i++) {
				if(Group_Spec){
				setResult("Group", i, GroupM);
				setResult("Specimen", i, Specimen);
				}
				setResult("ImageName", i, BaseName);
				setResult("ROI_name", i, ROI_names[i]);
				setResult("Area", i, Area_value[i]);
			}
			saveAs("Results", ROIs_Areas+File.separator+tit+"_ROI_areas.csv"); 
			run("Clear Results");			
								
	//---------------PROCESS PREDICTIONS AND IDENTITIES----------------------------------------------------------
						
		//--Open Predictions(Mask) and Identities. Identities will be duplicated to
			open(Mask_path);
			Predictions=getImageID();
				
		//--Createt AN INDENTITY IMAGE FOR EACH LABEL, by fiilling with black all objects belonging to other labels (erasing them supposing a black background). 		

						/*NOTE that this is not optimal as 16-bit images can be large, thus increasing processing time and limiting the number of labels that can be processed 
						 The best option would be to simply add to the 3Dmanager different sets for each label, filtering them by selecting the labels
						 This could be done easily making each label as a selection and than adding to 3D manager, but than filtering also by the area ROIs become trickier 
						 and I'm thus leaving it for duture developments. */
			for (i = 0; i < number_of_labels; i++) {
				open(Ident_path);
				rename("Identities_"+i+1); // labels starts from 1
				run("Properties...", "pixel_width="+pw+" pixel_height="+ph+" voxel_depth="+pd);
			}
			
			run("3D Manager");
			run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");
			
		// iterate through labels, add them to 3D manager and delete them in all identities images but the one (accordng to their numbers)
		// in example, label 1 of 3 (iteration variable i) will be deleted in Identities_2 and Identities_3 (iteration variable k)	
			for (i = 0; i < number_of_labels; i++) {
				selectImage(Predictions);
				run("Select Label(s)", "label(s)="+i+1); // labels starts from 1
				Temp=getImageID();;
				// clear the 3D manager
				Ext.Manager3D_SelectAll();
				Ext.Manager3D_Delete();
				// Add Labels
				Ext.Manager3D_AddImage();
				// erase unwanted cells from the Identities images of all other labels (k is different from i)
				for (k = 0; k < number_of_labels; k++) {
					if(k != i){
						selectWindow("Identities_"+k+1);
						Ext.Manager3D_Select(0);
						Ext.Manager3D_FillStack(0, 0, 0);
					}
				}
				selectImage(Temp);
				close();
			}
			
	//--------SETS ARRAYS TO STORE RESULTS PER EACH IMAGE---------------------------		
		//set as global arrays in order to fill them within the user defined Process_Nuclei function
		
		//Nuclei features
			var SegObj_labels=newArray();
			var SegObj_names=newArray();
			var SegObj_volumes=newArray();
			var SegObj_X=newArray();
			var SegObj_Y=newArray();
			var SegObj_Z=newArray();
			var SegObj_Zmin=newArray();
			var SegObj_Zmax=newArray();
						
		//Fluorescence measurements 
			var ch1_mgv=newArray();
			var ch2_mgv=newArray();
			var ch3_mgv=newArray();
			var ch4_mgv=newArray();
			var ch5_mgv=newArray();
			var ch6_mgv=newArray();
			var ch7_mgv=newArray();
			var ch8_mgv=newArray();	
			
			//(Note: arrays for additional channels must be added here, in the function and result table)
			//(As far as I have undestood it is not possible to dynamically declare variables within a for loop (over all channels) in the macro language)
			
							
	//-----------ANALYZE OBJECTS WITH Process Nuclei Function---------------------		
			
			// Complete cells (enterely included in the volume) MUST BE processed first, 
			// they must contain the tag "Complete"
			// At each passage the processed cells are earased from the original mask
			// In this way the remaining cells are the incomplete cells.
			// filling can be de-activated by setting the last variable to 0 (1 is for filling)
			// the variable required by "Process_Nuclei" function are: (LABEL,ROI,Nuclei_tag,Area_tag,complete_tag,filling)
			// complete_tag must be either "Complete" or "Incomplete".
			// see below for further information on the function variables
			
			// Loop trough labels and ROIs to Process Nuclei
			
			for (i = 0; i < number_of_labels; i++) {
				for(k = 0; k < number_of_ROIs; k++){
					Process_Nuclei(i+1,k,labels_names[i],ROI_names[k],"all",0);
				}
			}
			
			// This will produce a different set of 3D ROIs for each area and label, the function should be implemented to allow
			// renaming the objects accordingly ( but verify if this do not slow down the process)
			
			/* ACTIVATE THIS BLOCK TO DISTINGUISH COMPLETE AND INCOMPLETE CELLS 
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
			*/
			
			// create results Table with all SegObj nuclei measurements and annotations
			run("Clear Results");
			for(i=0;i<SegObj_labels.length;i++){
				if(Group_Spec){
				setResult("Group", i, GroupM);
				setResult("Specimen", i, Specimen);
				}
				setResult("ImageName", i, BaseName);
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
				if (channels_names.length>1) {
				setResult(channels_names[1] + "_mgv",i, ch2_mgv[i]);
				}
				if (channels_names.length>2) {
				setResult(channels_names[2] + "_mgv",i, ch3_mgv[i]);
				}
				if (channels_names.length>3) {
				setResult(channels_names[3] + "_mgv",i, ch4_mgv[i]);
				}
				if (channels_names.length>4) {
				setResult(channels_names[4] + "_mgv",i, ch5_mgv[i]);
				}
				if (channels_names.length>5) {
				setResult(channels_names[5] + "_mgv",i, ch6_mgv[i]);
				}
				if (channels_names.length>6) {
				setResult(channels_names[6] + "_mgv",i, ch7_mgv[i]);
				}
				if (channels_names.length>7) {
				setResult(channels_names[7] + "_mgv",i, ch8_mgv[i]);
				}	
			}		
				saveAs("Results", CSV_Dir+File.separator+BaseName+"_SegObj_measurements_.csv"); 
			} else {
				fileNotFound=Array.concat(BaseName,fileNotFound);
			}	
  		}
	}
  // before start processing a new file close all and release memory
  			run("Close All");
			call("java.lang.System.gc");
}

print("Files lacking Predictions and/or Identities: "); 
Array.print(fileNotFound);
print("Done!");


//---------------------------------------PROCESS NUCLEI FUNCTION (FOR INDIVIDUAL CHANNELS)--------------------------

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
	// feret takes a long time to compute and by default it is skipped
	//run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) bounding_box exclude_objects_on_edges_xy exclude_objects_on_edges_z drawing=Contour");
	run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value centroid_(pix) bounding_box exclude_objects_on_edges_xy exclude_objects_on_edges_z");
} else {
	//run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) bounding_box exclude_objects_on_edges_xy drawing=Contour");
	run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value centroid_(pix) bounding_box exclude_objects_on_edges_xy");
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
		 Ext.Manager3D_Bounding3D(i,x0,x1,y0,y1,z0,z1); // get the object min and max z (for stereological countings)
		 SegObj_Zmin=Array.concat(SegObj_Zmin,z0);
		 SegObj_Zmax=Array.concat(SegObj_Zmax,z1);
	}
// Save the 3D ROIs and the full Measure table	
	Ext.Manager3D_SelectAll();
	Ext.Manager3D_Save(ROIs3D_Dir+ File.separator + tag + "-" + BaseName+"_SegObjobj_3Droi_"+Type_tag+".zip");
	Ext.Manager3D_Measure();
	Ext.Manager3D_SaveResult("M",TXT_Dir + File.separator + tag+"-" + BaseName+"_SegObjobj_Volumes_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("M");

// Measure fluorescence levels in all channels
// As I think variables cannot be declared dynamically over for loops in macro language, I  use if statement to process the channels (up to 4)
	
	selectImage(FluoImages[0]);
	// iterate to 3D manager window to collect individual values
	for(i=0;i<Nb_of_objects;i++){
		 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
		 ch1_mgv=Array.concat(ch1_mgv,mgv);
	}
	// Save the full quatification table	
		Ext.Manager3D_Quantif();
		Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[0]+"_"+Type_tag+".txt");
		Ext.Manager3D_CloseResult("Q");

	if (FluoImages.length>1) {
		selectWindow(FluoImages[1]);	
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch2_mgv=Array.concat(ch2_mgv,mgv);
		}
	// Save the full quatification table	
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[1]+"_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("Q");
	}

	if (FluoImages.length>2) {
		selectWindow(FluoImages[2]);
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch3_mgv=Array.concat(ch3_mgv,mgv);
		}
	// Save the full quatification table	
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[2]+"_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("Q");
	}		
	
	if (FluoImages.length>3) {
		selectWindow(FluoImages[3]);
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch4_mgv=Array.concat(ch4_mgv,mgv);
		}
	// Save the full quatification table	
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[3]+"_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("Q");
	}

	if (FluoImages.length>4) {
		selectWindow(FluoImages[4]);
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch5_mgv=Array.concat(ch5_mgv,mgv);
		}
	// Save the full quatification table	
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[4]+"_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("Q");
	}
		if (FluoImages.length>5) {
		selectWindow(FluoImages[5]);
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch6_mgv=Array.concat(ch6_mgv,mgv);
		}
	// Save the full quatification table	
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[5]+"_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("Q");
		}
		if (FluoImages.length>6) {
		selectWindow(FluoImages[6]);
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch7_mgv=Array.concat(ch7_mgv,mgv);
		}
// Save the full quatification table	
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[6]+"_"+Type_tag+".txt");
	Ext.Manager3D_CloseResult("Q");
	
	}
		if (FluoImages.length>7) {
		selectWindow(FluoImages[7]);
		for(i=0;i<Nb_of_objects;i++){
			 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
			 ch8_mgv=Array.concat(ch8_mgv,mgv);
		}
// Save the full quatification table	
	Ext.Manager3D_Quantif();
	Ext.Manager3D_SaveResult("Q",TXT_Dir + File.separator + tag+"-"+ BaseName+"_SegObjobj_"+channels_names[7]+"_"+Type_tag+".txt");
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
	NameSplit=split(filename,".");
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
