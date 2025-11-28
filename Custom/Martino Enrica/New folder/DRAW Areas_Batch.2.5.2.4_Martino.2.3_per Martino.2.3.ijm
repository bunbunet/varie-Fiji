//@ File (label = "Input directory", style = "directory") dir
//@ File (label="Output directory", style = "directory") dir_out
//@ String(label="Specify the ROIs tag (will be added at the end of the name)", value="MAX_ROIs.zip") tag
//@ Integer(label="Number of planes for the MAX projection") nplanes
//@ Boolean(label="Remove Brightest Pixels?") remove
//@ Integer(label="Lower Threashold for Bright pixels") minAsp


//file names: EAE_PM1_merged_f3_resto.tif
// calculate MGV and Int-Den of individual Chs and sum them
// calculate area fraction of the sum, MGV and int-Den

// This Macro allow to draw and save ROIs for multiple areas in all images in a folder 
// Images can be stack or single plane, MAX projection can be produced checking the "MAX project" option
// For convinience a list of predefined names is presented, however during drawing Areas can be skipped, other names can be added at will.
// Add the name of the areas that you want to draw in the array list called Areas (between "" and separated by commas)

nplanes=nplanes-1

// create results directories
dir_roi= dir_out +File.separator+"ROIs";
dir_csv= dir_out +File.separator+"result_tables"
dir_img= dir_out +File.separator+"Merged_refractions_MAX"
File.makeDirectory(dir_csv);
File.makeDirectory(dir_roi);
File.makeDirectory(dir_img);

waitForUser("SAVE ALL IMAGES AND ROIs") ;

list = getFileList(dir);
for (i = 0; i < list.length; i++) {
	 if (endsWith(list[i], ".tif")){
	 	 roiManager("reset") ;
	 	 run("Clear Results");
	 	 run("Close All");
	 	 
	 	 print(i + ": " + dir+list[i]);
         open(dir+File.separator+list[i]);
         Original_image =getImageID();
         getDimensions(width, height, channels, slices, frames);
         tit = getTitle();
         titWext= File.nameWithoutExtension;
         // extract name and experimental group and section infos
         splittedName=split(tit, "_");
		 Specimen=splittedName[0]+"_"+splittedName[1];
		 print("Specimen: "+Specimen);
		 section=splittedName[3];
         print("Section: "+section);
         
         // Change colors and activate the two reflection channels
        for (k = 1; k <= channels; k++) {
         	Stack.setChannel(k);
         	run("Enhance Contrast...", "saturated=0.5");
         	if(k==1){
         		run("Cyan");
         	} else{
         		run("Grays");
         	}
         }      
         Stack.setActiveChannels("011");
         
         waitForUser("Move to the first slice than click ok") ;
         Stack.getPosition(channel, start, frame);
         
         //------------------------------RESULTS ARRAYS--------------------------------------------------------
	  			var Roi_names=newArray();       // Area of the ROI
	  			var Areas_o=newArray();			// Areas of the ROI before the Brigh Points correction
	  			var Areas=newArray();           // Area of the ROI final
	  			var Dapi_MGVs=newArray();       // Mean Gray Value of DAPI
				var Ref1_MGVs=newArray();	    // Mean Gray Value of Reflection1
				var Ref2_MGVs=newArray();	    // Mean Gray Value of Reflection2
	  			var Ref_AFs=newArray();			// Area Fraction of the staining (otsu)
               
         run("Set Measurements...", "area mean area_fraction display redirect=None decimal=4");
               
         // Draw the section
         run("Duplicate...", "duplicate channels=1");
         temp=getImageID();
         run("Z Project...", "projection=[Max Intensity]");
         setOption("BlackBackground", true);
         setThreshold(2, 255);
         run("Convert to Mask");
		 run("Options...", "iterations=1 count=4 black do=Open");
		 run("Create Selection");
		 roiManager("add");
		 roiManager("select", 0);
		 roiManager("rename", "Section");
		 
		 // Z-projection
         selectImage(Original_image);
         run("Z Project...", "start="+start+" stop="+start+nplanes-1+" projection=[Max Intensity]");
         z_Image=getImageID();
         //Enhance Contrast of the reflections
         for (k = 0; k < channels; k++) {
         	Stack.setChannel(k);
         	run("Enhance Contrast...", "saturated=0.5");  	
         }
         Stack.setChannel(1);
         run("Cyan");
         Stack.setChannel(2);
         run("Grays");
         Stack.setChannel(3);
         run("Grays");
         Stack.setActiveChannels("011");
         roiManager("select", 0);
         
         // User Draw ROIs
		 run("Channels Tool...");
	     setTool("polygon");
         waitForUser("Adjust (or redraw) Section ROI and Draw the White matter (in this order)") ;
	     
	     // Subtract GM for entire
	     roiManager("add");
	     roiManager("select", 1);
	     roiManager("rename", "WM");
	     roiManager("measure");
	     area=getResult("Area", 0);
	     Areas_o=Array.concat(Areas_o,area);
	     And_Xor(0, 1); // Custom function to perform a clean XOR
		 roiManager("select", 0);
		 roiManager("rename", "GM");
		 roiManager("measure");
		 area=getResult("Area", 1);
	     Areas_o=Array.concat(Areas_o,area);


	  // recreate the ugly name of the masks and single channel images
	  nRois=roiManager("count");
	  if(nRois>0){
	  	roiManager("save", dir_roi+ File.separator +titWext+"_"+tag+"original.zip") ;
	  	//---------------------------------ANALYSIS-----------------------------------------------------------
	  		
	  		// Create MAX of Merged Ref1 and Ref2 image (could be done from the z-project but I may try to remove the backgoround in the stack in the future)
	  		selectImage(Original_image);
	  		run("Duplicate...", "duplicate channels=2 slices="+start+"-"+start+nplanes);
	  		Ref1=getImageID();
	  		
	  		selectImage(Original_image);
	  		run("Duplicate...", "duplicate channels=3 slices="+start+"-"+start+nplanes);
	  		Ref2=getImageID();
	  		
	  		imageCalculator("Add create stack", Ref1,Ref2);
	  		Ref3=getImageID();
	  		
	  		run("Z Project...", "projection=[Max Intensity]");
	  		Refm=getImageID();
	  		
	  		//save the merged MAX image
	  		saveAs("tiff", dir_img+ File.separator +titWext+"_refMAX.tiff");
	  		
	  		// close temporary images	
	  		imgC=newArray(Ref1,Ref2,Ref3,Original_image,temp);
	  		for (im = 0; im <imgC.length; im++) {
	  			selectImage(imgC[im]);
	  			close();
	  			}
	  		
	  		// Remove brightest pixels
	  		if(remove){
		  		setThreshold(minAsp, 255);
		  		run("Create Selection");
		  		roiManager("add");
		  		// remove it from the WM and GM ROIs
		  		And_Xor(0,2);
				And_Xor(1,2);
				roiManager("select", 2);
		  		roiManager("delete");
		  		waitForUser("Check the corrected ROIs") ;
	  			}
	  		
	  		// Save the ROIs	
	  		roiManager("save", dir_roi+ File.separator +titWext+"_"+tag+"corrected.zip") ;
	  		
	  		// prepare the Mask for area Fraction
	  		selectImage(Refm);
	  		run("Subtract Background...", "rolling=50");
	  		setAutoThreshold("Otsu dark");
	  		waitForUser;
	  		run("Convert to Mask");
	  		
	  		//measure
	  		
	  		for (r = 0; r < roiManager("count"); r++) {
	  			run("Clear Results");
	  			roiManager("select", r);
	  			Roi_names=Array.concat(Roi_names,Roi.getName);
	  			// Collect MGV values for z-Image
	  			selectImage(z_Image);
	  			Stack.setChannel(1);
	  			roiManager("Measure");
	  			mgv=getResult("Mean", 0);
	  			Dapi_MGVs=Array.concat(Dapi_MGVs,mgv);
	  			Stack.setChannel(2);
	  			roiManager("Measure");
	  			mgv=getResult("Mean", 1);
	  			Ref1_MGVs=Array.concat(Ref1_MGVs,mgv);
	  			Stack.setChannel(3);
	  			roiManager("Measure");
	  			mgv=getResult("Mean", 2);
	  			Ref2_MGVs=Array.concat(Ref2_MGVs,mgv);
	  			// Collect ROI area
	  			area=getResult("Area", 2);
	  			Areas=Array.concat(Areas,area);
	  			
	  			// Collect Area Fraction from Reference merged image
	  			selectImage(Refm);
	  			roiManager("select", r);
	  			roiManager("Measure");
	  			af=getResult("%Area", 3);
	  			Ref_AFs=Array.concat(Ref_AFs,af);
	  		}
	
	run("Clear Results");
	for (r = 0; r < roiManager("count"); r++) {
				setResult("Specimen", r, Specimen);
				setResult("Section.ID", r, section);
				setResult("Region", r, Roi_names[r]);
				setResult("Area", r, Areas[r]);
				PercRemoved=((Areas[r]-Areas_o[r])/Areas_o[r]);
				setResult("AreaPercRemoved", r, PercRemoved);
				setResult("DAPI_MGV", r, Dapi_MGVs[r]);
				setResult("Ref1_MGV", r, Ref1_MGVs[r]);
				setResult("Ref2_MGV", r, Ref2_MGVs[r]);
				setResult("Ref_MGVsum", r, Ref1_MGVs[r]+Ref2_MGVs[r]);
				setResult("Ref_AreaFraction", r, Ref_AFs[r]);
				}
		saveAs("Results", dir_csv+File.separator+titWext+"_Results.csv"); 
			
			run("Close All");
			call("java.lang.System.gc");
			roiManager("reset");
			run("Clear Results");
		
	  } else {
	  	print("No ROIs were drawn, nothing will be saved");
	  }
	}
}

function And_Xor(x, y) {
    roiManager("Select", newArray(x, y));
    roiManager("AND");
    roiManager("Add");
    nr = roiManager("count") - 1;//get the index of the temporary ROI
    roiManager("Select", newArray(x, nr));
    roiManager("XOR");
    roiManager("Update");
    roiManager("Select", nr);
    roiManager("Delete");
}