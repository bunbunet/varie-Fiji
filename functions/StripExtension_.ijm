
//remove extetnsion, considered as the last .something

function StripExtension(filename){
	NameSplit=split(filename,".");
	fileWext=NameSplit[0];
	for (i = 1; i < NameSplit.length-1; i++) {
		fileWext=fileWext+"."+NameSplit[i];
	}
	return fileWext;
}

// Example use
file="DCX.1.punto.dot.point.tif";

fileWext=StripExtension(file);
print(fileWext);
