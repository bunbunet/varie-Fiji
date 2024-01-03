// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @String(label = "File extension", value = ".czi") suffix
// @String(label = "Added suffix", value = "_25perc") Suff
// @String(label = "Series number (0=100%, 1=50%, 2=25%, 3=12,5%)", value = "2") Series

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
	open(input + File.separator + img);
	print("Processing: " + input + File.separator + img);
	saveDir = replace(input, inputDir, outputDir); // replaces the input folder name (string) with the output folder name (string)
	File.makeDirectory(saveDir); // makes the above directory
	Title=getTitle();
	getStatistics(area, mean, min, max, std, histogram);
	// process only files that are not empty
	if (max>0){
		run("Scale...", "x=0.5 y=0.5 width=480 height=400 interpolation=Bilinear average create");
		print(Title);
		saveAs("TIFF", saveDir + Title + Suff);
		}
	}
}
