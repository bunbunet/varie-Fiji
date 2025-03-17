/*
 * This macro extract to Tiff all the series of a lif files, furher allowing o subset them according to a tag in their names (e.g. the string "Merging") 
 * All the files present in a folder or sub-folder are extracted and saved in to an output folder all ogheetr or according to the original folder hierarchy. 
 * An additonal option allow to divide set of images (e.g. Specimens) if the name of the group (specimen) is at he beginning of the lif fiile name and separated by an underscore (Specimen.2_restOfTheNane), 
 * outputs can be saved in a folder with that name, chek the boolean variables for each option. 
 * Multiple image types can be extracted independently, as well as the image metadata.
 * 
 * Created by Federico Luzzati, University of Turin, 2/10/2024 (based on the Fji batch processng template)
 */

#@ String(value="INPUT-OUTPUT AND FOLDERS OPTIONS", visibility="MESSAGE") hints1
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ Boolean (label="Process Subfolders", value=true) ProcessSubfolders
#@ Boolean (label="Recreate Folder Hierarchy", value=false) recreate_hierarchy
#@ Boolean (label="Divide Specimens into folders (specimen name separated by _ )", value=true) divide_in_folders
#@ String (label = "Pattern in series name", value = "Merging") pattern
#@ String(value="OUTPUT TYPES OPTIONS", visibility="MESSAGE") hints2
#@ Boolean (label="Save Metadata", value=false) save_metadata
#@ Boolean (label="Save MAX", value=false) save_MAX
#@ Boolean (label="Save Stack", value=false) save_stack
#@ Boolean (label="Save splitted MAX channels", value=true) save_SplitedMAX
#@ Boolean (label="Save splitted Stack channels", value=true) save_SplittedStack
#@ String(value="SPLITTED CHANNELS NAMES AND COLORS", visibility="MESSAGE") hints3
#@ String (label = "Channels names, separated by comma (,)", value = "Sp8,DCX,Ki67") Channels
#@ String (label = "Channels LUTs, separated by comma (,)", value = "Green,Red,Blue") LUTs

var channel_names=split(Channels, ",");
var LUT_names=split(LUTs, ",");
var outputDir // global variable to be passed to function later
var inputDir 
outputDir = File.getName(output); // retrieves the folder name string of the master input folder selected by the user above
inputDir = File.getName(input);

run("Bio-Formats Macro Extensions");
run("Bio-Formats Macro Extensions");
setBatchMode(true);

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	print("number of files:"+list.length);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]) && ProcessSubfolders){
			processFolder(input + File.separator + list[i]);
			}
		if(endsWith(list[i], ".lif")){
			processFile(input, output, list[i]);
			}
	}
}

function processFile(input, output, file) {
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
	if (divide_in_folders) {
				splittedName=split(filename, "_");
				Specimen=splittedName[0];
				print("Specimen Name="+Specimen);
				saveDir=saveDir+File.separator+Specimen;
				File.makeDirectory(saveDir);
		}
	
	// CREATE FOLDERS ACCORDING TO USER PREFERENCES
	if(save_metadata){
		run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=XYCZT series_");
		META_Dir=saveDir+File.separator+"Metadata";
		File.makeDirectory(META_Dir);
		saveAs("Text", META_Dir + File.separator + filename+".txt");
		run("Close");
		//close("*.txt");
		}
	if (save_MAX) {
		MAX_Dir=saveDir+File.separator+"MAX";
		File.makeDirectory(MAX_Dir);
		}
	if (save_stack) {
		Stacks_Dir=saveDir+File.separator+"Stacks";
		File.makeDirectory(Stacks_Dir);
		}
	if (save_SplitedMAX) {
		MaxSplit_Dir=saveDir+File.separator+"MAX_split";
		File.makeDirectory(MaxSplit_Dir);
		}
	if (save_SplittedStack){
		StacksSplit_Dir=saveDir+File.separator+"Stacks_split";
		File.makeDirectory(StacksSplit_Dir);
		}

	//print ("number of series:" + seriesCount);
	for (s=0; s<seriesCount; s++) {
		Ext.setSeries(s)
		Ext.getSeriesName(name);

		// SAVE SERIES MATCHING THE NAME PATTERN (If any images should be saved)
		if (save_stack|save_MAX|save_SplitedMAX|Stacks_Dir & matches(name, ".*"+pattern+".*")) {
			run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
			Title=getTitle();
			// remove the file extension
			Title=StripExtension(Title);
			orig=getImageID();
			getDimensions(width, height, channels, slices, frames);
			
			ImageName=Title +name+"_"+s+1;
			print("Exporting : " + ImageName);
			if (save_stack) {
				saveAs("TIFF", Stacks_Dir +File.separator + ImageName+".tif");
			}
			
			// SAVE stack and/or MAX as multichannel image
			if(save_MAX){
			  	  if(slices==1){
					saveAs("TIFF", MAX_Dir + File.separator + ImageName +".tif");
				} else {
					run("Z Project...", "projection=[Max Intensity]");
					saveAs("TIFF", MAX_Dir + File.separator + ImageName +"_MAX.tif");
					close();
				}
			}
			// SAVE stack and/or MAX splitted
			if (save_SplitedMAX|save_SplittedStack){
				selectImage(orig);
				if (channels==1) {
				if (slices==1){
			             	saveAs("tif", MaxSplit_Dir+File.separator+channel_names[0]+"-"+ImageName+".tif");
			         			 close();
			         			 call("java.lang.System.gc");	 
			          } else {
			          if (save_SplittedStack) {
			          	saveAs("tif", StacksSplit_Dir+File.separator+channel_names[0]+"-"+ImageName+".tif");
			          		//saveAs("tif", StacksSplit_Dir+File.separator+channel_names[c]+"-"ImageName+".tif");
			          	}
			          //MAX PROJECTIONS
			            if(save_SplitedMAX){
					        run("Z Project...", "projection=[Max Intensity]");
					        saveAs("tif", MaxSplit_Dir+File.separator+channel_names[0]+"-"+ImageName+"_MAX.tif");
					        close(); // close the MAX projection
					        call("java.lang.System.gc");
			            }
			          }
				//Split channels and save MAX and/or image sequence for each channel	
			          }else{
				run("Split Channels");		 	     	
				for(c=0; c<channels; c++){
			          selectWindow("C"+c+1+"-"+ImageName+".tif");
			          run(LUT_names[c]);   
			          // for single channel images theres no need to have MAX projection, files will still be saved into MAX folder 
				      if (slices==1){
			             	saveAs("tif", MaxSplit_Dir+File.separator+channel_names[c]+"-"+ImageName+".tif");
			         			 close();
			         			 call("java.lang.System.gc");	 
			          } else {
			          if (save_SplittedStack) {
			          	saveAs("tif", StacksSplit_Dir+File.separator+channel_names[c]+"-"+ImageName+".tif");
			          		//saveAs("tif", StacksSplit_Dir+File.separator+channel_names[c]+"-"ImageName+".tif");
			          	}
			          //MAX PROJECTIONS
			            if(save_SplitedMAX){
					        run("Z Project...", "projection=[Max Intensity]");
					        saveAs("tif", MaxSplit_Dir+File.separator+channel_names[c]+"-"+ImageName+"_MAX.tif");
					        close(); // close the MAX projection
					        call("java.lang.System.gc");
			            }     
			    	  }
					}
				   }
				  }	  run("Close All");
					  call("java.lang.System.gc");
				}	run("Close All");
					  call("java.lang.System.gc");
			  }			
			}	

print("Done!")

// Strip the last part of the string under the last . (usually the filename)
function StripExtension(string) {
	 string_split=split(string,".");
	string_wExt=string_split[0];
	for (i = 1; i < string_split.length-1; i++) {
		string_wExt=string_wExt+"."+string_split[i];
		}
	return string_wExt;
	}


