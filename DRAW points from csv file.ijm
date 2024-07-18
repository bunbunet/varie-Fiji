// This Macro Drow points based on names and coordinates of a csv file
// Csv file is expected to include coordinates in columns named X,Y,Z and point name in a column named ROI

ReadCsv();

for(i=0;i<nResults;i++){
		Stack.setSlice(getResultString("Z", i));
		makePoint(getResult("X", i), getResult("Y", i));
			roiManager("add");
			roiManager("select", i);
			roiManager("rename", getResultString("ROI", i));	
		}	
		
		
function ReadCsv() {

     lineseparator = "\n";
     cellseparator = ",";

     // copies the whole RT to an array of lines
     lines=split(File.openAsString(""), lineseparator);

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