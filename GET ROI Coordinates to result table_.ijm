count=roiManager("count");
for (i=0; i<count; ++i) {
	roiManager("Select", i);
	name=getInfo("roi.name");
	getSelectionBounds(x, y, width, height);
	slice=getSliceNumber();
	setResult("name", i, name);
	setResult("X", i, x);
	setResult("Y", i, y);
	setResult("Z", i, slice);
}