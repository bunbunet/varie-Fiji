// find the index of Left ROI
RoiCrop="Left"
nRois=roiManager("count");
lastROI=nRois;
names=newArray(); // add names to an array to evaluate the presence of the ROIs
for (i = 1; i < nRois; i++) {
	roiManager("select", i);
	name=Roi.getName;
	names=Array.concat(names,name);
	if (name=="Left") {
		print("found at "+i);
		RoiCropIndex=i;
		}
}

if(contains(names, RoiCrop)){// if the Crop ROI is not present skip
	for (i = 1; i < nRois; i++) {
		if(i!=RoiCropIndex){
					roiManager("select",0);
					name=Roi.getName;
					roiManager("select", newArray(0,RoiCropIndex-i));
					roiManager("AND");
				  	if (selectionType()==-1){ // if the crope remove all the area
				  		print(i+"-"+name + " completely removed");
				  		lastROI=lastROI-1; //the total number of ROIs is reduced by 1
				  		//RoiCropIndex=RoiCropIndex-1;
				  	} else {
				  		roiManager("add");
						roiManager("select",lastROI);
						roiManager("rename", name);
				  	}
				  	roiManager("deselect");
					roiManager("select",0); // delete the uncropped ROI
					roiManager("delete");	
				}
	}
} else{
	print(RoiCrop + " ROI Not Found");
}

function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}