#@ String(value="Directories and File names", visibility="MESSAGE") hint
#@ File (label="Fluorescence Images directory", style = "Directory") Dir
#@ String(label="Channels names, separated by comma (,)") Channels
#@ File (label="Predictions and Identities directory", style = "directory") Mask_dir 
#@ File (label="ROIs Directory", style = "Directory") Atlas_Dir 
#@ File (label="Directory to save Results", style = "directory") Results_dir
#@ String(value="TAGs specifying file types associated to the same section", visibility="MESSAGE") hint2
#@ String(label="Segmentation Prefix") SegTag
#@ String(label="ROIs tag") RoiTag
#@ String(label="Tag of result table") ResTag
#@ String(label="Gray value of the Object Prediction label to analyze (set 0 if absent)") label_value
#@ String(value="Saving Options", visibility="MESSAGE") hint3
#@ Boolean(label="Save Identities Image without objects bearing to other labels") Save_filtered_identities
#@ Boolean(label="Save additiona object morphological features?") Save_object_features

/*
 * This Macro loop through corresponding series of Fluorescenc Images, ROIs and Object Masks to measure object features and Fluorescence intensities within the ROIs. 
 * Analyzed objects must be labels in a 16-bit image inside a set of ROIs. A prediction image with a mask encoding object classes 
 * is accepted, the macro however process only class per run and the user should specify the Gray value of the desired label. 
 * It macro could be easily implemented to process multiple (or all) labelling.
 * Measurements of each ROI-Image-Mask set are saved as tables in independent csv files. 
 * Two outputs are produced: 1) A full list of objects annotated by their position, area and intensity values (MGVs)
 * 							 2) A summary of the number of objects per Area. 
 * 							 
 * File names are expected to include the name of the Specimen and an ID of the image. 
 */


//close all images and release memory from RAM
if(nImages>0){
	waitForUser("Warning! All Images will be closed!");
}
run("Close All");
call("java.lang.System.gc");
run("Clear Results");
roiManager("reset");

// Set a result sub-folder for the list of all objects
FullResults_dir=Results_dir + File.separator + "Full_Obj_tables";
File.makeDirectory(FullResults_dir);

// Array to store lacking image or mask files
fileNotFound=newArray();

run("3D Manager");
// set measurements options, all objects are counted, including those touching the borders (exclude_objects_on_edges_xy is not included)
run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) bounding_box drawing=Contour");

setBatchMode(true);			
									
// Loop through the Atlas ROIs produced by the Macro that analyzed segmentation
list=getFileList(Atlas_Dir);

//-----------------------Loop over ROIs files and check the existence of associated Predictions and Identities---

for (k = 0; k < list.length; k++) {
	print(Atlas_Dir+File.separator + list[k]);
	if (endsWith(list[k], ".zip")) { 
							
		// get Zvalue and specimen name
		roiManager("Open", Atlas_Dir+File.separator+list[k]);
		titWext= list[k];
		BaseName=replace(titWext,"_"+RoiTag+".zip","");
		splittedName=split(BaseName, "_");
		Specimen=splittedName[0];
		print("Specimen: "+Specimen);
		zString = getSubstring(titWext, "_s","_"+ RoiTag);
		zValue = NaN; //or whatever to tell you that you could not read the value
			 if(zString!="") {
	   			zValue=parseInt(zString); //parseFloat if not always an integer value
			 }
		print("Section ID: "+zValue);	 		 		 	
		print("X_X_X_X_X_X_X_X_X_X_X_X_X_X_Processing: " + BaseName + "X_X_X_X_X_X_X_X_X_X_X_X_X_X_X");

//------------ CHECK THE EXISTENCE OF SEGMENTATION MASKS AND FLUORESCENCE IMAGES FILES ----------------------------
								
//Identities and Predictions
		Prediction_Ok=false;
		if (label_value==0) {
			Prediction_Ok=true;
		} else {
			Mask_path = Mask_dir + File.separator +SegTag+"-"+ BaseName + "_Object Predictions.tiff";
			print("SEARCHING: " +SegTag+"-"+ BaseName + "_Object Predictions.tiff");
			if(File.exists(Mask_path)){
				print("Mask file found");
				Prediction_Ok=true;
			}
		}
		
		
			 
		print("SEARCHING: "+SegTag+"-"+ BaseName + "_Object Identities.tiff");
		Ident_Ok=false;
		Ident_path = Mask_dir+File.separator+SegTag+"-"+ BaseName+"_Object Identities.tiff";
		if(File.exists(Mask_path)){
			print("Identities file found");
			Ident_Ok=true;
		}

//FLUORESCENCE IMAGES
		// Open all the fluorescence images with the prefix indicated in the options (expect channels to be written at the beginning of the file name, separated by a "-"
		// according to the scheme: chName-Base name.tif
	
	//Convert user specified channel names into an Array
	channel_names=split(Channels, ",");
	
	//Initialize an Array to store individual channels ID and retreive them by index
	FluoImages=newArray();
	
	//Loop trough the channel names and open the corresponding files
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

//--------------------------------------------- ANALYZE IMAGES -------------------------------------------------------	
			
	if(Ident_Ok==true && Prediction_Ok==true && FluoImages.length>0) {
			
//--------------Initialize arrays to store the number of objects per brain area---------------------------------------
			
			Region_indexes=newArray(); // Atlas Region index (16-bit grayscale value)
			Objects=newArray();       // number of objects in any particular area
			
//-------------- Initialize arrays to store objects properties and measurements ---------------------------------
		
			var Region_indexesObj=newArray(); // Atlas Region index (16-bit grayscale value)
			var SegObj_labels=newArray();     // Objects IDs corresponding to the gray value in the Identity image
			var SegObj_X=newArray();		  // X coordinate
			var SegObj_Y=newArray();		  // Y coordinate
			var Ch1_MGVs=newArray();          // Mean Gray Value of Ch1 stain 
			var Ch2_MGVs=newArray();	      // Mean Gray Value of Ch2 stain 
			var Ch3_MGVs=newArray();	      // Mean Gray Value of Ch3 stain 
			var Ch4_MGVs=newArray();	      // Mean Gray Value of Ch4 stain
			
//--------------------------------------------------------------------------------------------------------------------
						
			// Open Identities and Predictions
			open(Mask_path);
			Predictions=getImageID();
			open(Ident_path);
			Identities=getImageID();
			
			// Erase cells assigned to un-selected labels from the Object Identities Imgege.
			if (label_value>0) {

			selectImage(Predictions);
			setThreshold(label_value, label_value);// Select the label 
			run("Create Selection");
			run("Make Inverse");
			roiManager("reset");
			roiManager("Add");
			selectImage(Identities);
			getDimensions(Original_width, Original_height, channels, slices, frames);
			roiManager("Select", 0);
			setBackgroundColor(0, 0, 0);
			setForegroundColor(0, 0, 0);
			roiManager("Fill");
			roiManager("reset");
			if (Save_filtered_identities==true){
				saveAs("Tiff", Mask_dir + File.separator + BaseName + "_Object Identities PNNonly.tiff");
				}
			}	
			// Save MorpholibJ morphological features
			selectImage(Identities);
			if (Save_object_features==true){
				// Analyze all objects with MorpholibJ
				run("Analyze Regions", "area perimeter circularity euler_number centroid equivalent_ellipse ellipse_elong. convexity max._feret oriented_box oriented_box_elong. tortuosity");
				// Rename the results window to result table
				Table.rename(SegTag+"-"+ BaseName+"_ObjectIdentities-Morphometry", "Results");
				// Add columns to specify specimen and section
				n=nResults;
				for (i = 0; i < nResults(); i++) {
				    setResult("Specimen", i, Specimen);
					setResult("Section.ID", i, zValue);
				}
				updateResults();	
			}
			
			// Measure Objects per Area
			roiManager("Open", Atlas_Dir+File.separator+list[k]);
			count=roiManager("count");
			// Loop trough all brain areas
			for (v=1; v<count; v++) {// !!!! I'll skip the first ROI, that should be the merged image as it would take too long to import it !!! C H E C K   I T   O U T!!!
				selectImage(Identities);
				roiManager("Select", v);
				ROI_name=Roi.getName;
				
				//import in 3D manager objects included in the selected ROI
				Ext.Manager3D_SelectAll();
				Ext.Manager3D_Delete();
				Ext.Manager3D_AddImage();
				Ext.Manager3D_Count(Nb_of_objects);
				Region_indexes=Array.concat(Region_indexes,ROI_name);
				Objects=Array.concat(Objects,Nb_of_objects);
				
				//Loop over objects properties to collect name, volume and position
				for (j = 0; j < Nb_of_objects; j++) {
					//get the measurements
					Ext.Manager3D_Quantif3D(j,"Mean",label); // label gray level - use IntDen, Mean, Min,Max, Sigma
		 			Ext.Manager3D_Measure3D(j,"Vol",vol); // volume
					Ext.Manager3D_Centroid3D(j,cx,cy,cz);
					//store them in the respective arrays
					SegObj_labels=Array.concat(SegObj_labels,label);
					SegObj_volumes=Array.concat(SegObj_volumes,vol);
				 	SegObj_X=Array.concat(SegObj_X,cx);
				 	SegObj_Y=Array.concat(SegObj_Y,cy);
				 	Region_indexesObj=Array.concat(Region_indexesObj,ROI_name);// store the brain area of that measurement
				 	}
				
				//Measure Fluoresce in 1 to 4 channels and iterate in 3D manager result window to collect individual values 	
				selectImage(FluoImages[0]);
				for(i=0;i<Nb_of_objects;i++){
					 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
					 Ch1_MGVs=Array.concat(Ch1_MGVs,mgv);
				}
				
				if (FluoImages.length>1) {
					selectImage(FluoImages[1]);	
					for(i=0;i<Nb_of_objects;i++){
						 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
						 Ch2_MGVs=Array.concat(Ch2_MGVs,mgv);
					}
				}
			
				if (FluoImages.length>2) {
					selectImage(FluoImages[2]);	
					for(i=0;i<Nb_of_objects;i++){
						 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
						 Ch3_MGVs=Array.concat(Ch3_MGVs,mgv);
					}
				}		
				if (FluoImages.length>3) {
					selectImage(FluoImages[3]);	
					for(i=0;i<Nb_of_objects;i++){
						 Ext.Manager3D_Quantif3D(i,"Mean",mgv); // quantification, use IntDen, Mean, Min,Max, Sigma
						 Ch4_MGVs=Array.concat(Ch4_MGVs,mgv);
					}
				}
				 			
			} // END OF BRAIN AREAS ROI LOOP

//----------------------------- SAVE INDIVIDUAL OBJECTS PER AREA--------------------------------------------------------------

				for(i=0;i<Region_indexesObj.length;i++){
					setResult("Specimen", i, Specimen);
					setResult("Section.ID", i, zValue);
					setResult("Region.Index", i, Region_indexesObj[i]);
					setResult("X", i, SegObj_X[i]);
					setResult("Y", i, SegObj_Y[i]);
					setResult("label", i, SegObj_labels[i]);
					
					setResult(channel_names[0] + "_MGV", i, Ch1_MGVs[i]);										
					if(FluoImages.length>1){
						setResult(channel_names[1] + "_MGV", i, Ch2_MGVs[i]);
					}
					if(FluoImages.length>2){
						setResult(channel_names[2] + "_MGV", i, Ch3_MGVs[i]);
					}
					if(FluoImages.length>3){
						setResult(channel_names[3] + "_MGV", i, Ch4_MGVs[i]);
					}
				}
				saveAs("Results", FullResults_dir+File.separator+ BaseName +"_"+ ResTag + "_Count_Objects_full_list.csv");
				run("Clear Results");
				
//---------------------------- SAVE NUMBER OF OBJECTS PER AREA-------------------------------------------

				for(i=0;i<Region_indexes.length;i++){
					setResult("Specimen", i, Specimen);
					setResult("Section.ID", i, zValue);
					setResult("Region.Index", i, Region_indexes[i]);
					setResult(ResTag+"_Number", i,Objects[i]);
				}
				
				saveAs("Results", Results_dir+File.separator+ BaseName +"_"+ ResTag + "_Count_Objects_summary.csv");

		}
		run("Clear Results");
		run("Close All");
		roiManager("reset");
		call("java.lang.System.gc");
			
}}// END OF SECTIONS LOOP 

for(i=0;i<fileNotFound.length;i++){
	setResult("FileName", i, fileNotFound[i]);
}
saveAs("Results", Results_dir+File.separator+"CCF_Count_Objects_"+ResTag+"_FileNotFound.csv");

print("Done!");

//Notes.
//to create a multipoint
//makeSelection(point, xpoints, ypoints);

// save the centroids, use multipoints MakeS
//roiManager("save", Results_dir + File.separator + BaseName + "_"+ ResTag + "_centroids.zip");

//----------------------------------------------------- CUSTOM FUNCTIONS---------------------------------

// This function find a string 
function getSubstring(string, prefix, postfix) {
   start=indexOf(string, prefix)+lengthOf(prefix);
   end=start+indexOf(substring(string, start), postfix);
   if(start>=0&&end>=0)
     return substring(string, start, end);
   else
     return "";
}