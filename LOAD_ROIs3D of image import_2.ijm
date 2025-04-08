#@ File (label="Select ROIs3D directory", style = "directory") ROIs3D_Dir
#@ File (label="Select ROIs directory", style = "directory") ROIs
#@ Boolean(label="Load ROIs?") load_ROIs
#@ Boolean(label="Open all ROIs3D") allROIs3D
#@ String (label="ROIs tag (after original file name) (write x to skip)") ROItag
#@ String(value="Label TAGS: individual, unsplitted,aspecific", visibility="MESSAGE") hints1
#@ String(value="ROI TAGS: StrArea, ClusterArea", visibility="MESSAGE") hints2
#@ String(value="Complete tags: Complete, Incomplete", visibility="MESSAGE") hints3
#@ String(label="Type tag") Type_tag

tit=getTitle();

titWext= getTitleStriptif();

ROI_path =ROIs+ File.separator + titWext + ROItag + ".zip";

if (load_ROIs==true){
roiManager("Open", ROI_path);
}

run("3D Manager");
if (allROIs3D==true){
	list=getFileList(ROIs3D_Dir);
	for (i = 0; i < list.length; i++) {
		if (matches(list[i], ".*"+titWext+".*")) {
			print(list[i]);
			Ext.Manager3D_Load(ROIs3D_Dir+ File.separator + list[i]);
			Ext.Manager3D_SelectAll();
		}
	}
}
else {

	Ext.Manager3D_Load(ROIs3D_Dir+ File.separator + tit+"_SegObjobj_3Droi_"+Type_tag+".zip");
	Ext.Manager3D_SelectAll();
}

function getTitleStriptif() {
  t = getTitle();
  extensions = newArray(".tif");    
  for(i=0; i<extensions.length; i++)
    t = replace(t, extensions[i], "");  
  return t;
}  // end getTitleStripExtension()