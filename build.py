import os
import shutil

# source directory(audit as required, src directory looks for typescript files in its cwd):
src_directory = os.getcwd() # get file current working directory

# destination directory(audit as required):
destination_directory = os.getcwd()+"/berry/src/packages" # use the script directory as the baseline of the destination
# /src should be edited to what ever file you wish to be created or moved to, e.g C:/berry/src/packages

if not os.path.exists(destination_directory):
    os.makedirs(destination_directory) # make the folder directory tree if non-existent

for file in os.listdir(src_directory): # list out files
    if file.endswith('.ts'): # evaluate if the file is a typescript file
        src = src_directory
        destination = destination_directory
        shutil.move(src+'/'+file, destination) # move the file to the destination
        # edit file src for working directory
        with open(destination+'/'+file, "r+") as file_data:
            content = file_data.read()
            tokens = content.split("\n")
            new_dir = destination_directory.replace("c", "C", 1)
            new_dir = new_dir.replace("\\", "/")
            file_path = str.split(file_data.name, "/")
            file_name = file_path[len(file_path)-1].removesuffix(".ts")
            tokens.remove('declare module "C:/berry/src/'+file_name+'"'+";")
            tokens[len(tokens)-1] = 'declare module "'+new_dir+"/"+file_name+'"'
            new_src = "\n".join(tokens)
            print(new_src)
            file_data.seek(0)
            file_data.write(new_src)
            file_data.truncate()
