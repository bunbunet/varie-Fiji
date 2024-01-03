import sys
from os import listdir
from os.path import isfile, join
import csv
#this script return the list of files (NOT folders) in a directory.
#the output is saved in the same folder as the .py file that should thus be moved in the desired output directory
#Modify
user_input = str(input("Choose Directory: "));
file_name = str(input("Choose the csvfile name:_")+".csv");

onlyfiles = [f for f in listdir(user_input) if isfile(join(user_input, f))]

with open(file_name, 'w', newline='') as print_to:
    writer = csv.writer(print_to)
    for i in onlyfiles:
        writer.writerow([i])

#se non metti il '' per newline di default lascia uno spazio tra una riga e l'altra
#se non metti [] sull'elemento iterante ogni lettera del nome diventa una colonna
        






