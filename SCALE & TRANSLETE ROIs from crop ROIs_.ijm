// scale ROIs and/or translate them by the x,y coordinates of the first ROI in the list.
// The transformed ROIs will be appended at the end of the list
// e.g. This Macro can be used to remap ROIs drawn on an image cropped back to the original image,
// just store the crop ROI as the first ROI in the ROI manager

//specify the scale factor
scale_factor=0.25;
// Translate set true
Translate=true

//chose a tag for the transformed ROIs
tag="_25perc";

//count the number of ROIs before looping and stor it into a variable
//otherwise the loop will never stop!
count=roiManager("count");

//Get the position of the croping ROI (the first in the list) in the original image:
roiManager("Select", 0);
getSelectionBounds(xTrans, yTrans, width, height)
print("Translation, X:"+xTrans+", Y:"+yTrans);

//Scale ROIs and rename
for (i=1; i<count; ++i) {
	roiManager("Select", i);
	name=getInfo("roi.name");
	run("Scale... ", "x="+scale_factor+" y="+scale_factor);
	Roi.setName(name+tag);
    roiManager("Add");       
}
//Translate ROIs (automatically update the ROI)
if Translate=true {
	for (i=count; i<roiManager("count"); ++i) {
		roiManager("Select", i);
		roiManager("translate", xTrans, yTrans); 
	}
}	 

