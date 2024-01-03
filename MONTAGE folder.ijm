

columns=4

dir="G:\\Prove\\Export"
Out_Fold_List_Unique=getFileList(dir);
run("Image Sequence...","open=["+dir+File.separator+Out_Fold_List_Unique[0]+"] sort use");
run("Make Montage...", "columns="+columns+" use");
