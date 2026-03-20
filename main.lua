--- Configure plugin:
notebookRootDir = "" -- the root directory for the notebooks
platform = "linux" -- set platform: "linux" or "windows"
version_above_1_3 = false -- default is false, set to true if warning appears when using plugin
--------------------------------------------

--- Shortcuts and icons can be changed here
function initUi()
	app.registerUi({
		["menu"] = "Previous Page",
		["callback"] = "switchToPreviousPage",
		["accelerator"] = "<Alt>Left",
		["toolbarId"] = "PreviousPage",
		["iconName"] = "pan-start-symbolic",
	})
	app.registerUi({
		["menu"] = "Next Page",
		["callback"] = "switchToNextPage",
		["accelerator"] = "<Alt>Right",
		["toolbarId"] = "NextPage",
		["iconName"] = "pan-start-symbolic-rtl",
	})
	app.registerUi({
		["menu"] = "Previous Notebook",
		["callback"] = "switchToPreviousNotebook",
		["accelerator"] = "<Alt><Shift>Left",
		["toolbarId"] = "PreviousNotebook",
		["iconName"] = "pan-up-symbolic",
	})
	app.registerUi({
		["menu"] = "Next Notebook",
		["callback"] = "switchToNextNotebook",
		["accelerator"] = "<Alt><Shift>Right",
		["toolbarId"] = "NextNotebook",
		["iconName"] = "pan-down-symbolic",
	})
	app.registerUi({
		["menu"] = "Select File",
		["callback"] = "selectFile",
		["accelerator"] = "<Alt><Shift>k",
		["toolbarId"] = "SelectFile",
		["iconName"] = "user-bookmarks", -- also possible "file-manager"
	})
end

--- Do not change after this
if platform == "linux" then
	sep = "/"
else
	sep = "\\"
end

-- choosing between deprecated app.msgbox and newer api with app.openDialog
local openDialog
if version_above_1_3 then
	function openDialog(message, options, callback, isError)
		app.openDialog(message, options, callback, isError)
	end
else
	function openDialog(message, options, callback, isError)
		local selection = app.msgbox(message, options)
		_G[callback](selection)
	end
end

function emptyCallback() end
function messageDialog(message, options)
	openDialog(message, options, "emptyCallback", false)
end

function showMessage(message)
	openDialog(message, { "Ok" }, "emptyCallback", false)
end

function selectFile()
	notebooks = getNotebooksAndFindIndex()

	if #notebooks == 0 then
		showMessage("There are currently no notebooks")
	else
		openDialog("Select notebook", notebooks, "openNotebookAndChooseFile", false)
	end
end

function openNotebookAndChooseFile(selection)
	if selection < 0 then return end

	notebookDir = getRootDir() .. sep .. notebooks[selection]
	files = getFilesInNotebookAndFindIndex("", notebookDir)

	if #files == 0 then
		showMessage("Notebook is empty")
	else
		shortenedFileNames = getShortenedFileNames(files)
		openDialog("Select File", shortenedFileNames, "openSelectedFile", false)
	end
end

function openSelectedFile(selection)
	if selection < 0 then return end

	local newFilePath = notebookDir .. sep .. files[selection]
	app.openFile(newFilePath)
end

function switchNotebook(locationStr, chooser)
	local currentNotebook = getCurrentNotebook()
	local notebooks, i = getNotebooksAndFindIndex(currentNotebook)

	if i < 0 then
		showMessage(
			"Could not find current notebook. Not switching files. \n(Probably the currently opened file is not in the notebook root path)"
		)
	elseif #notebooks == 0 then
		showMessage("There are no notebooks")
	else
		local newNotebook = notebooks[chooser(notebooks, i)]

		local newNotebookPath = getRootDir() .. sep .. newNotebook
		local files = getFilesInNotebookAndFindIndex("", newNotebookPath)

		if #files == 0 then
			showMessage(locationStr .. " notebook '" .. newNotebook .. "' is empty. Not switching files")
		else
			local newFilePath = newNotebookPath .. sep .. files[1]
			app.openFile(newFilePath)
		end
	end
end

function switchToPreviousNotebook()
	switchNotebook("Previous", function(notebooks, i)
		if i > 1 then
			return i - 1
		else
			return #notebooks
		end
	end)
end

function switchToNextNotebook()
	switchNotebook("Next", function(notebooks, i)
		if i < #notebooks then
			return i + 1
		else
			return 1
		end
	end)
end

function switchPage(chooser)
	local currentFile = getCurrentFileName()
	local files, i = getFilesInNotebookAndFindIndex(currentFile, getCurrentFileFolder())

	if i < 0 then
		showMessage(
			"Could not find current file. Not switching files. \n(Probably the currently opened file is not in the notebook root path)"
		)
	else
		local newFile = files[chooser(files, i)]
		local newFilePath = getCurrentFileFolder() .. sep .. newFile

		app.openFile(newFilePath)
	end
end

function switchToPreviousPage()
	switchPage(function(files, i)
		if i > 1 then
			return i - 1
		else
			return #files
		end
	end)
end

function switchToNextPage()
	switchPage(function(files, i)
		if i < #files then
			return i + 1
		else
			return 1
		end
	end)
end

function getRootDir()
	return notebookRootDir
end

function getNotebooksAndFindIndex(notebookToFind)
	return getDirAndFindIndex(notebookToFind, getRootDir())
end

function getFilesInNotebookAndFindIndex(fileToFind, directory)
	return getDirAndFindIndex(fileToFind, directory)
end

function getDirAndFindIndex(elementToFind, filepath)
	local cmd
	if platform == "linux" then
		cmd = 'ls "' .. filepath .. '"'
	else
		cmd = 'dir /b "' .. filepath .. '"'
	end
	local p = io.popen(cmd)

	local list = {}
	local index = -2

	if p == nil then
		showMessage("Error: Could not read directory. \nTried to run command: " .. cmd)
		return list, index
	end

	local i = 1
	for fileOrDir in p:lines() do
		list[#list + 1] = fileOrDir
		if fileOrDir == elementToFind then
			index = i
		end
		i = i + 1
	end

	return list, index
end

function getCurrentFileFolder()
	local currentFilePath = getCurrentFilePath()
	local index = string.find(currentFilePath, sep .. "[^" .. sep .. "]*$")
	if index == nil then
		index = #currentFilePath
		print("getCurrentFileFolder: index unexpectedly = nil")
	end

	local currentFileFolder = string.sub(currentFilePath, 0, index - 1)
	return currentFileFolder
end

function getCurrentNotebook()
	local folderPath = getCurrentFileFolder()
	local index = string.find(folderPath, sep .. "[^" .. sep .. "]*$")

	if index == nil then
		index = #folderPath
		print("getCurrentNotebook: index unexpectedly = nil")
	end

	local notebook = string.sub(folderPath, index + 1)
	return notebook
end

function getCurrentFileName()
	local currentFilePath = getCurrentFilePath()
	local index = string.find(currentFilePath, sep .. "[^" .. sep .. "]*$")

	if index == nil then
		index = #currentFilePath
		print("getCurrentFileName: index unexpectedly = nil")
	end

	local currentFileFolder = string.sub(currentFilePath, index + 1)
	return currentFileFolder
end

function getCurrentFilePath()
	local doc = app.getDocumentStructure()
	return doc.xoppFilename
end

-- shortens long file names into multiline names
function getShortenedFileNames(files)
	local shortenedFileNames = {}

	local maxLength = string.len(files[1])
	for i = 1, #files do
		if string.len(files[i]) > maxLength then
			maxLength = string.len(files[i])
		end
	end

	local maxTotalWidth = 120
	local targetWidth = math.floor(maxTotalWidth / #files)

	for i = 1, #files do
		shortenedFileNames[i] = shortenFileName(files[i], targetWidth)
	end

	return shortenedFileNames
end

function shortenFileName(filename, targetWidth)
	local index = string.find(filename, ".[^.]*$")
	-- remove .xopp file extension
	local newFileName = string.sub(filename, 1, index - 1)

	if string.len(newFileName) > 3 * targetWidth then
		newFileName = string.sub(newFileName, 1, 3 * targetWidth - 1) .. "..."
		newFileName = stringInsert(newFileName, targetWidth, "\n")
		newFileName = stringInsert(newFileName, 2 * targetWidth + 1, "\n")
	elseif string.len(newFileName) > 2 * targetWidth + 2 then
		newFileName = stringInsert(newFileName, targetWidth, "\n")
		newFileName = stringInsert(newFileName, 2 * targetWidth, "\n")
	elseif string.len(newFileName) > targetWidth + 2 then
		newFileName = stringInsert(newFileName, targetWidth, "\n")
	end

	return newFileName
end

function stringInsert(baseStr, i, insertStr)
	return string.sub(baseStr, 1, i) .. insertStr .. string.sub(baseStr, i + 1)
end
