#@ File(label = "Input directory", style = "directory") dir
#@ String(label = "File Format", value = ".tiff") format
#@ Boolean(label="Save for QuickNII or Deepslice?(s based sequence instead of z)") quick
#@ String(label="Histogram Min-Max method",choices={"manual", "enhance contrast","none"}, style="radioButtonHorizontal") contrast


scale=0.15;

output_dir=dir+File.separator+"QuickNII";
File.makeDirectory(output_dir);

// SET CHANNELS MIN AND MAX (for more channels add values to array in line 33)
ch1_min_max="5,20";
ch2_min_max="10,60";
ch3_min_max="100,255";
ch4_min_max="255,255";

// SET CHANNELS LUTS (for more channels add values to array in line 34)
ch1_LUT="Green"
ch2_LUT="Red"
ch3_LUT="Blue"
ch4_LUT="Magenta"
ch5_LUT="Grays"

//Set the processsing of the images. (leave blank to skip, don't comment out)
function processImages() {
	//run("Subtract Background...", "rolling=50 disable stack"); 
	//run("Unsharp Mask...", "radius=3 mask=0.60 stack"); 
}

//setBatchMode(true); 
run("Clear Results");

// 
min_max=newArray(ch1_min_max,ch2_min_max,ch3_min_max,ch4_min_max);
LUT_names=newArray(ch1_LUT,ch2_LUT,ch3_LUT,ch4_LUT,ch5_LUT);

// Create Two Arrays to store the name of single focal planes and their z position
// At the end of the macro these array are printed in a csv file that can be directly used to import these focal planes into TrakEM2
Fname=newArray;
Zlayer=newArray;

list = getFileList(dir);

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
				Stack.setChannel(c+1);
				if(contrast=="manual"){
					values=split(min_max[c],",");
					setMinAndMax(parseInt(values[0]),parseInt(values[1]));
				}
				if(contrast=="enhance contrast"){
					run("Enhance Contrast", "saturated=0.35");
				}
				run(LUT_names[c]);
				
  			}
			if (slices>1) {
				run("Z Project...", "projection=[Max Intensity]");
			}
			
			Stack.setDisplayMode("composite");
			run("RGB Color");
			
			// rewrite the name in s based sequence with 3 digits numbers
			sValue=zValue;
			if (quick) {
				sValue=IJ.pad(zValue, 3);
			}
			name=replace(imgName, "_z"+zValue, "_s"+sValue);
            saveAs("png", output_dir+File.separator+name);
            //saveAs("tif", output_dir+File.separator+name);
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
