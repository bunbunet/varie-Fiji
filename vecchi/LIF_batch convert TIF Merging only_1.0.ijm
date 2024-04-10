/*
 * This macro convert in Tiff all the series of a lif files containing the string "Merging" in their names present in a folder or a folder hierarchy
 * and save the extracted tiff in the output folder.
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".lif") suffix
#@ String (label = "Pattern in series name", value = "Merging") pattern

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
	print("number of files:"+list.length);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
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
	print ("number of series:" + seriesCount);
	for (s=0; s<seriesCount; s++) {
		Ext.setSeries(s)
		//Ext.openImagePlus(path);
		//Ext.openImage(list[i], no);
		Ext.getSeriesName(name);
		print(s+" "+name);
		if (matches(name, ".*"+pattern+".*")) {
			run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
			Title=getTitle();
			print("Saving to: " + output);
			saveAs("TIFF", output +File.separator+ Title +"_"+s+1);
			call("java.lang.System.gc");
		}
			
	}
}
