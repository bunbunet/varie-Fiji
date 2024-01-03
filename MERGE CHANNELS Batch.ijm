
dir1=getDirectory("Choose Directory Ch1");
dir2=getDirectory("Choose a Directory Ch2");
dirS=getDirectory("Choose a Directory to save Results");

list1 = getFileList(dir1);
list2 = getFileList(dir2);

setBatchMode(true); 
for (i=0; i<10; i++) {
	for(j=0; j<10; i++) {
		open(dir1+list1[i]);
        imgName1=getTitle();
        //run("Make Composite");
        //run("Split Channels");
        //Channel1="C1-"+ imgName1; 
        print(imgName1+"_"+Channel1);    
	    open(dir2+list2[i]);
	    imgName2=getTitle();
        print(imgName2);
	    run("Merge Channels...", "c1=["+imgName1+"] c2=["+imgName2+"] create");
	    saveAs("tif",dirS+imgName1+"_RFP-ch3"+".tif");
	    close("*");	    
     //if (endsWith(list[i], ".tif"))
   } 
 } 
     