/*
 * This macro convert in Tiff all the series of a lif files containing the string "Merging" or other tag in their names present in a folder or a folder hierarchy
 * and save the extracted tiff in the output folder or folder hierarchy. If the name of the specimen is separated by an underscore (Specimen.2_restOfTheNane), 
 * outputs can be saved in a folder with that name, chek the boolean variables for each option
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ Boolean (label="Save MAX", value=false) save_MAX
#@ Boolean (label="Save Metadata", value=false) save_metadata
#@ Boolean (label="Recreate Folder Hierarchy", value=false) recreate_hierarchy
#@ Boolean (label="Divide Specimens into folders (specimen name separated by _ )", value=true) divide_in_folders
#@ String (label = "Pattern in series name", value = "Merging") pattern

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
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], ".lif"))
			processFile(input, output, list[i]);	
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	path=input + File.separator + file;
	Ext.setId(path);
	Ext.getCurrentFile(file);
	Ext.getSeriesCount(seriesCount);
	//Ext.getSeriesName(seriesName);
	
	// Store the filename
	filename=File.nameWithoutExtension;

	// replaces the input folder name (string) with the output folder name (string)
	saveDir=output;
	if(recreate_hierarchy){
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
	print ("number of series:" + seriesCount);
	for (s=0; s<seriesCount; s++) {
		Ext.setSeries(s)
		Ext.getSeriesName(name);
		print(s+" "+name);
		//SAVE THE METADATA
		if(save_metadata==true){
			run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=XYCZT series_");
			META_Dir=saveDir+File.separator+"Metadata";
			File.makeDirectory(META_Dir);
			saveAs("Text", META_Dir + File.separator + filename+"_"+name+"txt");
			close("*.txt");
		}
		// SAVE SERIES MATCHING THE NAME PATTERN
		if (matches(name, ".*"+pattern+".*")) {
			run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
			Title=getTitle();
			
			// SAVE STACK
			print("Saving to: " + saveDir);
			Stacks_Dir=saveDir+File.separator+"Stacks";
			File.makeDirectory(Stacks_Dir);
			saveAs("TIFF", Stacks_Dir +File.separator+ Title +"_"+s+1);
			
			// SAVE MAX
			 if (save_MAX==true){
			 	MAX_Dir=saveDir+File.separator+"MAX";
			 	File.makeDirectory(MAX_Dir);
						getDimensions(width, height, channels, slices, frames);
						if(slices==1){
							saveAs("TIFF", MAX_Dir + File.separator + Title +"_single slice.tif");
						}
						else{
							run("Z Project...", "projection=[Max Intensity]");
							saveAs("TIFF", MAX_Dir + File.separator + Title +"_MAX.tif");						
						}
					
				}			
			}
		run("Close All");
		call("java.lang.System.gc");
	}
}