// this macro automatically segment zif + nuclei
// to exclude areas from contours, use ALT and draw a second ROI 

di=getDirectory("Choose a Directory");
dir = di+"\\Results\\";
File.makeDirectory(dir);
run("Clear Results");
roiManager("reset")
imgName=getTitle();
Stack.setChannel(1);
run("Grays");
Stack.setChannel(2);
run("Grays");
Stack.setChannel(3);
run("Grays");
run("Duplicate...", "duplicate channels=3");
imgName2=getTitle();
//selectWindow("C3-"+ imgName);
//run("8-bit");
run("Threshold...");
setAutoThreshold("Default");
//setOption("BlackBackground", true);
//setThreshold(50, 255);
waitForUser("Adjust the threshold");



//Image pre-processing
run("Convert to Mask");
run("Despeckle");
run("Fill Holes");
run("Watershed");
setTool("polygon");
waitForUser("Draw granule's contoure and click ok");
roiManager("Add");
roiManager("Save", dir+imgName+"Gr_contour"+".roi");

// Anlyze Particles and measurements 1
run("Analyze Particles...", "size=3-Infinity show=Outlines add");
roiManager("Save", dir+imgName+"_Gr_cells"+".zip");
num=roiManager("count");
print("number of zif cells_" +imgName+":\n"+num);
selectWindow(imgName);
Stack.setChannel(3);
run("Set Measurements...", "area mean centroid integrated redirect=None decimal=4");
roiManager("Measure");
saveAs("Results", dir+ imgName+"_granules" + "_zif"+".csv");
run("Clear Results");
Stack.setChannel(1);
roiManager("Measure");
saveAs("Results", dir+ imgName+"_granules" + "_DAPI"+".csv");
run("Clear Results");
Stack.setChannel(2);
roiManager("Measure");
saveAs("Results", dir+ imgName+"_granules" + "_Calretinin"+".csv");
run("Clear Results");
roiManager("reset");

// Draw second countour
selectWindow(imgName);
Stack.setChannel(2);
setTool("polygon");
waitForUser("Draw internal granule's contoure and click ok");
roiManager("Add");
roiManager("Save", dir+imgName+"GrInt_contour"+".roi");

// Analyze particles and measure 2
selectWindow(imgName2);
roiManager("select",0);
run("Analyze Particles...", "size=3-Infinity show=Outlines add");
roiManager("Save", dir+imgName+"Internal_Gr_cells"+".zip");
selectWindow(imgName);
Stack.setChannel(3);
run("Set Measurements...", "mean centroid integrated redirect=None decimal=4");
num2=roiManager("count");
print("number of internal zif cells "+imgName+":\n"+num2);
roiManager("Measure");
saveAs("Results", dir+ imgName+"_Int_granules" + "_zif"+".csv");
run("Clear Results");
Stack.setChannel(1);
roiManager("Measure");
saveAs("Results", dir+ imgName+"_Int_granules" + "_DAPI"+".csv");
run("Clear Results");
Stack.setChannel(2);
roiManager("Measure");
saveAs("Results", dir+ imgName+"_Int_granules" + "_Calretinin"+".csv");


print("Done!")




