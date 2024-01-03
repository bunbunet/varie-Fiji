//@ File (label = "Input directory", style = "directory") input
//@ File (label = "Output directory", style = "directory") output
//@ String (label = "Pattern in series name", value = "dapi") pattern

// This script assemble a channel that was acquired separately and can be distinguished by a specific pattern added at the end
// of the file name : my_fantastic_image.tif ; my_fantastic_image_dapi.tif

list = getFileList(input);

function ColorChannels() {
	Stack.setChannel(1);
	run("Green");
	Stack.setChannel(2);
	run("Red");
	Stack.setChannel(3);
	run("Magenta");
	Stack.setChannel(4);
	run("Cyan");
}


setBatchMode(true); 
for (i=0; i<list.length; i++) {
	if(endsWith(list[i], ".tif")) {
		// Open Base image (not containing the pattern)
		if (matches(list[i], ".*"+pattern+".*")==false) {
			open(input+File.separator+list[i]);
			img=getTitle();
			baseName=File.nameWithoutExtension;
			print(baseName);
	        
	        // Search the additional channel
	        add_Path=input+File.separator+baseName+"_"+pattern+".tif";
	        if (File.exists(add_Path)) {
	        	print("additional channel found: "+ add_Path);
	        	open(add_Path); 
	        	add=getTitle();
	        	selectImage(img);
		        run("Split Channels");
			    run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=[C3-"+img+"] c4=["+add+"] create");
			    ColorChannels();			    
			    saveAs("tif",output+File.separator+img);
			    run("Close All");    
	        } else{
	        	print("additional channel NOT found: "+ add_Path);
	        }
   		} 
 	  }
} 
     