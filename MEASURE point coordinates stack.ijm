//Export to result table the name and x,y,z coordinates of point selection


count=roiManager("count");
for (i=0; i<count; ++i) {
	roiManager("Select", i);
	name=getInfo("roi.name");
	Roi.getCoordinates(x, y);
	Stack.getPosition(channel, slice, frame);
	setResult("Name", i, name);
	setResult("X", i, x[0]);
	setResult("Y", i, y[0]);
	setResult("Z", i, slice);	
}