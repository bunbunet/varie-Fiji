Rows=3
Columns=5
Base= "ciccio"
vetrino="v1"
pozzetto="pz"
SectionNumber=124
Series=6
Type="Scan"

run("Duplicate...", " ");
setTool("rectangle");
waitForUser("Draw a rectangle around the sections");
setAutoThreshold("Default dark no-reset");
run("Gaussian Blur...", "sigma=8");
//run("Median...", "radius=5");
run("8-bit");
run("Threshold...");
waitForUser("Adjust the threshold");
run("Clear Results");
run("Set Measurements...", "centroid redirect=None decimal=4");
//Set the minimum dimension of the sections
run("Analyze Particles...", "size=4000000-Infinity clear include add");

// This part rename the ROIs based on their relative positions

nRo= roiManager("count");
CentX = newArray(nRo);
CentY = newArray(nRo);
for (i = 0; i < nResults; i++){ 
	x = getResult("X", i);
    y = getResult("Y", i);
    CentX[i]=x;
    CentY[i]=y;
}
Array.getStatistics(CentX, minX, maxX, meanX, stdX);
Array.getStatistics(CentY, minY, maxY, meanY, stdY);
//print("minX:"+minX+";maxX:"+maxX);
//print("minY:"+minY+";maxY:"+maxY);
StepY=(maxY-minY)/(Rows-1);
StepX=(maxX-minX)/(Columns-1);
//print("   StepX: "+StepX);
//print("   StepY: "+StepY);
RangeRw=newArray(Rows+1);	
RangeCl=newArray(Columns+1);
xR=minX-StepX/2;
yC=minY-StepY/2;
RangeRw[0]=xR;
RangeCl[0]=yC;
//print("LimitsY");
//print("   "+RangeRw[0]);
for (i = 1; i < RangeRw.length; i++){
	yC=yC+StepY;
	RangeRw[i]=yC;
	print("Row Limit"+RangeRw[i]);
}
//print("LimitsX");
//print("   "+RangeCl[0]);
for (i = 1; i < RangeCl.length; i++){
	xR=xR+StepX;
	RangeCl[i]=xR;
	//print("    "+RangeCl[i]);
}
for (i=0; i<nRo; i++) {
	roiManager("Select", i);
	for (n=0; n<(Rows); n++){
    		if (RangeRw[n]<CentY[i] && CentY[i]<RangeRw[n+1]){
    			RwRoi=n+1;
    		}}
    for (j=0; j<(Columns); j++){
    		if (RangeCl[j]<CentX[i] && CentX[i]<RangeCl[j+1]){
    			ClRoi=j+1;
    		}}
    roiManager("Rename", Base+"_zX_"+vetrino+"cl"+ClRoi+"rw"+RwRoi+"_"+pozzetto+"_"+Type);
}
roiManager("sort");
nRo= roiManager("count");
for (i=0; i<nRo; i++) {
	roiManager("Select", i);
	oldName=Roi.getName;
	NewName=replace(oldName,"_zX_","_z"+SectionNumber+"_");
	roiManager("Rename",NewName);
	SectionNumber=SectionNumber+Series;
	print(SectionNumber);
}
