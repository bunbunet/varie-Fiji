x="2"
y="4"
Dir="G:\\Rabies R+R\\QA R+R.3\\Stacks"
Base="R+R3_v2.3clXXrw2pz6_40x1024 stackTile.lif - TileScan_002 - T="

run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Up & Right] grid_size_x="+x+" grid_size_y="+y+" tile_overlap=20 first_file_index_i=0 directory=["+Dir+"] file_names=["+Base+"{i}.tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=5 compute_overlap computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");