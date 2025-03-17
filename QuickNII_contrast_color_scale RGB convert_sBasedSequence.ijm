// @File(label = "Input directory", style = "directory") dir
// @String(label = "File Format", value = ".tiff") format
// @Double(label= "Scale, beween 0 and 1"  value=0.25, min=0, max=1) scale
// #@ Boolean(label="Save for QuickNII or Deepslice?(s based sequence instead of z") quick


output_dir=dir+File.separator+"QuickNII";

// SET CHANNELS MIN AND MAX (for more channels add values to array in line 33)
ch1_min_max="0,255";
ch2_min_max="0,255";
ch3_min_max="0,255";
ch4_min_max="0,255";

// SET CHANNELS LUTS (for more channels add values to array in line 34)
ch1_LUT="red"
ch2_LUT="green"
ch3_LUT="blue"
ch4_LUT="cyan"
ch5_LUT="magenta"

//Set the processsing of the images. (leave blank to skip, don't comment out)
function processImages() {
	//run("Subtract Background...", "rolling=50 disable stack"); 
	//run("Unsharp Mask...", "radius=3 mask=0.60 stack"); 
}

setBatchMode(true); 
run("Clear Results");

// 
min_max=newArray(ch1_min_max,ch2_min_max,ch3_min_max,ch4_min_max);
LUT_names=newArray(ch1_LUT,ch2_LUT,ch3_LUT,ch4_LUT,ch5_LUT);

// Create Two Arrays to store the name of single focal planes and their z position
// At the end of the macro these array are printed in a csv file that can be directly used to import these focal planes into TrakEM2
Fname=newArray;
Zlayer=newArray;

list = getFileList(dir);

LUT_names=newArray(LUT1,LUT2,LUT3,LUT4,LUT5);

for (i=0; i<list.length; i++) {
     if (endsWith(list[i], format)){
			print(i + ": " + dir+list[i]);
			open(dir+File.separator+list[i]);
			// make composite to handle potential RGB images
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
			run("Scale...", "x="+scale+" y="+scale+" interpolation=Bilinear average, create");
			getDimensions(width, height, channels, slices, frames);
			print("Channels:"+channels);
			print("Slices"+slices);
  	
            for (c = 0; c < channels; c++) {
				Stack.setChannel(c);
				values=split(min_max[c],",");
				setMinAndMax(parseInt(values[0]),parseInt(values[1]));
				run(LUT_names[c]);
			}
			if (slices>1) {
				run("Z Project...", "projection=[Max Intensity]");
			}
			run("RGB Color", "slices");
			
			// rewrite the name in s based sequence with 3 digits numbers
			sValue=zValue
			if (quick) {
				sValue=IJ.pad(zValue, 3);
			}
			name=replace(imgName, "_z"+zValue, "_s"+sValue);
            saveAs("tif", output_dir+File.separator+imgNameSave+"_s"+IJ.pad(z, 3)+".tif");
            run("Close All");
            call("java.lang.System.gc");
     }
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
