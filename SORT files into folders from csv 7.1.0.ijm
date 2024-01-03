#@ File (label = "Intput directory", style = "directory") in
#@ File(label = "Choose Txt file list",style="open") Txt
#@ String(label="File extension: ", description=".png") ext
#@ Boolean(label="Make Montage") Make_Montage
#@ Boolean(label="Create Stack") Create_Stack
#@ Boolean(label="List Alphabetically in montages") alphabetical
#@ int (label = "Montage Number of columns", value = 4) columns
#@ Boolean(label="Crop Image") CropImage
#@ File(label = "Choose ROI file",style="open") ROI


/*  This Macro sort files into folders according to a text file (txt or csv).
 *  The files to be sorted must be located in a single folder
 *  In the csv file the names and grouping must be in columns named "ID" and "Cluster" respectively
 *  Names are expected WITHOUT the extension (if the extension is already present in the listed names keep the extension option empty)
 *  it also produces a montage of the images included in the folder
 *  In each folder the macro also save a montage and a stack. 
 *  To preserve the ID list order unckeck the "List Alphabetically in montages" box.
 *  Even if no ROI is required do not leave blank the choose ROI file or it will throw an error
 */
roiManager("reset");
setForegroundColor(255, 255, 255);
setBackgroundColor(255, 255, 255);

setBatchMode(true); 

if(alphabetical==true){
	MontDir=in + File.separator + "Montages_AlphabeticalOrder";
}
else{
	MontDir=in + File.separator + "Montages_CustomOrder";
}
ClustDir=in + File.separator + "Cluster_Folders";

File.makeDirectory(MontDir);
File.makeDirectory(ClustDir);


//--------------- OPEN CSV AS RESULT TABLE--------------

     lineseparator = "\n";
     cellseparator = ",\t";

     // copies the whole RT to an array of lines
     lines=split(File.openAsString(Txt), lineseparator);

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
     // To list the files in alphabetical order in the montage, the table is sorted by the ID column
     if (alphabetical==true){
     Table.sort("ID");
     }

//-------------CREATE TWO PARALLEL ARRAYS FOR CLUSTER AND IDs----------------------------------------

// Extract the files IDs and cluster from the RT and store them into two parallel arrays
// The extension is already added to the item names to match with the files
// If the list already include the file extension modify line 47 (remove ext)
ID=newArray();
cluster=newArray();
print("Number of items in the txt file: "+ nResults());
for (i = 0; i < nResults(); i++) {
    it = getResultString('ID', i);
    group= getResultString('Cluster', i);
    item = it + ext;
    ID=Array.concat(ID,item);
    cluster=Array.concat(cluster,group);
}

//------------------SORT FILES INTO FOLDERS AND MAKE MONTAGE--------------

//set an array to store the files not found
files_not_found=newArray();

//collect cluster levels on a cluster copy (must be sorted messing up alignement iwt IDs)
cluster_copy=newArray();
for (i = 0; i < cluster.length; i++) {
	cluster_copy=Array.concat(cluster_copy,cluster[i]);
}

Clusters=ArrayUnique(cluster_copy);
Array.print(Clusters);

// Itarate through the clusters (grouping variable), if the cluster correspond to the current cluster level
// open the files. When all the IDs of that cluster have been opened leave the IDs loop assemble a stack, 
// do the montage save and close all
print("Number of clusters found:" + Clusters.length);
for (k= 0; k<Clusters.length; k++){
	// set a counter to verify the number of images that will be opened as part of current cluster
	Openedfiles=0;
	// set a cloumns variable that can be modified in case images are not enough to fill it
	cols=columns;
	current_cluster=Clusters[k];
	out= ClustDir + File.separator + current_cluster;
	File.makeDirectory(out);
	print("Cluster "+ k +":"+ current_cluster);
	// extract all the IDs corresponding to the [k]th Cluster.
	for (i = 0; i <cluster.length; i++){
		if (cluster[i]==current_cluster){
			if (File.exists(in+File.separator+ID[i])) { //Sanity check that the file exist
				// if no crop or mantage is needed 
				if (Make_Montage == true || CropImage==true){
					//print(ID[i]+"_"+ cluster[i]);
					open(in+File.separator+ID[i]);
					Openedfiles=Openedfiles+1;
					title=getTitle();
					run("RGB Color");
					if(CropImage==true){
						roiManager("reset");
						open(ROI);
						run("Crop");
					saveAs("TIFF", out+File.separator+ID[i]+".tif"); 
					}
				}
				//If not cropped images can simply be copied in the target folder
				if(CropImage==false){
					File.copy(in+File.separator+ID[i], out+File.separator+ID[i]); // Files are further copied in the corresponding cluster folder
				}
			} else {
				files_not_found=Array.concat(files_not_found,ID[i]);
			}
		}
}

//--MAKE MONTAGE--

	// To avoid large white spaces in the montage, when opened images are not filling a row of n columns,
	// the montage columns number is set = to the n° of opened images	
	if (cols>Openedfiles){
		cols=Openedfiles;
		}
	//round cols to the highest integer
	rows=Math.ceil(Openedfiles/cols);
	// Create Montage with all the opened images and save it 
	if (Make_Montage==true && nImages>1) {
		run("Images to Stack", "name=Stack title=[] use");
		if(Create_Stack==true){
			saveAs("TIFF", MontDir+File.separator+Clusters[k]+"_stack.tif");
			}
		run("Make Montage...", "columns="+cols+" rows="+rows+" scale=1 use");
		saveAs("PNG", MontDir+File.separator+Clusters[k]+"_montage.tif");
		run("Close All");
	}
	close("*");
}

print("Files not found:");
for (i = 0; i < files_not_found.length; i++) {
	print(files_not_found[i]);
}

print("Done!");

//----- Function that return a new array
function ArrayUnique(array) {
	array 	= Array.sort(array);
	array 	= Array.concat(array, 999999);
	uniqueA = newArray();
	i = 0;	
   	while (i<(array.length)-1) {
		if (array[i] == array[(i)+1]) {
			//print("found: "+array[i]);			
		} else {
			uniqueA = Array.concat(uniqueA, array[i]);
		}
   		i++;
   	}
	return uniqueA;
}
