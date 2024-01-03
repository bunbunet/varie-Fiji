#@ File (label="Select stacks directory", style = "directory") img_dir
#@ File (label="Select ROI directory", style = "directory") roi_dir
#@ File (label="Output CSVs directory", style = "directory") csv_dir

// This Macro takes images and corresponding multipoint ROIs of Counted Ki67+ clusters, 
// whose name shoud be IDENTICAL to that of the images but .zip and spits a csv file 
// with all the cells by cluster and a simplified ROI set with the centroid of  the clusters 
// and annotation of cluster Type and if it is BrdU+

out_dir=roi_dir+File.separator+"Cluster ROIs"
File.makeDirectory(out_dir);
//setBatchMode(true);

InputList = getFileList(img_dir);
run("Set Measurements...", "  redirect=None decimal=4");

/*
labels_names
1.	cK BrdU neg
2.	cKD BrdU neg
3.	cK BrdU pos
4.	cKD BrdU pos
5.	Dormant (BrdU pos, Ki67 and DCX neg)
*/

print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
 if (endsWith(InputList[l], ".tif")) { 			
	
	// Open Image and get the base name	
	open(img_dir+File.separator+InputList[l]);
	// rest calibration to have measures in pixels
	run("Properties...", "pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000");
	FluoImage=getImageID();
	tit = getTitle();
	titWext= File.nameWithoutExtension;
	
	// Extract Specimen Name, Z level and Group
	splittedName=split(titWext, "_");
	Specimen=splittedName[0];
	zLevel=splittedName[1];
	splittedAnimal=split(splittedName[0],".");
	Group=splittedAnimal[0];
	
	print("processing: " );
	print("Group: "+ splittedAnimal[0]+ "; ID: "+ splittedAnimal[1] + ", " + "z level: "+zLevel);
	
	// Start analysis
	ROI_path=roi_dir+File.separator+titWext+".zip";
	if(File.exists(ROI_path)) {
		// Inizialize arrays to store the results
		var Cells_X=newArray();
		var Cells_Y=newArray();
		var Cells_Z=newArray();
		var Cells_Type=newArray();
		var Cells_name=newArray();
		//
		var Cluster_ID=newArray(); // Name of the Multipoint object (cluster)
		var Cluster_X=newArray();
		var Cluster_Y=newArray();
		var Cluster_Z=newArray();
		var Cluster_Type=newArray(); // cK, cKcKD or cKD
		var Cluster_B=newArray(); // Brdu poistive or negative
		
		// Open multipoint ROIs		
		roiManager("reset");
		roiManager("Open", roi_dir+File.separator+titWext+".zip");
		// Iterate trough the multipoints
		for (i = 0; i < roiManager("count"); i++) {			
			roiManager("Select", i);
			name=Roi.getName;
			run("Clear Results");
			roiManager("Measure");
			// get individual cluster measurement
			for (r = 0; r < nResults(); r++) {
				   Cells_X =Array.concat(getResult('X', r),Cells_X);
				   Cells_Y =Array.concat(getResult('Y', r),Cells_Y);
				   Cells_Z =Array.concat(getResult("Slice", r),Cells_Z);//Make no sense.. but slices number are strings!
				   Cells_Type=Array.concat(getResult("Counter", r),Cells_Type);
				   Cells_name=Array.concat(name,Cells_name);			   			    
			}

			//calculate centroid
			//Extract the last clusters cells
			Xt=Array.trim(Cells_X, nResults);
			Yt=Array.trim(Cells_Y, nResults);
			Zt=Array.trim(Cells_Z, nResults);
			// Calculate mean
			Array.getStatistics(Xt, min, max, meanX, stdDev);
			Array.getStatistics(Yt, min, max, meanY, stdDev);
			Array.getStatistics(Zt, min, max, meanZ, stdDev);
			// Add means to Clusters
			Cluster_X=Array.concat(meanX,Cluster_X);
			Cluster_Y=Array.concat(meanY,Cluster_Y);
			Cluster_Z=Array.concat(meanZ,Cluster_Z);
			
			//Evaluate Type
			t=Array.trim(Cells_Type, nResults);
			if(contains(t,1)|contains(t,3)){ // check cK presence
				if(contains(t,2)|contains(t,4)){// check cKD presence
					Cluster_Type=Array.concat("cKcKD",Cluster_Type);
				} else {
					Cluster_Type=Array.concat("cK",Cluster_Type);
					}
			}else{
				Cluster_Type=Array.concat("cKD",Cluster_Type);
				}
			if(contains(t,2)|contains(t,4)){// check if it is BrdU+
				Cluster_B=Array.concat("B",Cluster_B);
			}else{
				Cluster_N=Array.concat("B",Cluster_B);
			}
			
			ID=name+"_"+Cluster_Type[0]+"_"+Cluster_B[0];
			Cluster_ID=Array.concat(ID,Cluster_ID);
			
			//print(meanX+","+meanY);
			//Array.print(t);
			//print(ID);	
		}
		
		// Save all cells results
		run("Clear Results");
		
		for(i=0;i<Cells_X.length;i++){
			setResult("Group", i, Group);
			setResult("Animal_id", i, Specimen);
			setResult("zLevel", i, zLevel);
			setResult("ImageName", i, tit);
			setResult("CellType", i, Cells_Type[i]);
			setResult("ID", i, Cells_name[i]);
			setResult("X", i, Cells_X[i]);
			setResult("Y", i, Cells_Y[i]);
			setResult("Z", i, Cells_Z[i]);
			setResult("CellType", i, Cells_Type[i]);		
		}		
		saveAs("Results", csv_dir+File.separator+tit+"_IndividualCells_measurements_.csv");
		
		// Draw centroids and add to ROI manager
		roiManager("reset");
		for(i=0;i<Cluster_ID.length;i++){
			Stack.setSlice(Cluster_Z[i]);
			makePoint(Cluster_X[i], Cluster_Y[i]);
			roiManager("add");
			roiManager("select", i);
			roiManager("rename", Cluster_ID[i]);	
		}
		roiManager("save",out_dir+File.separator+titWext+".zip" );	
	}
	else{
		print("ROI file not found");
	}
 }run("Close All");
}


 	print("Done!");	
 	
	
function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
} 	