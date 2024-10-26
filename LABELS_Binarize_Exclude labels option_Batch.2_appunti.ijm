labels=newArray("223");
getDimensions(width, height, channels, slices, frames);

for (i = 0; i <labels.length; i++) {
		setThreshold(labels[i], labels[i], "raw");
		for (s = 0; s < slices; s++) {
			setSlice(s+1);
			run("Create Selection");
			setForegroundColor(0, 0, 0);
			if(selectionType()!=-1){ 
				run("Fill", "slice");
				}
		}
}