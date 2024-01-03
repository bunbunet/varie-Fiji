//@ File (label = "Input directory", style = "directory") input

list = getFileList(input);

function ColorChannels() {
	Stack.setChannel(1);
	run("Green");
	Stack.setChannel(2);
	run("Red");
	Stack.setChannel(3);
	run("Magenta");
	//Stack.setChannel(4);
	//run("Cyan");
}

setBatchMode(true); 
for (i=0; i<list.length; i++) {
	if(endsWith(list[i], ".tif")) {
		open(input+File.separator+list[i]);
		img=getTitle();
		ColorChannels();			    
		saveAs("tif",input+File.separator+img);
		run("Close All");    
   		} 
 	}