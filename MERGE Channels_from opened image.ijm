#@ File (label="Select Image Directory", style = "directory") input

image_format=".tif";

Title=getTitle();

TitleSplit=split(Title,"-");
		BaseNameO="";
		for(s = 1; s<TitleSplit.length; s++){
			BaseNameO=BaseNameO+TitleSplit[s];
		}
		
print(BaseNameO);

InputList = getFileList(input);
print("files in stack directory: "+InputList.length);
for (l = 0; l < InputList.length; l++) {
	if (endsWith(InputList[l], image_format)) {
		// remove the extension from the BaseName
		SplitName=File.getName(input + File.separator +InputList[l]);
		//print(SplitName);
		// Get the Basename
		SplitName=split(SplitName,"-");
		BaseName="";
		for(s = 1; s<SplitName.length; s++){
			BaseName=BaseName+SplitName[s];
		}
		if (BaseName==BaseNameO) {
			if(InputList[l]!=Title){
				open(input + File.separator +InputList[l]);					
			}
		}

	}
}
images=getList("image.titles");
run("Merge Channels...", "c1="+images[0]+" c2="+images[1]+" c3="+images[2]+" c4="+images[3]+" create");

