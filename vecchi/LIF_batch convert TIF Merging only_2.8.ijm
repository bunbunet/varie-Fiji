/*
 * This macro convert in Tiff all the series of a lif files containing a tag in their names (e.g. the string "Merging") present in a folder or a folder hierarchy
 * and save the extracted tiff in the output folder or folder hierarchy. If the name of the specimen is separated by an underscore (Specimen.2_restOfTheNane), 
 * outputs can be saved in a folder with that name, chek the boolean variables for each option. 
 * Metadata can be saved with or without the images, however METADATA WINDOWS ARE NOT AUTOMATICALLY CLOSED!! BE CAREFUL IF USING THAT OPTION,
 * IF USING THAT OPTION MANUALLY COLSE THE WINDOWS AS THEY POP UP
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ Boolean (label="Save MAX", value=false) save_MAX
#@ Boolean (label="Save Stack", value=false) save_stack
#@ Boolean (label="Save Metadata", value=false) save_metadata
#@ Boolean (label="Recreate Folder Hierarchy", value=false) recreate_hierarchy
#@ Boolean (label="Save splitted MAX channels (instead of merged MAX)", value=true) save_SplitAndMAX
#@ Boolean (label="Divide Specimens into folders (specimen name separated by _ )", value=true) divide_in_folders
#@ String (label = "Pattern in series name", value = "Merging") pattern
#@ String (label = "Channels names, separated by comma (,)", value = "Sp8,DCX,Ki67") Channels
#@ String (label = "Channels LUTs, separated by comma (,)", value = "Green,Red,Blue") LUTs


var channel_names=split(Channels, ",");
var LUT_names=split(LUTs, ",");

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

var outputDir // global variable to be passed to function later
var inputDir 
outputDir = File.getName(output); // retrieves the folder name string of the master input folder selected by the user above
inputDir = File.getName(input);
run("Bio-Formats Macro Extensions");

run("Bio-Formats Macro Extensions");
setBatchMode(true);

processFolder(input);
print("Done!");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	print("number of files:"+list.length);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])){
			processFolder(input + File.separator + list[i]);
			}
		if(endsWith(list[i], ".lif")){
			processFile(input, output, list[i]);
			}
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	path=input + File.separator + file;
	filename=file;
	print("processing: "+filename);
	Ext.setId(path);
	//Ext.getCurrentFile(file);//Gets the base filename used to initialize this dataset
	Ext.getSeriesCount(seriesCount);
	//Ext.getSeriesName(seriesName);
	saveDir=output;
	if(recreate_hierarchy){
		// replaces the input folder name (string) with the output folder name (string)
		saveDir = replace(input, inputDir, outputDir); 
		// makes the above directory
		File.makeDirectory(saveDir);
		}
	if (divide_in_folders==true) {
				splittedName=split(filename, "_");
				Specimen=splittedName[0];
				print("Specimen Name="+Specimen);
				saveDir=saveDir+File.separator+Specimen;
				File.makeDirectory(saveDir);
		}
	//SAVE THE METADATA
	if(save_metadata==true){
		run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=XYCZT series_");
		META_Dir=saveDir+File.separator+"Metadata";
		File.makeDirectory(META_Dir);
		saveAs("Text", META_Dir + File.separator + filename+".txt");
		close("*.txt");
	}
	//print ("number of series:" + seriesCount);
	for (s=0; s<seriesCount; s++) {
		Ext.setSeries(s)
		Ext.getSeriesName(name);

		// SAVE SERIES MATCHING THE NAME PATTERN (If any images should be saved)
		if (matches(name, ".*"+pattern+".*")|(save_stack==true)|(save_MAX==true)) {
			run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
			Title=getTitle();
			print("Saving to: " + saveDir);
			
			// SAVE STACK
			Stacks_Dir=saveDir+File.separator+"Stacks";
			File.makeDirectory(Stacks_Dir);//print("Saving Stacks to: " + Stacks_Dir);
			if (save_stack==true) {
				saveAs("TIFF", Stacks_Dir +File.separator + Title +"_"+s+1);
			}

			// SAVE MAX
			 if (save_MAX==true){
			 	// get the name of the saved image
				ImgName=getTitle();
			 	MAX_Dir=saveDir+File.separator+"MAX";
			 	File.makeDirectory(MAX_Dir);
			 	print("Saving MAX to: " + MAX_Dir);
				getDimensions(width, height, channels, slices, frames);
			// SAVE SEPARATED CHANNELS
				if (save_SplitAndMAX==true){
					//Split channels and save MAX and/or image sequence for each channel	
					run("Split Channels");		 	     	
					for(c=0; c<channels; c++){
				          selectWindow("C"+c+1+"-"+ ImgName);
				          run(LUT_names[c]);
				          // for single channel images theres no need to have MAX projection, files will still be saved into MAX folder 
					      if (slices==1){
				             	saveAs("tif", MAX_Dir+File.separator+channel_names[c]+"-"+Title+".tiff");
				         			 close();
				         			 call("java.lang.System.gc");	 
				          } else {
				          //MAX PROJECTIONS
						        run("Z Project...", "projection=[Max Intensity]");
						        saveAs("tif", MAX_Dir+File.separator+channel_names[c]+"-"+Title+"_MAX.tiff");
						        close(); // close the MAX projection
						        call("java.lang.System.gc");
				    	  }
				}
			 // SAVE ALL CHANNELS TOGHETER
				} else { 
				  	  if(slices==1){
						saveAs("TIFF", MAX_Dir + File.separator + Title +"_single slice.tif");
					} else {
						run("Z Project...", "projection=[Max Intensity]");
						saveAs("TIFF", MAX_Dir + File.separator + Title +"_MAX.tif");
						close();
						call("java.lang.System.gc");
					  }		
				}
			  }			
			}
		
	}
}
print("Done!")