//@ File (label = "Input directory", style = "directory") dir
//@ int(label="number of planes", value=2) n_planes

// This Macro allow to draw and save ROIs for multiple areas in all images in a folder 
// Add the name of the areas that you want to draw in the array list (between "" and separated by commas)

CSV_Dir=dir+File.separator+"CSV"
File.makeDirectory(CSV_Dir);

n_rows =newArray(0.125,0.375,0.625,0.875);
n_cols =newArray(0.25,0.75);

run("Brightness/Contrast...");
waitForUser("SAVE ALL UNSAVED CHANGES TO ROIs") ;


channel_names=newArray("Ki67","SOX9","SOX2","DCX");
run("Set Measurements...", "mean redirect=None decimal=4");

list = getFileList(dir);
print(dir);
print(list.length);
//Array.print(list);
for (i = 0; i < list.length; i++) {
	 if (endsWith(list[i], ".tif")){
	 	 print(i + ": " + dir+list[i]);
         open(dir+File.separator+list[i]);
         getDimensions(width, height, n_channels, slices, frames);
		 Stack.setDisplayMode("composite");
        // Initialize Arrays to store results
         section=newArray();
		 Channels=newArray();
		 Groups=newArray();
		 Specimens=newArray();
		 AnimalIds=newArray();
		 MGVs=newArray();
			// Extract slice details from the filename
			// Names are expectd to be composed by: ExperimentalGroup.ID_Region_zLevel_pz_ other stuff
			// e.g. Healthy.7_STRdx_z87_pz3_c2r1_2nd Round_merging.lif_1.tif
			tit = getTitle();
			splittedName=split(tit, "_");
			Specimen=splittedName[0];
			splittedAnimal=split(splittedName[0],".");
			Group=splittedAnimal[0];
			AnimalId=splittedAnimal[1];

         roiManager("reset");        
		 Original_image =getImageID();
		 for (c =0; c<n_cols.length; c++) {
		 	for (r =0; r<n_rows.length; r++){
		 		for (p =0; p<n_planes; p++) {
					makeRectangle(parseInt(width*n_cols[c]), parseInt(height*n_rows[r]), 80, 80);
					waitForUser("Move the contour than click OK");
					roiManager("Add");
		 			} 
		 		}
		 	}
		 roiManager("save", dir+ File.separator +tit+"_ROIs.zip") ;

		for (ch = 1; ch < n_channels+1; ch++) {
			channel=channel_names[ch-1];
			for (n=0; n<roiManager("count");n++) {
		 		roiManager("select", n);
		 		Stack.setChannel(ch);
		 		roiManager("Update");
		 		run("Clear Results");
		 		run("Measure");		 		
		 		section=Array.concat(section,tit);
				Channels=Array.concat(channel,Channels);
				Groups=Array.concat(Group,Groups);
				Specimens=Array.concat(Specimen,Specimens);
				AnimalIds=Array.concat(AnimalId,AnimalIds);
		 		MGV=getResult("Mean", 0);
		 		MGVs=Array.concat(MGV,MGVs);		 	
			 }	
		}
		
		for (r=0; r<section.length; r++){
			setResult("Section", r, section[r]);	
	  	 	setResult("GroupM", r, Groups[r]);
			setResult("Specimen", r, Specimens[r]);
			setResult("AnimalId", r, AnimalIds[r]);
			setResult("Antigen", r, Channels[r]);
			setResult("MGV", r, MGVs[r]);
		 }
		 saveAs("Results", CSV_Dir+File.separator+tit+"_Background.csv");
		 close();
	}
}


