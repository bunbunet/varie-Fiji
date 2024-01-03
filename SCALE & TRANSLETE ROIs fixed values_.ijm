// scale ROIs and/or translate them in x,y 

//Define the scale factor
scale_factor=0.25;

//Define the tag to be assigned to scaled ROI
tag="_25perc";

//Define the translation
xTrans=736
yTrans=1624

count=roiManager("count");
for (i=0; i<count; ++i) {
	roiManager("translate", xTrans, yTrans);
}
// Roi are counted before the loop, 
//otherwise the nymber would be continully updated and the loop will go forever!
for (i=0; i<count; ++i) {
	roiManager("Select", i);
	name=getInfo("roi.name");
	//to scale each ROIs in place, relative to its center
	//run("Scale... ", "x="+scale_factor+" y="+scale_factor+" centered");
	//run("To Bounding Box");
	// to scale ROIs relative to the image
	run("Scale... ", "x="+scale_factor+" y="+scale_factor);
	Roi.setName(name+tag);
    roiManager("Add");       
}


