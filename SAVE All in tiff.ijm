dir = getDirectory("Choose a Directory"); 
n = nImages();
  for (i=1; i<=n; i++) {
        selectImage(i); 
        title = getTitle; 
        print(title); 
        saveAs("tiff", dir+title);
        close(i);
}
run("Close All")

// non capisco perché close() non chiude..
//in alternative, ma non per il chiude ho trovato questo
//get image IDs of all open images 
//dir = getDirectory("Choose a Directory"); 
//ids=newArray(nImages); 
//for (i=0;i<nImages;i++) { 
//        selectImage(i+1); 
//        title = getTitle; 
//        print(title); 
//        ids[i]=getImageID; 

//        saveAs("tiff", dir+title); 
//}