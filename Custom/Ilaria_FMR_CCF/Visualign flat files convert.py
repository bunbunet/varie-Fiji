# -*- coding: utf-8 -*-
"""
Created on Sun Aug  1 23:09:13 2021

@author: Federico Luzzati
"""

from skimage import io
import numpy
import os

root_dir = "C:\\Users\\feder\\Documents\\LAB\\LGE_interneurons_postnatal\\Cdkl5\\Atlas\\VisuAlign export\\"
root_dir_input = os.path.join(root_dir)
root_dir_output = os.path.join(root_dir, "Atlas_16bit")
SOVRASCRIVI = False

if not os.path.exists(root_dir_output):
    os.makedirs(root_dir_output)

#Get all the flat files in input directory
file_list=os.listdir(root_dir_input)
       
flat_list=[f for f in file_list if ".flat" in f]

for file in flat_list:
    file_path = os.path.join(root_dir_input, file)
    with open(file_path,'rb') as fp:
      buffer = fp.read()
    nDims = int(buffer[0])
    shape = numpy.frombuffer(buffer, dtype=numpy.dtype('>i4'), offset=1, count=2) 
    data = numpy.frombuffer(buffer, dtype=numpy.dtype('>i2'), offset=9)
    data = data.reshape(shape[::-1])
    #print(nDims,shape,data.shape,data.min(),data.max())
    
    #plt.imshow(data)
    file_tif=os.path.splitext(file)[0]+".tif"
    output_path=os.path.join(root_dir_output, file_tif)
    
    io.imsave(output_path, data)

