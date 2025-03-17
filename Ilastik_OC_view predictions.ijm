#@ File (label="Select Predictions and Identities directory", style = "directory") Mask_dir 
#@ String (label="Predictions & Identitis tag (before original file name) (leave blank to skip)") tag

if(tag!=""){
	tag=tag+"-";
} else {
	tag="";
}

img=getTitle();
BaseName=StripExtension(img);
Mask_path = Mask_dir + File.separator + tag + BaseName + "_Object Predictions.tiff";
Ident_path = Mask_dir + File.separator+ tag + BaseName+"_Object Identities.tiff";

// Add Labels of individual objects to 3D manager
open(Ident_path);
Ident=getImageID();

run("3D Manager");
run("3D Manager Options", "volume surface compactness 3d_moments integrated_density mean_grey_value std_dev_grey_value feret centroid_(pix) drawing=Contour");

Ext.Manager3D_AddImage();
//close();

// Add predictions as additional channel
open(Mask_path);
Mask=getTitle();
run("glasbey on dark");

selectImage(img);
getDimensions(width, height, channels, slices, frames);
run("Split Channels");
if (channels==1){
	run("Merge Channels...", "c1=[C1-"+img+"] c2=["+Mask+"] create");
}
if (channels==2){
	run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=["+Mask+"] create");
}
if (channels==3){
	run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=[C3-"+img+"] c4=["+Mask+"] create");
}
if (channels==4){
	run("Merge Channels...", "c1=[C1-"+img+"] c2=[C2-"+img+"] c3=[C3-"+img+"] c4=[C4-"+img+"] c5=["+Mask+"] create");
}




function StripExtension(filename){
	NameSplit=split(filename,".");
	fileWext=NameSplit[0];
	for (i = 1; i < NameSplit.length-1; i++) {
		fileWext=fileWext+"."+NameSplit[i];
	}
	return fileWext;
}