setForegroundColor(255, 255, 255);
for (i = 0; i <roiManager("count") ; i++) {
roiManager("Select", i);
run("Make Inverse");
roiManager("Update");
roiManager("Fill");
}