pixelSize50=0.65;
pixelSize25=1.3;

title=getTitle()
getDimensions(width, height, channels, slices, frames);

if (matches(title, ".*s50.*")) {
run("Properties...",  "unit=micron pixel_width="+pixelSize50+" pixel_height="+pixelSize50+" voxel_depth=40");
}
else if (matches(title, ".*s25.*")){
run("Properties...",  unit=micron pixel_width="+pixelSize25+" pixel_height="+pixelSize25+" voxel_depth=40");
}

//"channels="+channels+" slices="+slices+" frames="+frames+"