dir=getDirectory("Choose source Directory");
list = getFileList(dir);
for (i=0; i<list.length; i++) {
  			  setResult("name", i, list[i]);
  			  saveAs("Results",dir+File.separator+"File_list.txt");
}