//Thi macro fill the inverse of a ROIs (Background)
//of a segmented image (e.g after analyze particles)
// to fill the objects comment out the run (Make Inverse) lines

setForegroundColor(0, 0, 0);

//loop through all the ROIs
for (i = 0; i <roiManager("count"); i++) {
	roiManager("select",i);
// invert the selection	
	run("Make Inverse");
	roiManager("update");
// fill the selection
	roiManager("Fill");
// re-invert the selection
	roiManager("select",i);
	run("Make Inverse");
	roiManager("update");
}