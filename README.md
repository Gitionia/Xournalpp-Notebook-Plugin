# Xournalpp-Notebook-Plugin
This is a simple implementation of notebooks in Xournal++, similar to onenote, as a plugin. It uses folders in a certain root directory to represent notebooks that contain files. There are also UI-Buttons for switching between notebooks or files. This repository consists mainly of one lua script that can also be adapted to the users needs. This plugin should work on linux and windows.

## Installation
Clone the repository into the plugins folder (depends on platform, see also config folder at https://xournalpp.github.io/guide/file-locations/).
Then open the .lua file and set a root directory where the notebooks should be stored. The plugin also needs to be enabled in the plugins manager.

## Side notes
- This plugin attempts to mimic onenotes functionality for having notebooks with several pages
- However, this means that no nested notebooks are supported, which may be wanted
- Also, this plugin is not meant to replace the usage of the file manager for managing the files
- This plugin will probably not be extended further

## Usage
You can add 5 custom UI-Buttons that you can add by customizing the toolbar (Edit->Toolbars->Customize). Four of them allow for switching to the next or previous notebook or file and one allows to first select any notebook and then choose a file. Alternatively, you can use the same functionality under plugins in the menubar.

Selecting the notebook :
<img width="2160" height="1278" alt="grafik" src="https://github.com/user-attachments/assets/705d3064-1edb-432e-907b-d534f499ff0a" />
(see buttons at the bottom)


Then selecting a file inside a notebook:
<img width="2160" height="1278" alt="grafik" src="https://github.com/user-attachments/assets/02b0bf2c-4c0d-4648-a137-a8b302971657" />
