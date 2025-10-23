//@ File (label = "Images directory", style = "directory") dir_img
//@ File (label = "ROIs directory", style = "directory") dir_roi
//@ File (label="Output directory", style = "directory") dir_out

// create results directories
dir_csv= dir_out +File.separator+"result_tables_AF"
File.makeDirectory(dir_csv);

waitForUser("SAVE ALL IMAGES AND ROIs") ;

setBatchMode(true);
list = getFileList(dir_img);
for (i = 0; i < list.length; i++) {
	 if (endsWith(list[i], ".tiff")){
	 	 roiManager("reset") ;
	 	 run("Clear Results");
	 	 run("Close All");
	 	 
	 	 print(i + ": " + dir_img+list[i]);
         open(dir_img+File.separator+list[i]);
         Original_image =getImageID();
         getDimensions(width, height, channels, slices, frames);
         tit = getTitle();
         titWext= File.nameWithoutExtension;
         titWext=replace(titWext, "_refMAX", "");
         // extract name and experimental group and section infos
         splittedName=split(tit, "_");
		 Specimen=splittedName[0]+"_"+splittedName[1];
		 print("Specimen: "+Specimen);
		 section=splittedName[3];
         print("Section: "+section);
              
         //------------------------------RESULTS ARRAYS--------------------------------------------------------
	  			var Roi_names=newArray();       // Area of the ROI
	  			var Areas=newArray();           // Area of the ROI final
	  			var Areas_o=newArray();			// Areas of the ROI before the Brigh Points correction
	  			var Ref_MGVs=newArray();	    // Mean Gray Value of Reflections
	  			var Ref_AFs=newArray();			// Area Fraction of the staining (otsu)
               
         run("Set Measurements...", "area mean area_fraction display redirect=None decimal=4");
              
	  	//---------------------------------ANALYSIS-----------------------------------------------------------
	  		
	  		selectImage(Original_image);
	  		run("Subtract Background...", "rolling=50");
	  		setAutoThreshold("Otsu dark");
	  		run("Convert to Mask");
	  		
	  		// measure original area
	  		run("Clear Results");
	  		roiManager("open", dir_roi+ File.separator +titWext+"_original.zip");
	  		for (r = 0; r < roiManager("count"); r++) {
	  			roiManager("select", r);
	  			roiManager("Measure");
	  			area=getResult("Area", r);
	  			Areas_o=Array.concat(Areas_o,area);
	  		}
	  		
	  		roiManager("reset");
	  		roiManager("open", dir_roi+ File.separator +titWext+"_corrected.zip");
	  		
	  		//measure corrected area and collect results
	  		run("Clear Results");
	  		for (r = 0; r < roiManager("count"); r++) {
	  			roiManager("select", r);
	  			Roi_names=Array.concat(Roi_names,Roi.getName);
	  			roiManager("Measure");
	  			area=getResult("Area", r);
	  			Areas=Array.concat(Areas,area);
	  			selectImage(Original_image);
	  			mgv=getResult("Mean", r);
	  			Ref_MGVs=Array.concat(Ref_MGVs,mgv);
	  			af=getResult("%Area", r);
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
				setResult("Ref_MGVsum2", r, Ref_MGVs[r]);
				setResult("Ref_AreaFraction", r, Ref_AFs[r]);
				}
		saveAs("Results", dir_csv+File.separator+titWext+"_AF_Results.csv"); 
			
			run("Close All");
			call("java.lang.System.gc");
			roiManager("reset");
			run("Clear Results");

	  } else {
	  	print("No ROIs were drawn, nothing will be saved");
	  }
}

setBatchMode(false);

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