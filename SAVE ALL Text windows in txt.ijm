// this macro save all text windows,it gives an error on the loop but still works

dir = getDirectory("Choose a Directory"); 
list = getList("window.titles");
print(list.length);
	for(i=0;i<=list.length; i++){
		selectWindow(list[i]);
		saveAs("Text", dir+list[i]);
		print("   "+list[i]);
		run("Close");
	}

//getInfo("window.title")
//saveAs("Text", path);