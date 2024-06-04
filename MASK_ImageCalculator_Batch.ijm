//@ File (label="Select Mask directory_1", style = "directory") input_Seg1
//@ File (label="Select Mask directory_2", style = "directory") input_Seg2
//@ File (label="Select Output_Directory", style = "directory") out_dir
//@ String(label="label grey level of Mask1", value="1") label1
//@ String(label="label grey level of Mask2", value="1") label2
//@ String(label="New Image Name", value="NesGF") newMaskName

// This Macro analyze two segmentations (as label images) and than extract the colocalization mask. It also saves the binary masks of the original images
// The two segmentations of each image must be in two separate folders
// Users must also indicate the gray level of the label to extract for each

list1 = getFileList(input_Seg1);
list2 = getFileList(input_Seg2);

setBatchMode(true);

for (k = 0; k < list1.length; k++) {
	if (endsWith(list1[k], ".tif")) { 
		//Open Image1
		open(input_Seg1+File.separator+list1[k]);
		tit1 = getTitle();
		Mask1=getImageID();
		//Open Image2
		open(input_Seg2+File.separator+list2[k]);
		Mask2=getImageID();
		tit2 = getTitle();
		//Extract base name and verify correspondence
		SplitMaskType1=split(tit1, "-");
		BaseName=SplitMaskType1[1];
		SplitMaskType2=split(tit2, "-");
		BaseName1=SplitMaskType2[1];
		if(BaseName==BaseName1){
			print("mask coresspondence ok");
			// Convert to Masks
			selectImage(Mask1);
			setThreshold(label1,label1);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Grays");
			saveAs("Tiff", out_dir + File.separator + SplitMaskType1[0] + "-" + BaseName +".tiff");
			selectImage(Mask2);
			setThreshold(label2,label2);
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Grays");
			saveAs("Tiff", out_dir + File.separator + SplitMaskType2[0] + "-" + BaseName +".tiff");
			// Generate Overlap Mask
			imageCalculator("AND create", tit1,tit2);
			saveAs("Tiff", out_dir + File.separator + newMaskName + "-" + BaseName +".tiff");
		} else {
			print(tit1+" and "+tit2+" were obtained from distinct images!");
		}
	}
}
