//if different channels are not separated in the stack but displayed in a common sequence of images
//this macro separate them in to n separate images

nChannels=3

getDimensions(width, height, channels, slices, frames);
image=getImageID();
for (g = 1; g <= nChannels; g++) {
	planes="1";// to set a variable as a string the first item must be a string.
	
	//for (i = g; i < slices-1/nChannels; i+=nChannels) {
	  for (i = g; i <= slices; i+=nChannels);
		planes=planes+","+i;
		}
		
	selectImage(image);	
	run("Make Substack...", "slices="+planes);
	setSlice(1);
	run("Delete Slice");
}