//@ File (label="Select Output Folder", style = "Directory") out_dir
//@ Integer(label="MAX spacing") n

name=getTitle();
y=1

setBatchMode(true);
for (i = 0; i < nSlices/4; i++) {
	if(y<nSlices){
		run("Z Project...", "start="+y+" stop="+y+n+" projection=[Max Intensity]");
		save(out_dir+File.separator+name+"_"+y+"-"+y+n+".tif");
		y=y+n;
		close();
	}
}
setBatchMode(false);