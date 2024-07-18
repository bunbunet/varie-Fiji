dir=getDirectory("Choose a Directory");
for (i=0; i<roiManager("count"); ++i) {
	roiManager("Select", i);
	name=getInfo("roi.name");
	run("Duplicate...", i);
	run("Flip Horizontally");
        saveAs("Tiff", dir+name+".tif");
        close();
    setResult("name", i, name +".tif");
    getSelectionCoordinates(x, y);
    for (n=0;n<x.length;n++) {
    	setResult("X"+n+1, i, x[n]);
    	setResult("Y"+n+1, i, y[n]);
    
    }           
}