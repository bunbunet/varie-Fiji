//This macro extract labels form Ilastik segmentation and create individual objects
// Sometimes in the 16-bit images the segmented objects could be not visible
// Adjust brightness and contrast to show it up. 

dir = getDirectory("Choose a Directory to seave extracted labels"); 

run("Select None");

// get the number of labels (the maximum gray value)
getStatistics(area, mean, min, max, std, histogram);
Labels= max
print("Number of labels:"+Labels);

//uncomment this line to manually define the number of labels
//Labels=4;

title=getImageID();

//process labels one at the time
for (i = 1; i <= Labels; i++) {
	roiManager("reset");
	run("Clear Results");
	selectImage(title);
	run("glasbey");
	run("Select Label(s)", "label(s)="+i+"");
	img1=getImageID();
	
	//Binarize the image
	setThreshold(i, i);
	run("Convert to Mask", "method=Default background=Dark black");	
	Name=getString("Object name", " ");
	waitForUser("Adjust the segmentation and click ok");
	
	//Choose whether to save the binary image or select specific objects
	Connected_Components=getBoolean("Do you want to perform Connected Components Labelling ?");
	if(Connected_Components==false){		
		saveAs("tiff", dir+Name+"_"+title+"_"+i);
		close(img1);	
	}
	//Connected Components Analysis
	else{
		run("Connected Components Labeling", "connectivity=6 type=[16 bits]");
		img2=getImageID();
		run("glasbey");
		setTool("multipoint");
		run("Select None");
		run("Set Measurements...", "mean redirect=None decimal=4");
		waitForUser("Select the objects with points");
		roiManager("Add");
		roiManager("Measure");
	
		//Set an array to store the labels identified by each point
		Object=newArray();	
		for (j = 0; j < nResults(); j++) {
			    mean = getResult("Mean", j);
			    Object=Array.concat(mean, Object);
			}
		print("number of points:" + Object.length);
	
		//create a single string with the labels
		labels=String.join(Object, ",");
					
		print("labels:"+labels);		
		run("Select Label(s)", "label(s)="+labels+"");
		img3=getImageID();
		run("8-bit");
		setMinAndMax(0, 0);
		run("Apply LUT", "stack");
		//run("Duplicate...", "duplicate");
		//run("Options...", "iterations=6 count=3 black do=Close stack");
		//run("Fill Holes", "stack");
		saveAs("tiff", dir+Name+"_"+title+"_"+i);
		close(img1);
		close(img2);
		close(img3);
		}
}

