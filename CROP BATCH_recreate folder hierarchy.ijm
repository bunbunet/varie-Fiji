// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @ String(label = "File extension", value = ".tif") suffix
// @String(label = "Added suffix", value = "_crop") Suff
// @ String(value="CROP RECTANGLE PARAMETERS", visibility="MESSAGE") hints1
// @Integer(label = "x", value = "_25perc") x
// @Integer(label = "y", value = "_25perc") y
// @Integer(label = "width", value = "_25perc") width
// @Integer(label = "height", value = "_25perc") height

/*
 * Macro template to process multiple images in a folder
 */

var outputDir // global variable to be passed to function later
var inputDir 
outputDir = File.getName(output); // retrieves the folder name string of the master input folder selected by the user above
inputDir = File.getName(input);

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
	open(input + File.separator + img);
	makeRectangle(x, y, width, height);
	run("Crop");
	Title=File.getNameWithoutExtension(input + File.separator + img);
	saveDir = replace(input, inputDir, outputDir); // replaces the input folder name (string) with the output folder name (string)
	File.makeDirectory(saveDir); // makes the above directory
	saveAs("PNG", saveDir + Title + Suff);
	call("java.lang.System.gc");
	}

// cose da considerare: Se c'è un file tile si potrebbe fargli aprire solo il merging al fondo.. ma bisogna passare da Ext.openImageC:\Users\Federico Luzzati\Documents\Image Analysis\fiji-win64\0_Macros\3D Mapping\Image Processing and Import

