import os
import zipfile

# Define the folder containing your plugin files
plugin_folder = 'my-plugin'

# Define the files to be included in the plugin
files_to_include = ['package.json', 'my-script.lua']

# Define the name of the output .aseprite-extension file
output_extension_file = '../The Mushroom Warbler/Assets/Art/Tiles/my-plugin.aseprite-extension'

def create_aseprite_extension(plugin_folder, files_to_include, output_extension_file):
    with zipfile.ZipFile(output_extension_file, 'w') as zp:
        for file in files_to_include:
            file_path = os.path.join(plugin_folder, file)
            zp.write(file, arcname=file_path)

if __name__ == '__main__':
    create_aseprite_extension(plugin_folder, files_to_include, output_extension_file)