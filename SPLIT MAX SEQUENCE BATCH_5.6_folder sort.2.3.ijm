// @File(label = "Input directory", style = "directory") dir
// @String(label = "File Format", value = ".tiff") format
// @String(label = "Name of Channel 1", value = "GFP") ch1
// @String(label = "LUT", value = "Grays") LUT1
// @String(label = "Name of Channel 2", value = "CTIP2") ch2
// @String(label = "LUT", value = "Grays") LUT2
// @String(label = "Name of Channel 3", value = "RFP") ch3
// @String(label = "LUT", value = "Grays") LUT3
// @String(label = "Name of Channel 4", value = "DAPI") ch4
// @String(label = "LUT", value = "Grays") LUT4
// @String(label = "Name of Channel 5", value = "DAPI") ch5
// @String(label = "LUT", value = "Grays") LUT5
// @String(label="split slices", choices={"yes", "no"}, style="radioButtonHorizontal") sequence
// @String(label="Sort into folders", choices={"yes", "no"}, style="radioButtonHorizontal") Folder_Sort
// @String(label="Save Stack not MAX", choices={"yes", "no"}, style="radioButtonHorizontal") save_stack_as_tiff



//Set the processsing of the images. (leave blank to skip, don't comment out)
function processImages() {
	//run("Subtract Background...", "rolling=50 disable stack"); 
	//run("Unsharp Mask...", "radius=3 mask=0.60 stack"); 
}

setBatchMode(true); 
run("Clear Results");


// Create Two Arrays to store the name of single focal planes and their z position
// At the end of the macro these array are printed in a csv file that can be directly used to import these focal planes into TrakEM2
Fname=newArray;
Zlayer=newArray;

list = getFileList(dir);

// Channels will be called according to the number of channels in each image
// If less channesl are present they will 
channel_names=newArray(ch1,ch2,ch3,ch4,ch5);
LUT_names=newArray(LUT1,LUT2,LUT3,LUT4,LUT5);

for (i=0; i<list.length; i++) {
     if (endsWith(list[i], format)){
             print(i + ": " + dir+list[i]);
             open(dir+File.separator+list[i]);
             // make composite to handel potential RGB images
             run("Make Composite");
             Original_Image=getImageID();
             imgNameSave=File.getNameWithoutExtension(list[i]);
             imgName=getTitle();
              // Extract the _z value from the file name
			 zString = getSubstring(imgName+format, "_z", "_");
			 zValue = NaN; //or whatever to tell you that you could not read the value
			 if(zString!="") {
	   			zValue=parseInt(zString); //parseFloat if not always an integer value
				print ("Z:"+zValue);
			 }
	     	 processImages(); //process images according to user defined function
             getDimensions(width, height, channels, slices, frames);
             print("Channels:"+channels);
             print("Slices"+slices);
             
             //Split channels and save stack or MAX and/or Image sequence
             run("Split Channels");	     	
             for(c=0; c<channels; c++){
             	// Create Folder hierarchy according to user options
             	// Files can be saved in a single folder or sorted into distinct folders, each names as the channel name
             	// We create the folder here in order to accomodate only channels existing in the images
             	if(Folder_Sort=="yes"){
					Zdir= dir + File.separator + channel_names[c];
					//print("Fold_Sort è vero!");				
				}
				else{
					Zdir = dir+ File.separator + "Split";
				}
				 File.makeDirectory(Zdir);
             	 selectWindow("C"+c+1+"-"+ imgName);
             	 run(LUT_names[c]);
             	 
             if (slices==1 || save_stack_as_tiff=="yes"){
             	saveAs("tif", Zdir+File.separator+channel_names[c]+"-"+imgNameSave+".tif");
         		close();	 
             }
             else {
		         run("Z Project...", "projection=[Max Intensity]");
		         saveAs("tif", Zdir+File.separator+channel_names[c]+"-"+imgNameSave+"MAX.tif");
		         close();
		        if (sequence=="yes") {
		        	if(Folder_Sort=="yes"){
						dir2= dir + File.separator + channel_names[c] + "_sequence";				
					}
					else{
						dir2 = dir + File.separator + "sequence";	
					}
					File.makeDirectory(dir2);
		        	selectWindow("C"+c+1+"-"+ imgName);      
		 			for (j=1; j<=slices; j++){
		 				run("Make Substack..."," slices="+j); 
		  				saveAs("tif", dir2+imgNameSave+"_"+IJ.pad(j, 3)+".tif");
		  				// The file name and z lavel of each focal plane are added to arrays. 
		  				// The z spacing is calculated by dividing 1 / total number of focal planes.
		    			Fname=Array.concat(imgNameSave+"_"+IJ.pad(j, 3)+".tif",Fname);
		    			Zlayer=Array.concat(zValue,Zlayer);
		    			zValue=zValue+(1/slices);
		  				close();
		 			}
		 		}  
		 	  }			
     		}
     	run("Close All");
     	call("java.lang.System.gc");
		}
}

//print the table of individual planes names and z levels for trakEM2 import
if(sequence=="yes"){
	for (i = 0; i < Fname.length; i++) {
						setResult("name", i, Fname[i]);
		    			setResult("X", i, "0");
		    			setResult("Y", i, "0");
		    			setResult("Z", i, Zlayer[i]);
					 }
	
	saveAs("Results", dir2+"sequence"+".csv");	
}

setBatchMode(false); 
print("Done!");


// This function find a string 
function getSubstring(string, prefix, postfix) {
   start=indexOf(string, prefix)+lengthOf(prefix);
   end=start+indexOf(substring(string, start), postfix);
   if(start>=0&&end>=0)
     return substring(string, start, end);
   else
     return "";
}
