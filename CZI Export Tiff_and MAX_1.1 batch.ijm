//@ File (label = "Input directory", style = "directory") input
//@ Boolean (label="Save Original Image", value=false) save_stack
//@ Boolean (label="Save MAX", value=false) save_MAX
//@ Boolean (label="Save Metadata", value=false) save_metadata
//@ Boolean (label="Save macro and label images", value=false) save_macro
//@ Boolean (label="Create single Output directory", value=false) SaveAllInOneFolder
//@ Double (label = "Scale factor", label="Scale Factor") scale

// This Macro Batch export from all axioscan czi files in a folder: 
// original Image, stack, MAX, label and macro images, original metadata and a list of series dimensions.
// Image size can be scaled by reducing the scale under 1 (0.5 will be 50% scaled)
// Images can be also custom processed adding the commands in the processImage function
// For further details or suggestions contact federico.luzzati@unito.it
// 
// SPECIFIC PYRAMIDS CAN BE EXTRACTED, THE FINAL PIXEL SIZE CAN VARY .
//
Pyramid=1

function processImages() {
	//ADD HERE YOUR PERSONALIZED IMAGE PROCESSING COMMANDS
	//run("Subtract Background...", "rolling=50 disable stack"); 
	//run("Unsharp Mask...", "radius=3 mask=0.60 stack"); 
}

run("Bio-Formats Macro Extensions");
setBatchMode(true);

list = getFileList(input);
print("number of files: "+list.length);
//Loop over all .czi files in the selected folder
for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], ".czi")) {
			print("reading :"+ list[i]);
			Title=substring(list[i], 0,lastIndexOf(list[i], ".czi"));
			outPath=input+ File.separator + Title;
			if(SaveAllInOneFolder==true){
				outPath=input+ File.separator + "Extracted_Images";	
			}
			output=File.makeDirectory(outPath);
			//Set the arrays that will store the information that will be collected, re-initialize for each file
			//FileNames=newArray();
			SeriesNames=newArray();
			sizeXs=newArray();
			sizeYs=newArray();
			//PositonXYZ=newArray();
			sizeChannels=newArray();
			sizeZs=newArray();
			path=input + File.separator + list[i];
			if(save_metadata==true){
				run("Bio-Formats Importer", "open=["+path+"] display_metadata view=[Metadata only]");
				saveAs("Text", outPath+File.separator+"Original_metadata_"+Title+".csv");
			}
			Ext.setId(path);
			Ext.getCurrentFile(file);
			Ext.getSeriesCount(seriesCount);
			//Ext.openThumbImagePlus(path);
			//saveAs("TIFF", file +"_Thumbinail_");
			
			//loop over all series in the current .czi file
			for (s=0; s<seriesCount; s++) {
				Ext.setSeries(s)
				//collect information for the current series
				Ext.getSeriesName(name);
				Ext.getSizeX(sizeX);
				Ext.getSizeY(sizeY);
				Ext.getSizeZ(sizeZ);
				Ext.getSizeC(sizeC);
				Ext.getSizeT(sizeT);
				
				//Append the information to the arrays
				//FileNames=Array.concat(file,FileNames);
				SeriesNames=Array.concat(SeriesNames,name);
				sizeXs=Array.concat(sizeXs,sizeX);
				sizeYs=Array.concat(sizeYs,sizeY);
				//PositonXYZ=Array.concat(positionX+"x"+positionY+"x"+positionZ,PositonXYZ);
				sizeChannels=Array.concat(sizeChannels,sizeC);
				sizeZs=Array.concat(sizeZs,sizeZ);
				
				//Extract macro and label image
				if(save_macro==true){
					if (matches(name, ".*macro.*")) {
						run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
						run("RGB Color");
						saveAs("TIFF", outPath+File.separator+Title+"_macro_");
						run("Close");
						}
					if (matches(name, ".*label image.*")) {
						run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
						run("RGB Color");
						saveAs("TIFF",outPath+File.separator+Title+"_label image_");
						run("Close");
						}
					}
				}
			//Print the arrays to result table
			if(save_metadata==true){
				run("Clear Results");
				for(k=0;k<SeriesNames.length;k++){
							setResult("Series Name", k, SeriesNames[k]);
							setResult("Size X", k, sizeXs[k]);
							setResult("Size Y", k, sizeYs[k]);
							setResult("number of planes", k, sizeZs[k]);
							setResult("number of channels", k, sizeChannels[k]);
						}
						
				saveAs("Results", outPath+File.separator+Title+"_czi series dimensions.csv"); 
			}
			//--------------------------EXTRACT IMAGES--------------------------------
			// get the array lenght and add one element at the end to compare elements 
			// with subsequent ones without going "out of index" in the loop
			Series_to_export=newArray();
			length=sizeXs.length;
			sizeXs=Array.concat(0,sizeXs);
					
					// select the pyramid level in the sequence
					for (j = 0; j <length ; j++) {
						if(sizeXs[j+1]>sizeXs[j]){
							Series_to_export=Array.concat(Series_to_export,j+Pyramid);
						}
					}

			print("Exporting Series:");
			Array.print(Series_to_export);
			// Extract the series with the smallest dimesnions
			for (s=0; s<Series_to_export.length; s++) {
				//Ext.setSeries(Series_to_export[s]);
				run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+Series_to_export[s]);
				if (scale!=1){
					run("Scale...", "x="+scale+" y="+scale+" z=1.0 interpolation=Bilinear average create");
				}
				processImages();
				if (save_stack==true){				
					saveAs("TIFF", outPath + File.separator + Title +"_py"+ Pyramid +"_Series_" + Series_to_export[s] + "_scene"+s+1+"_sc"+scale+".tif");	
				}		
				if (save_MAX==true){
					getDimensions(width, height, channels, slices, frames);
					if(slices==1){
				saveAs("TIFF", outPath + File.separator + Title +"_py"+ Pyramid +"_Series_" + Series_to_export[s] + "_scene"+s+1+"_sc"+scale+"_MAX_single slice.tif");
					}
					else{
						run("Z Project...", "projection=[Max Intensity]");
						saveAs("TIFF", outPath + File.separator + Title +"_py"+ Pyramid +"_Series_" + Series_to_export[s] + "_scene"+s+1+"_sc"+scale+"_MAX.tif");						
					}
				
				}	
				run("Close");					
				}
		}
	}	

print("Done!");


