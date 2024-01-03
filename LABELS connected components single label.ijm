//This macro extract labels form Ilastik segmentation and create individual objects
// Sometimes in the 16-bit images the segmented objects could be not visible
// Adjust brightness and contrast to show it up. 
dir = getDirectory("Choose a Directory"); 
Labels=255;
title=getImageID();
	selectImage(title);
	run("glasbey");
	run("Select Label(s)", "label(s)="+Labels+"");
	run("Connected Components Labeling", "connectivity=6 type=[16 bits]");
	run("glasbey");
waitForUser("Check object grey value");
	Object=getString("Select Object Value", "");
	run("Select Label(s)", "label(s)="+Object+"");
	run("8-bit");
	setMinAndMax(0, 0);
	run("Apply LUT", "stack");
	run("Duplicate...", "duplicate");
	run("Options...", "iterations=6 count=3 black do=Close stack");
	run("Fill Holes", "stack");
	saveAs("tiff", dir+title+"_");


