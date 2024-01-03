pixelSize50=0.65;
pixelSize25=1.3;

title=getTitle()
getDimensions(width, height, channels, slices, frames);

if (matches(title, ".*25perc.*")) {
run("Properties...",  "unit=micron pixel_width="+pixelSize50+" pixel_height="+pixelSize50+" voxel_depth=40");
}
else if (matches(title, ".*50perc.*")){
run("Properties...",  unit=micron pixel_width="+pixelSize25+" pixel_height="+pixelSize25+" voxel_depth=40");
}

//"channels="+channels+" slices="+slices+" frames="+frames+"