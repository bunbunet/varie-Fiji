#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "Pattern in series name", value = "_dapi") pattern

// This script assemble a channel that was acquired separately and can be distinguished by a specific pattern added at the end
// of the file name : my_fantastic_image.tif ; my_fantastic_image_dapi.tif

list = getFileList(input);

setBatchMode(true); 
for (i=0; i<10; i++) {
	for(j=0; j<10; i++) {
		// Open Base image (not containing the pattern)
		if (matches(name, ".*"+pattern+".*")==false) {
			print(img);
			open(input+File.separator+input[i]);
			baseName=File.nameWithoutExtension;
	        img=getTitle();
	        // Search the channel
	        if (File.exists(input+File.separator+baseName+pattern) {    
		        run("Split Channels");
				
			    run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=[C3-"+img+"] c4=[C3-"+img+"] create");
			    saveAs("tif",output+File.separator+img);
			    run("Close All");    
   } 
 } 
     