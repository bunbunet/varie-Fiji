/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

setBatchMode(true);
dimensions_W=newArray();
dimensions_Y=newArray();
name=newArray();

processFolder(input);
for (i = 0; i <name.length; i++) {
	setResult("Name", i,name[i] );
	setResult("Width", i,dimensions_W[i] );
	setResult("Height", i,dimensions_H[i] );
}


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

function processFile(input, output, file) {
	open(input+File.separator+file);
	title=getTitle();
	getDimensions(width, height, channels, slices, frames);
	dimensions_W=Array.concat(width,dimensions_W);
	dimensions_Y=Array.concat(height,dimensions_Y);
	name=Array.concat(title,name);
	print("Processing: " + input + File.separator + file);
	print("Dimensions:"+width+"x"+height);
	close();
}

