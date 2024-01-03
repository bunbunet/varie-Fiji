//This macro scan a folder for subfolders containing image files to be stitched without configuration. The stitched images are automatically saved in the mother folder
dir=getDirectory("Choose source Directory");
print(dir);
list = getFileList(dir);

setBatchMode(true); 
for (i=0; i<list.length; i++) {
     for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
     	  	print(i + ": " + dir+list[i]);
     	  	name=replace(list[i],"/","");
     	  	print(name);
	      	run("Grid/Collection stitching", "type=[Unknown position] order=[All files in directory] directory=["+dir+list[i]+"] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=5 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
	      	run("RGB Color");
	      	saveAs("tiff", dir+name);
     }
}
print("DONE!");
