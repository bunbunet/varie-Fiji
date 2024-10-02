// To delete one ROI from another,
// calculate the overlap (AND) between the inverse of the seconf and the first

roiManager("Select", 0);
roiManager("rename","STR_all");

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
 