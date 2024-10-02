@ File (label="Select stack image") orig //select original 3-channel stack
@ File (label = "Output directory", style = "directory") dir

//draw areas of interest
open(orig);
//waitForUser("SAVE ALL UNSAVED CHANGES TO ROIs") ;
roiManager("reset") ;
setTool("polygon");
tit = getTitle();
Original_image =getTitle();

// Make a Z projection to draw STR areas
run("Z Project...", "projection=[Max Intensity]");

Stack.setChannel(2);
run("Brightness/Contrast...");
run("Enhance Contrast", "saturated=0.3");
MAX= getTitle();
//Draw the STR contour
waitForUser("Draw the STR contour");
roiManager("Add");
roiManager("Select", 0);
roiManager("rename","STR_all");

// Draw also the lesioned areas and substract from whole STR
Spared_ROI=3
Les_ROI=1
waitForUser("Draw the Lesion contour");
roiManager("Add");
roiManager("Select", Les_ROI);
roiManager("rename","STR_les");
roiManager("Select", Les_ROI);
run("Make Inverse");
roiManager("Add");
roiManager("Select", newArray(0,2));
roiManager("AND");
roiManager("Add");
roiManager("Select",Spared_ROI)
roiManager("rename","STR_healthy");
roiManager("save", dir+ File.separator +tit+"_STR_ROIs.zip") ;
close(MAX);