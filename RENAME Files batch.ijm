dir=getDirectory("Choose source Directory");
list = getFileList(dir);

#Use this option if you simply want to rename your files
#Consider that image J has a limited capacity to work with strings,
#Other dedicated freewate software exists: https://www.den4b.com/products/renamer
folder = getDirectory("Choose a folder to rename files");
files = getFileList(folder);
for(i = 0; i < files.length; i++){
  nameSplit = split(files[i], "Z");
  newFilename = nameSplit[0] + "_Z" + nameSplit[1] + "_t00Z.tif";
  File.rename(folder + files[i], folder + newFilename);
}


/*
#Use this option if you also want to perform some modification to the image
setBatchMode(true); 
for (i=0; i<list.length; i++) {
     if (endsWith(list[i], ".tif")){
               print(i + ": " + dir+list[i]);
             open(dir+list[i]);
             imgName=getTitle();
             imgName2=split(imgName, ".");
             saveAs("Tiff", dir+"CIC_ARA_z"+ imgName2[0] + "_.tif");

     }
}
	