macro "Transfer_Labels" {
	nDEST=nSlices;
	if (nDEST==1) exit("Destination is not a stack");
	DEST=getTitle;
	setBatchMode(true);
	if (nImages<1) exit("Not enough images");
	TITLES=newArray(nImages);
	for (i=1; i<=nImages; i++) {
		selectImage(i);
		TITLES[i-1]=getTitle;
	}
	Dialog.create("Label Parameters");
	Dialog.addChoice("Source stack",TITLES,TITLES[0]);
	Dialog.addNumber("Crop labels by", 3,0,1,"characters");
	Dialog.addString("Add to label:", "", 6);
	Dialog.show;
	SOURCE=Dialog.getChoice;
	CROP=Dialog.getNumber;
	ADD=Dialog.getString;
	selectImage(SOURCE);
	nSOURCE=nSlices;
	if (nSOURCE!=nDEST) exit("Source and destination do not have the same slice number !");
	LABELS=newArray(nSOURCE);
	for (i=0; i<nSOURCE; i++) {
		setSlice(i+1);
		LAB=getInfo("slice.label");
		LAB_LENGTH=lengthOf(LAB);
		if (LAB_LENGTH<CROP) exit("Too much cropping in the name !");
		LABELS[i]=substring(LAB, 0,LAB_LENGTH-CROP)+ADD;
	}
	selectImage(DEST);
	for (i=0; i<nSOURCE; i++) {
		setSlice(i+1);
		setMetadata("Label", LABELS[i]);
	}
	setBatchMode("exit and display");
}