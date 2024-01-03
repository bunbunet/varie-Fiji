#@ File (label = "Intput directory", style = "directory") in
#@ File (label = "Output directory", style = "directory") out
#@ String(label = "File Extension", value = ".png") extension

//This Macro segment objects over a green background, crop the image to the dimension of the object
// and print the file name. It strip the extension by splitting the file name at "."

list = getFileList(in);
setBatchMode(true); 
for (f=0; f<list.length; f++) {
     if (endsWith(list[f], extension)){
           	 print(f + ": opening "+ list[f]);
             open(in+File.separator+list[f]);
             	
				makeRectangle(114, 30, 1281, 1044);
				run("Crop");
				
				//Remove extension from the file name
				Title1=getTitle();
				Title2=split(Title1, ".");
             	Title=Title2[0];
				
				saveAs("PNG",out+File.separator+Title);
     }
}
setBatchMode(false); 
				
