// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @String(label = "File extension", value = ".tif") suffix
// @String(label = "Added suffix", value = "_25perc") Suff

/*
 * Macro template to process multiple images in a folder
 */

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

var outputDir // global variable to be passed to function later
var inputDir 
outputDir = File.getName(output); // retrieves the folder name string of the master input folder selected by the user above
inputDir = File.getName(input);
run("Bio-Formats Macro Extensions");

setBatchMode(true);
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, img) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + img);
	path=input + File.separator + img;
	Ext.setId(path);
	Ext.getCurrentFile(file);
	Ext.getSeriesCount(seriesCount);
	print (list[i]+":" + seriesCount + " series");
	saveDir = replace(input, inputDir, outputDir); // replaces the input folder name (string) with the output folder name (string)
	File.makeDirectory(saveDir); // makes the above directory
	for (s=0; s<seriesCount; s++) {
		//Ext.setSeries(s)
		//Ext.openImagePlus(path);
		//Ext.openImage(list[i], no)
		run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
		Title=getTitle();
		saveAs("TIFF", saveDir + Title + Suff+s+1);
		call("java.lang.System.gc");
	}
}


// cose da considerare: Se c'è un file tile si potrebbe fargli aprire solo il merging al fondo.. ma bisogna passare da Ext.openImageC:\Users\Federico Luzzati\Documents\Image Analysis\fiji-win64\0_Macros\3D Mapping\Image Processing and Import

