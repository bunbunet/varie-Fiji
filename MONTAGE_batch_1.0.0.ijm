/*
 * This macro convert in Tiff all the series of a lif files containing the string "Merging" in their names present in a folder or a folder hierarchy
 * and save the extracted tiff in the output folder.
 */
#@ File (label = "Input directory", style = "directory") input
#@  File (label = "Output directory", style = "directory") output
#@  String (label = "Subfolder Name_followed by /", value = "Pi_processed/") SubFolderName
#@ int (label = "Montage Number of columns", value = "4") columns
#@  int (label = "Montage Unsharp Radius", value = "30") radius
#@  Float (label = "Montage Unsharp mask*10", value = "7") mask 
#@  String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
run("Bio-Formats Macro Extensions");
setBatchMode(true);

processFolder(input);
print("Done!");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	//print("number of files:"+list.length);
	for (i = 0; i < list.length; i++) {
		//print(list[i]);
		if(list[i]==SubFolderName) {
			path=input + list[i];
			MakeMontage(path,output);
			call("java.lang.System.gc");
			//print(list[i];
		}
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
			call("java.lang.System.gc");
	}
}

function MakeMontage(path, output) {
	list=getFileList(path);
	print("Montage of: " + path);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], suffix)){
			//print(list[i]);
			name=split(list[i], "_");
			ser=split(name[5],"."); //extract the series number
			series_List=Array.concat(series_List,ser[0]);
			PngHead=Array.concat(PngHead,list[i]);
		}
	}

Array.getStatistics(series_List, min, max, mean, stdDev);
series=max; // get the number of seires
mask=mask/10;
title=split(PngHead[1], "_");
title=title[0]+title[1];

section_series = round(lengthOf(list)/series);
rows= round(section_series/columns)+1;
setForegroundColor(0, 0, 0);
setBackgroundColor(0, 0, 0);

MontageDir=output+File.separator+title;
File.makeDirectory(MontageDir);

	for (i = 1; i < series+1; i++) {
		run("Image Sequence...","open=["+path+File.separator+PngHead[1]+"] sort file=series_"+i+".tif");
		run("Make Montage...", "columns="+columns+" rows="+rows+" scale=1 label font=48 use");
		run("Unsharp Mask...", "radius="+radius+" mask="+mask+"");
		run("Brightness/Contrast...");
		//saveAs("tiff", MontDirT+title+"_series_"+i);
		saveAs("jpeg", MontageDir+File.separator+title+"_series_"+i+".jpg");
		//run("Enhance Contrast", "saturated=0.35");
		call("java.lang.System.gc");
		//setMinAndMax(96, 218);
	}
	call("java.lang.System.gc");
  }
}
	
	

