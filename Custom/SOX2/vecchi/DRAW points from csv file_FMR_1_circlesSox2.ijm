// This Macro Drow circles or points based on names and coordinates of a csv file
// Csv file is expected to include coordinates in columns named X,Y,Z and point name in a column named ROI

channels_names=newArray("Ki67");

//Path to CSV and Images
var Csv_path="C:/Users/feder/Documents/LAB/ProgettoQA/SOX2/Sox2_J/Export/SOX9_coordinates/";
Image_path="C:/Users/feder/Documents/LAB/ProgettoQA/SOX2/Sox2_J/Export/SOX9_coordinates/SplitChannels/";

// Circle size in microns
circle_size=10;

// set the string contained in ROIs that you want to encircle
CicleType1="SOX9."
CicleType2="DCX."
CicleType3="Ki67."

//----------------------------------------MACRO RUN-------------------------------------------------


run("Clear Results");
roiManager("reset");

getPixelSize(unit, pixelWidth, pixelHeight);
circle_size=circle_size/pixelWidth;
Orig_Name=getTitle();
BaseName=replace(Orig_Name, "DCX-", "");
BaseName=replace(BaseName, ".tif", "");
CsvName=BaseName+".csv"

Csv_path = Csv_path + File.separator  + CsvName
print(Csv_path);
ReadCsv();

setBatchMode(true);
for(i=0;i<nResults;i++){
		//Stack.setSlice(getResultString("Z", i));
		name= getResultString("ROIc", i);
		X = getResult("Xpx", i);
		Y = getResult("Ypx", i);
		Z = getResult("Zpx", i);
		
		if (indexOf(name, CicleType1) != -1) {
			run("Roi Defaults...", "color=yellow stroke=1 group=0");
			Stack.setSlice(Z);
			makeOval(X-(circle_size/2,) (Y-circle_size/2), circle_size/pixelWidth, circle_size/pixelHeight);
			
		} else if (indexOf(name, CicleType2) != -1)  {
			run("Roi Defaults...", "color=yellow stroke=1 group=2");
			Stack.setSlice(Z);
			makeOval(X-(circle_size/2,) (Y-circle_size/2), circle_size/pixelWidth, circle_size/pixelHeight);
			
		}  else if (indexOf(name, CicleType3) != -1)  {
			run("Roi Defaults...", "color=yellow stroke=1 group=3");
			Stack.setSlice(Z);
			makeOval(X-(circle_size/2,) (Y-circle_size/2), circle_size/pixelWidth, circle_size/pixelHeight);
		} else {
			Stack.setSlice(Z);
			makePoint(X, Y);
		}
			roiManager("add");
			roiManager("select", i);
			roiManager("rename", name);	
		}
setBatchMode(false);

run("ROI Manager...");
roiManager("Show All");
waitForUser;


//-----------------open other channels
for (i=0; i<channels_names.length;i++) {
				Img= channels_names[i]+"-" + BaseName + ".tif";
				Img_path=Image_path + File.separator + Img;
				print("Searching: " + Img);
				if(File.exists(Img_path)) {
					open(Img_path);
					print("Found!");
					tit=getTitle();
					FluoImages=Array.concat(FluoImages,tit);
				}
}

//-------------------merge images
n = FluoImages.length;
print("Numero di immagini trovate: " + n);

if (n > 0) {
    cmd = "";

    if (n >= 1) cmd = cmd + "c1=" + FluoImages[0];
    if (n >= 2) cmd = cmd + " c2=" + FluoImages[1];
    if (n >= 3) cmd = cmd + " c3=" + FluoImages[2];
    if (n >= 4) cmd = cmd + " c4=" + FluoImages[3];
    if (n >= 5) cmd = cmd + " c5=" + FluoImages[4];
    // puoi continuare fino a c7 se ti serve

    cmd = cmd + " create"; // per avere una nuova immagine merged
    print("Merge Channels... " + cmd);
    run("Merge Channels...", cmd);
} else {
    print("Nessuna immagine trovata: niente merge.");
}

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

// This function find a string 
function getSubstring(string, prefix, postfix) {
   start=indexOf(string, prefix)+lengthOf(prefix);
   end=start+indexOf(substring(string, start), postfix);
   if(start>=0&&end>=0)
     return substring(string, start, end);
   else
     return "";
}