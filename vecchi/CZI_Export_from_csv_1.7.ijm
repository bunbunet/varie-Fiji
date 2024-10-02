//@ File (label="czi directory", style = "directory") dir
//@ File (label="Output directory_(parent)", style = "directory") OutDir
//@ Boolean (label="Save splitted MAX projections", value=true) save_SplitAndMAX
//@ Boolean (label="Save processed stack", value=false) save_stack_as_tiff
//@ Boolean (label="Save un-processed stack", value=false) save_unprocessedstack_as_tiff
//@ File (label="Unprocessed Stack_Output directory", style = "directory") UnprStack
//@ Boolean (label="Save individual z planes", value=false) sequence


// This script allow to extract from CZI axioscan files as specified in a csv file (tab separated) structured as follows:
//czi	AutomaticZ	Series_Number	firstZ	z	scale	Pyramid	specimen	tag	Channels	LUTs
	// czi: name of the czi file with extension (.czi)
	// AutomaticZ: true/false value specifying wheter the numbering of the sections (z-level) can be assigned automatically
	// Series_Number: number of cutted series, it is used to calculate section numbering
	// firstZ: number (z-level) of the first section.
	// z: list of section numbers (separated by ,) to be used in case sections are not in order, hence AutomaticZ is set to false
	// scale: scale factor to apply to the exported images
	// Pyramid: Pyramid level pre-baked in the czi file (set 1 for full resolution images)
	// specimen: Name of the specimen, it is used as the containing folder of exported images and to compose their names
	// tag: user defined tag added after the z-level, at the end of the file name.
	// Channels: Names of the antigens in each channel (in order and separated by ,)
	// LUTs: Names of the LUTs to be assigned to the different channels, associated by their order and separated by ,
		
// Different export types can be chosen. In general the files are divided by specimen names creating (if not already existing) the following folders hierarchy:
// Specimen name-|
//		      MAX---|
//			  Stack---|
				

// NOTE: Proper pyramid selection take advantage from the fact that pyramids from different scenes are in descending order 
// The macros thus interpret an increas in the size of the images as change of scene in the seires of series (can make mistakes!).
// for further information please contact federico.luzzati@unito.it

//----------------------------------------DEFINE PRE-PROCESSING FILTERS-----------------------------------------------------

//Set the processsing of the images. (comment out the processing steps (not the whole function!) to skip)
function processImages() {
	run("Subtract Background...", "rolling=50 disable stack"); 
	run("Unsharp Mask...", "radius=2 mask=0.60 stack"); 
}
//NOTE: Processing of individual channels should be better performed with dedicated functions, as the macro already split the channels

//----------------------------------------MACRO CODE-- no further user difined options required-------------------------------
AutomaticSeries=true;
run("Clear Results");
	call("java.lang.System.gc");
// open the csv as a result table
ReadCsv();
print("Files to process: " + nResults);

// Inizialize two Arrays to store the name of single focal planes and their z position
// At the end of the macro these array are printed in a csv file that can be used to import these focal planes into TrakEM2, for simplicity these files are not divided into individual specimens
// 
Fname=newArray;
Zlayer=newArray;

setBatchMode(true);
// Start processing .czi files listed in the csv files
for (line = 0; line < nResults; line++) {
	
	// Extract czi details from the  result table (obtsained from the csv file)
	czi=getResultString("czi", line);
	AutomaticZ=getResultString("AutomaticZ", line);
	firstZ=getResult("firstZ", line);
	SeriesN=getResult("Series_Number", line);
	z=getResultString("z", line);
	scale=getResultString("scale", line);
	Pyramid=getResult("Pyramid", line);
	specimen=getResultString("specimen", line);
	tag=getResultString("tag", line);
	Channels=getResultString("Channels", line);
	LUTs=getResultString("LUTs", line);
	print("processing: "+ czi);	
	
	// convert lists to arrays (must be separated by ",")
	z=split(z, ",");
	channel_names=split(Channels, ",");
	LUT_names=split(LUTs, ",");
	
	//Set the path to the czi file
	path=dir + File.separator + czi;
	if(File.exists(path)) {
	
	//---------------------CREATE SPECIMEN'S AND IMAGE TYPE SPECIFIC FOLDERS----------------------------------
	
	// If already present they will be not overwritten, but simply used
	//Note: makeDirectory function can create only one directory at the time, to build a nested path you should run it multiple times sequentially

	SpecimenFolder=OutDir+File.separator+specimen;
	File.makeDirectory(SpecimenFolder);
	Zdir = SpecimenFolder+File.separator+"MAX";
	File.makeDirectory(Zdir);
	print("ZDir: "+Zdir);
	
	if (sequence==true) {
		dir2 = OutDir+File.separator+specimen+File.separator+"Sequence";
		print(dir2);
		File.makeDirectory(dir2);
	}
	if (save_stack_as_tiff==true){
		Stack_Tiff = OutDir+File.separator+specimen+File.separator+"Stack_Tiff";
		print(Stack_Tiff);
		File.makeDirectory(Stack_Tiff);
	}

	//----------------------------------OPEN CZI AND EXTRACT SERIES---------------------------

	//intialize the czi file
	run("Bio-Formats Macro Extensions");
	Ext.setId(path);
	Ext.getCurrentFile(file);
	print("Processing:"+file);
	Ext.getSeriesCount(seriesCount);
	print (seriesCount + " series");
	
	//Initialize an array to store the dimension in pixel of each series
	sizeXs=newArray();
	
	for (i = 0; i < seriesCount; i++) {
		Ext.setSeries(i);
		Ext.getSizeX(sizeX);
		Ext.getSeriesName(name);
		// macro and label are excluded 
		if(!matches(name, ".*macro image.*")||!matches(name, ".*label image.*")){
		sizeXs=Array.concat(sizeXs,sizeX);
		}
	}	
	if(AutomaticSeries==true){
		Series_to_export=newArray();
		length=sizeXs.length;
		sizeXs=Array.concat(0,sizeXs);
		
		// select the pyramid level in the sequence
		for (j = 0; j <length ; j++) {
			if(sizeXs[j+1]>sizeXs[j]){
				Series_to_export=Array.concat(Series_to_export,j+Pyramid);
			}
		}
	}
	
	if (AutomaticZ=="TRUE"){
		//Calculate the z levels for each exported series
		z=newArray();
		for (h=0; h<Series_to_export.length; h++) { 
			z=Array.concat(z,firstZ);
			firstZ=firstZ+SeriesN;
		}
	}
	// The number of series to export sometimes exceed the specified Z
	z=Array.concat(z,"x1");
	z=Array.concat(z,"x2");
	z=Array.concat(z,"x3");
	for (i = 0; i <(Series_to_export.length-1); i++) {
		print("Preparing export of series:"+ Series_to_export[i]+ " as z"+z[i]);
	}
		
	//--------iterate through the series to extract and save the select ones-------------
	for (s=0; s<Series_to_export.length-1; s++){
		//Ext.setSeries(Series_to_export[s]);	
		print("Exporting series:" +Series_to_export[s]+" z:"+z[s]);
		//Ext.openImagePlus(path);
		run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+Series_to_export[s]);	
		imgName=specimen+"_z"+z[s]+"_"+tag;
		rename(imgName);
		if (scale!=1){
			run("Scale...", "x="+scale+" y="+scale+" z=1.0 interpolation=Bilinear average create");
		} 
	    getDimensions(width, height, channels, slices, frames);
	    print(imgName);
	    print("Channels:"+channels);
	    print("Slices"+slices);
	    
	    // Extract the _z value from the file name
		zString = getSubstring(imgName, "_z", "_");
		zValue = NaN; //or whatever to tell you that you could not read the value
		if(zString!="") {
			zValue=parseInt(zString); //parseFloat if not always an integer value
				 }
		if (save_unprocessedstack_as_tiff==true){
	          	saveAs("TIF", UnprStack+File.separator+imgName+".tif");
	          	rename(imgName);	 
	          }
	    print("Filtering");      			 
		processImages();
		if (save_stack_as_tiff==true){
	          	saveAs("TIF", Stack_Tiff+File.separator+imgName+".tif");
	          	rename(imgName);
	          }	
	    if (save_SplitAndMAX==true){	 
		//Split channels and save MAX and/or image sequence for each channel	
		run("Split Channels");		 	     	
		for(c=0; c<channels; c++){
	          selectWindow("C"+c+1+"-"+ imgName);
	          run(LUT_names[c]);
	          // for single channel images theres no need to have MAX projection, files will still be saved into MAX folder 
		      if (slices==1){
	             	saveAs("tif", Zdir+File.separator+channel_names[c]+"-"+imgName+".tiff");
	         			 close();
	         			 call("java.lang.System.gc");	 
	          } 
	          else {
	          //MAX PROJECTIONS
			        run("Z Project...", "projection=[Max Intensity]");
			        saveAs("tif", Zdir+File.separator+channel_names[c]+"-"+imgName+"MAX.tiff");
			        close(); // close the MAX projection
			        call("java.lang.System.gc");
			        if (sequence ==true){
			  //IMAGE SEQUENCE
				  		selectWindow("C"+c+1+"-"+ imgName);
					 	for (j=1; j<=slices; j++){
				 				run("Make Substack..."," slices="+j); 
				  				saveAs("tif", dir2+File.separator+imgName+"_"+IJ.pad(j, 3)+".tiff");
				  				// The file name and z lavel of each focal plane are added to arrays. 
				  				// The z spacing is calculated by dividing 1 / total number of focal planes.
				    			Fname=Array.concat(imgName+"_"+IJ.pad(j, 3)+".tiff",Fname);
				    			Zlayer=Array.concat(zValue,Zlayer);
				    			zValue=zValue+(1/slices);
				  				close();
			 			   		}  
			 				}
			 				
	             }
	             //close(); // Current selected splitte channel  it gave errors sometimes at the end of the processed czi
		}
	  }
	run("Close All");
	call("java.lang.System.gc");
	}
	}
	else{
		print("File not Found");   
	}
	run("Close All");
	call("java.lang.System.gc");
}

run("Clear Results");
//print the table of individual planes names and z levels for trakEM2 import
for (i = 0; i < Fname.length; i++) {
					setResult("name", i, Fname[i]);
	    			setResult("X", i, "0");
	    			setResult("Y", i, "0");
	    			setResult("Z", i, Zlayer[i]);
				 }
saveAs("Results", OutDir+File.separator+"Image_Sequence.csv");
print("Done!"); 



// ----------------------------Function that find a string-----------------------------
function getSubstring(string, prefix, postfix) {
   start=indexOf(string, prefix)+lengthOf(prefix);
   end=start+indexOf(substring(string, start), postfix);
   if(start>=0&&end>=0)
     return substring(string, start, end);
   else
     return "";
}

// ----------------------Function that Open csv as result Table--------------
function ReadCsv() {

     lineseparator = "\n";
     cellseparator = "\t";

     // copies the whole RT to an array of lines
     lines=split(File.openAsString(""), lineseparator);

     // recreates the columns headers
     labels=split(lines[0], cellseparator);
     if (labels[0]==" ")
        k=1; // it is an ImageJ Results table, skip first column
     else
        k=0; // it is not a Results table, load all columns
     for (j=k; j<labels.length; j++)
        setResult(labels[j],0,0);

     // dispatches the data into the new RT
     run("Clear Results");
     for (i=1; i<lines.length; i++) {
        items=split(lines[i], cellseparator);
        for (j=k; j<items.length; j++)
           setResult(labels[j],i-1,items[j]);
     }
     updateResults();
}




