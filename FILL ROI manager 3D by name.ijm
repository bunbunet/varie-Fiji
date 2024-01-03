dir=getDirectory("Choose a Directory")
title=getTitle()

run("Select All");
setForegroundColor(255, 255, 255);
run("Fill", "stack");

for (i = 0; i <roiManager("count"); i++) {
	roiManager("select",i);
	name=getInfo("roi.name");
	if (matches(name, ".*STR.*")){
		setForegroundColor(0, 0, 0);
		roiManager("Fill");
	}
	else if (matches(name, ".*Les.*")){
		setForegroundColor(70, 70, 70);
		roiManager("Fill");		
	}
	else if (matches(name, ".*Healty.*")){
		setForegroundColor(70, 70, 70);
		roiManager("Fill");	
}
saveAs("tif", dir+title+"_Areas"+".tif");