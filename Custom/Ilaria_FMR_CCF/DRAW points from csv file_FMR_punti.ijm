//Path to CSV and Images
var Csv_path="C:/Users/Carola.Eva/Documents/PNN_analysis_R/Fmr_PNN_p60/PV-PNN_coordinates_csv";
Image_path="D:/Fmr1 P60 Whole-brain/Fluo_MAX";

run("Clear Results");
roiManager("reset");

// Circle size in microns

// This Macro Drow points based on names and coordinates of a csv file
// Csv file is expected to include coordinates in columns named X,Y,Z and point name in a column named ROI

getPixelSize(unit, pixelWidth, pixelHeight);
circle_size=10/pixelWidth;
WFA_Name=getTitle();
BaseName=replace(WFA_Name, "WFA-", "");
BaseName=replace(BaseName, ".tif", "");
BaseName2=replace(BaseName, "quickNII", "QuickNII");
CsvName=BaseName+"_PV.PNN.objects.csv"

print(pixelWidth);

Csv_path = Csv_path + File.separator  + CsvName
print(Csv_path);
ReadCsv();
setBatchMode(true);

for(i=0;i<nResults;i++){
		//Stack.setSlice(getResultString("Z", i));
		name= getResultString("ROI_Name", i);
		X = getResult("X", i);
		Y = getResult("Y", i);
			makePoint(X, Y);
			roiManager("add");
			roiManager("select", i);
			roiManager("rename", name);	
		}
setBatchMode(false);

run("ROI Manager...");
roiManager("Show All");
waitForUser;


open(Image_path + File.separator + "PV-" + BaseName + ".tif" );
PV_Name=getTitle();
run("Merge Channels...", "c1="+WFA_Name+" c2="+PV_Name+" create");
roiManager("Show All");

function ReadCsv() {

     lineseparator = "\n";
     cellseparator = ",";

     // copies the whole RT to an array of lines
     lines=split(File.openAsString(Csv_path), lineseparator);

     // recreates the columns headers
     labels=split(lines[0], cellseparator);
     if (labels[0]==" ")
        k=1; // it is an ImageJ Results table, skip first column
     else
        k=0; // it is not a Results table, load all columns
     for (j=k; j<labels.length; j++)
        setResult(labels[j],0,0);

     // dispatches the data into the new RT
     run("Clear Results");
     for (i=1; i<lines.length; i++) {
        items=split(lines[i], cellseparator);
        for (j=k; j<items.length; j++)
           setResult(labels[j],i-1,items[j]);
     }
     updateResults();
}