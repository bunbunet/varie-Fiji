#@ File (label = "Intput directory", style = "directory") in
#@ File (label = "Output directory", style = "directory") out
#@ String(label = "File Extension", value = ".tif") extension

//This Macro segment objects over a green background, crop the image to the dimension of the object
// and print the file name. It strip the extension by splitting the file name at "."

list = getFileList(in);
setBatchMode(true); 
for (f=0; f<list.length; f++) {
     if (endsWith(list[f], extension)){
           	 print(f + ": opening "+ list[f]);
             open(in+File.separator+list[f]);
             	
				roiManager("reset");
				img=getImageID();
				
				//Remove extension from the file name
				Title1=getTitle();
				Title2=split(Title1, ".");
             	Title=Title2[0];
				run("Duplicate...", " ");
				
				// Macro del Thresholding del verde.. avrei detto fosse una cosa più semplice.. 
				
				min=newArray(3);
				max=newArray(3);
				filter=newArray(3);
				a=getTitle();
				run("RGB Stack");
				run("Convert Stack to Images");
				selectWindow("Red");
				rename("0");
				selectWindow("Green");
				rename("1");
				selectWindow("Blue");
				rename("2");
				min[0]=0;
				max[0]=255;
				filter[0]="pass";
				min[1]=0;
				max[1]=255;
				filter[1]="pass";
				min[2]=4;
				max[2]=255;
				filter[2]="pass";
				for (i=0;i<3;i++){
				  selectWindow(""+i);
				  setThreshold(min[i], max[i]);
				  run("Convert to Mask");
				  if (filter[i]=="stop")  run("Invert");
				}
				imageCalculator("AND create", "0","1");
				imageCalculator("AND create", "Result of 0","2");
				for (i=0;i<3;i++){
				  selectWindow(""+i);
				  close();
				}
				selectWindow("Result of 0");
				close();
				selectWindow("Result of Result of 0");
				rename(a);
				
				// Label the objects
				run("Analyze Particles...", "size=0-Infinity pixel include add");
				// fuse eventual multiple ROIs into a single ROI
				
				rois=newArray();
				n = roiManager('count');
				for (i = 0; i < n; i++) {
					rois=Array.concat(rois,i);   
				}
				
				// select multiple ROIs at once and combine them
					if (roiManager("count")>1){
						roiManager("select", rois);
						roiManager("Combine");
						roiManager("add");
					}
				
				selectImage(img);
				
					if (roiManager("count")>1){
						roiManager("select", n);
					}
					else{
						roiManager("select", 0);
					}
				run("Enlarge...", "enlarge=20 pixel");
				run("To Bounding Box");
				run("Crop");
				
				setFont("SansSerif", 10);
				setColor(0, 0, 0);
				getDimensions(width, height, channels, slices, frames);
				stringWidth = getStringWidth(Title);
				drawString(Title, width-stringWidth-10, height);
				saveAs("Tiff",out+File.separator+Title);
     }
}

				
