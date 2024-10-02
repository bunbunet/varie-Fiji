//@ File (label = "Mulichannel directory", style = "directory") input
//@ File (label = "Additional channel directory", style = "directory") input_add
//@ File (label = "Output directory", style = "directory") output
//@ String (value = "SPECIFY THE PREFIX AND SUFFIX, INCLUDE SEPARATORS (_,-,. etc)", visibility="MESSAGE") hint
//@ String (label = "Suffix of additional channel image", value = "dapi") suffix
//@ String (label = "Prefix of additional channel image", value = "Ki67-") prefix
//@ String (label = "File Format of the additional Channel", value = ".tiff") FileFormat


// This script assemble a channel that was acquired separately and can be distinguished by a specific pattern added at the end
// of the file name : 
// Base  name: my_fantastic_image.tif ;
// suffix  pattern:  Ki67-my_fantastic_image_Object Predictions.tiff
// prefix  patern: dapi-my_fantastic_image.tif

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
	Stack.setChannel(5);
	run("Grays");
}

setBatchMode(true); 
for (i=0; i<list.length; i++) {
	if(endsWith(list[i], ".tif")) {
		open(input+File.separator+list[i]);
		getDimensions(width, height, channels, slices, frames);
		img=getTitle();
		baseName=File.nameWithoutExtension;
		print(baseName);
			
		// search the additional channel
	    add_Path=input_add+File.separator+prefix+baseName+suffix+FileFormat;
	    print("searching: "+ add_Path);

	    if (File.exists(add_Path)) {
	        print("additional channel found");
	        open(add_Path); 
	        add=getTitle();
	        selectImage(img);
		    run("Split Channels");
		        if (channels==1){
		        	run("Merge Channels...", "c1=[C1-"+img+"] c2=["+add+"] create");
		        }
		        if (channels==2){
			    	run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=["+add+"] create");
		        }
		        if (channels==3){
			    	run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=[C3-"+img+"] c4=["+add+"] create");
		        }
		        if (channels==4){
			    	run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=[C3-"+img+"] c4=[C4-"+img+"] c5=["+add+"] create");
		        }
			 ColorChannels();			    
			 saveAs("tif",output+File.separator+img);
			 run("Close All");    
	        } else{
	        	print("additional channel NOT found: "+ add_Path);
	        	run("Close All"); 
	        }
   		} 
 	 }
 	 prin("Done!");

     