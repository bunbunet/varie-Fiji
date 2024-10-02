#@ File (label="Select ROIs directory", style = "directory") input
#@ File (label="Select output directory", style = "directory") output
#@ String (label="list name of ROIs to keep separated by comma", value = "STR_Les,STR_healthy,Les") Rois_to_keep
#@ String (label="tag to add as suffix to the ROIs", value = "HealtyLes") tag

Rois_to_keep=split(Rois_to_keep,",");

list = getFileList(input);

for (i = 0; i < list.length; i++) {
	roiManager("reset");
	if(endsWith(list[i], ".zip")){
		
		roiManager("open", input+File.separator+list[i]);
		baseName=File.getNameWithoutExtension(input+File.separator+list[i]);
		print(list[i]+": "+roiManager("count"));
		for (r = 0; r < roiManager("count"); r++) {// the actual number of ROIs changesand must be updated in the loop
			name=RoiManager.getName(r);
			roiManager("select", r);
			if(!contains(Rois_to_keep,name)){
				roiManager("delete");
			}
		}
		
		roiManager("save", output+File.separator+baseName+"_"+tag+".zip");
	}
}


function contains( array, value ) {
    for (i=0; i<array.length; i++) 
        if ( array[i] == value ) return true;
    return false;
}
