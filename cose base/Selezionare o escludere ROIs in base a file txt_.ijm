
Atlas_Dir="C:/Users/feder/Documents/prove"

areas_to_exclude=split(File.openAsString(Atlas_Dir+File.separator+"areas_to_exclude.txt"), ",");
// DO NOT FORGET TO ADD A , ALSO AT THE END OF THE LAST ITEM

newImage("Untitled", "8-bit black", 100, 100, 1);
makeRectangle(10, 10, 10, 10);
Roi.setName("caz");
roiManager("add");

makeRectangle(20, 20, 20, 20);
Roi.setName("in");
roiManager("add");

makeRectangle(40, 40, 40, 40);
Roi.setName("cul");
roiManager("add");


print("ROIs not excluded");
for (i = 0; i < roiManager("count"); i++) {
	roiManager("select", i);
	Region_index=Roi.getName;
	if (!contains(areas_to_exclude,Region_index)) {
		print(Region_index);
		//roiManager("delete");
	}
}


function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}