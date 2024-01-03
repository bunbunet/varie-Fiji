
// To use File.copy function the full input and output path should be specified
path1="G:\\Prove\\RRGEF.2_piastra.tif";
path2="G:\\Prove\\Export\\RRGEF.2_piastra.tif";
File.copy(path1, path2); 

// To copy a list of files, the path should be assembled
path1="G:\\Prove\\";
path2="G:\\Prove\\Export\\";
list=getFileList(path1);

for (i = 0; i < list.length; i++) {
	if(endsWith(list[i], ".tif")){
		print(list[i]);
		File.copy(path1+list[i], path2+list[i]); 
	}
}
