//@ File (label = "Choose Directory Ch1", style = "directory") dir1
//@ File (label = "Choose a Directory Ch2", style = "directory") dir2
//@ File (label = "Choose a Directory to save Merged", style = "directory") dirS
//@ String(label = "Tag for the merged images", value="merged") tag

// The two folders must contain ONLY the images to be merged

list1 = getFileList(dir1);
list2 = getFileList(dir2);

if(list1.length!=list2.length){
	print("The two folders have contains number of files");
}

setBatchMode(true); 
for (i=0; i<list1.length; i++) {
		open(dir1+File.separator+list1[i]);
		baseName=File.getNameWithoutExtension(dir1+File.separator+list1[i]);
        imgName1=getTitle();
        print(imgName1+"_");    
	    open(dir2+File.separator+list2[i]);
	    imgName2=getTitle();
        print(imgName2);
	    run("Merge Channels...", "c1=["+imgName1+"] c2=["+imgName2+"] create");
	    saveAs("tif",dirS+File.separator+baseName+"_"+tag+".tif");
	    run("Close All");	    
 } 
 
 print("done");