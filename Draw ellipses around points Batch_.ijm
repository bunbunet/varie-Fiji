#@ File (label="Select ROIs directory", style = "directory") ROIs_dir
#@ File (label="Select Directory to save results", style = "directory") Out_dir
#@ String (label="Tag Type", style = "directory") tag
#@ Integer (label="Oval X in pixels)") Xov
#@ Integer (label="Oval Y in pixels)") Yov

setBatchMode(true);

list= getFileList(ROIs_dir);
for (k = 0; k < list.length; k++) {
 if (endsWith(list[k], ".roi")) { 	
 		roiManager("reset");
 		run("Clear Results");
		open(ROIs_dir + File.separator + list[k]);
		roiManager("Add");
		roiManager("select", 0);
		tit=list[k];
		roiManager("Measure");
		//getPixelSize(unit, pixelWidth, pixelHeight);
		points=newArray();
		for (i = 0; i < nResults(); i++) {
		    X = getResult('X', i);
		    Y = getResult('Y', i);
		    makeOval(X-Xov/2,Y-Yov/2, Xov, Yov);
		    roiManager("add");
		    point=Array.concat(points,i+2);
		}
		
		// create a single selection and save it
		roiManager("Select", points);
		roiManager("Combine");
		roiManager("reset");
		roiManager("Add");
		roiManager("select", 0);
		roiManager("rename", tag);
		roiManager("save", Out_dir+ File.separator +tit+"_"+tag+".zip") ;
		roiManager("reset");
 		run("Clear Results");
		run("Close All");
 	}
}
