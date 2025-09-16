--- Change to your needs:
notebookRootDir = ""
sep = "\\"     --- seperator in filepaths: "\\" should work for windows, for linux try "/"
--------------------------------------------

--- Shortcuts and icons can be changed here
function initUi()
  app.registerUi({["menu"] = "Previous Page", ["callback"] = "switchToPreviousPage", ["accelerator"]="<Alt>Left", ["toolbarId"] = "PreviousPage",  ["iconName"] = "pan-start-symbolic"});
  app.registerUi({["menu"] = "Next Page", ["callback"] = "switchToNextPage", ["accelerator"]="<Alt>Right", ["toolbarId"] = "NextPage",  ["iconName"] = "pan-start-symbolic-rtl"});
  app.registerUi({["menu"] = "Previous Notebook", ["callback"] = "switchToPreviousNotebook", ["accelerator"]="<Alt><Shift>Left", ["toolbarId"] = "PreviousNotebook",  ["iconName"] = "pan-up-symbolic"});
  app.registerUi({["menu"] = "Next Notebook", ["callback"] = "switchToNextNotebook", ["accelerator"]="<Alt><Shift>Right", ["toolbarId"] = "NextNotebook",  ["iconName"] = "pan-down-symbolic"});
  -- app.registerUi({["menu"] = "Select Notebook", ["callback"] = "selectNotebook", ["accelerator"]="<Ctrl>k"});
  app.registerUi({["menu"] = "Select File", ["callback"] = "selectFile", ["accelerator"]="<Alt><Shift>k", ["toolbarId"] = "SelectFile",  ["iconName"] = "user-bookmarks"});

end



function selectFile()
  local notebooks = getNotebooksAndFindIndex()

  local selection = app.msgbox("Select Notebook", notebooks)

  local notebookDir = getRootDir() .. sep .. notebooks[selection]
  local files = getFilesInNotebookAndFindIndex("", notebookDir)

  local shortenedFileNames = getShortenedFileNames(files)

  local selectedFile = app.msgbox("Select File", shortenedFileNames)

  local newFilePath = notebookDir .. sep .. files[selectedFile]

  app.openFile(newFilePath)
end


---unused
function selectNotebook()
  local notebooks = getNotebooksAndFindIndex()

  local selection = app.msgbox("Select Notebook", notebooks)

  local notebookDir = getRootDir() .. sep .. notebooks[selection]
  local files = getFilesInNotebookAndFindIndex("", notebookDir)
  local newFilePath = notebookDir .. sep .. files[1]

  app.openFile(newFilePath)
end

function switchToPreviousNotebook()
  local currentNotebook = getCurrentNotebook()
  local notebooks, i = getNotebooksAndFindIndex(currentNotebook)
  
  local newNotebook
  if i > 1 then
    newNotebook = notebooks[i - 1]
  else
    newNotebook = notebooks[#notebooks]
  end

  local newNotebookPath = getRootDir() .. sep .. newNotebook  
  local files, j = getFilesInNotebookAndFindIndex("", newNotebookPath)

  local newFilePath = newNotebookPath .. sep .. files[1]

  app.openFile(newFilePath)
end

function switchToNextNotebook()
  local currentNotebook = getCurrentNotebook()
  local notebooks, i = getNotebooksAndFindIndex(currentNotebook)
  
  local newNotebook
  if i < #notebooks then
    newNotebook = notebooks[i + 1]
  else
    newNotebook = notebooks[1]
  end

  local newNotebookPath = getRootDir() .. sep .. newNotebook  
  local files, j = getFilesInNotebookAndFindIndex("", newNotebookPath)

  local newFilePath = newNotebookPath .. sep .. files[1]

  app.openFile(newFilePath)
end



function switchToPreviousPage()
  local currentFile = getCurrentFileName()
  local files, i = getFilesInNotebookAndFindIndex(currentFile, getCurrentFileFolder())
  
  local newFile
  if i > 1 then
    newFile = files[i - 1]
  else
    newFile = files[#files]
  end

  local newFilePath = getCurrentFileFolder() .. sep .. newFile

  app.openFile(newFilePath)
end


function switchToNextPage()
  local currentFile = getCurrentFileName()
  local files, i = getFilesInNotebookAndFindIndex(currentFile, getCurrentFileFolder())
  
  local newFile
  if i < #files then
    newFile = files[i + 1]
  else
    newFile = files[1]
  end

  
  local newFilePath = getCurrentFileFolder() .. sep .. newFile

  app.openFile(newFilePath)
end


function getRootDir()
  return notebookRootDir
end

function getNotebooksAndFindIndex(notebookToFind)
  local p = io.popen('dir /b "' .. getRootDir() .. '"')

  local notebookList = {}
  local index = -2
 
  local i = 1
  for notebook in p:lines() do
    notebookList[#notebookList+1] = notebook
    if notebook == notebookToFind then
      index = i
    end
    i = i + 1
  end

  return notebookList, index
end

function getFilesInNotebookAndFindIndex(fileToFind, directory)
  
  local p = io.popen('dir /b "' .. directory .. '"')

  local fileList = {}
  local index = -2
 
  local i = 1
  for file in p:lines() do
    fileList[#fileList+1] = file
    if file == fileToFind then
      index = i
    end
    i = i + 1
  end

  return fileList, index
end


function getCurrentFileFolder()

  local currentFilePath = getCurrentFilePath()
  local index = string.find(currentFilePath, sep .. "[^" .. sep .. "]*$")
  if index == nil then
    index = #currentFilePath
  end
  
  local currentFileFolder = string.sub(currentFilePath, 0, index - 1)
  return currentFileFolder

end

function getCurrentNotebook()
  local folderPath = getCurrentFileFolder()
  local index = string.find(folderPath, sep .. "[^" .. sep .. "]*$")

  local notebook = string.sub(folderPath, index + 1)
  return notebook
end

function getCurrentFileName()

  local currentFilePath = getCurrentFilePath()
  local index = string.find(currentFilePath, sep .. "[^" .. sep .. "]*$")
  if index == nil then
    index = #currentFilePath
  end

  local currentFileFolder = string.sub(currentFilePath, index + 1)
  return currentFileFolder

end


function getCurrentFilePath()

  local doc = app.getDocumentStructure()
  return doc.xoppFilename

end

function getShortenedFileNames(files)
  local shortenedFileNames = {}
  
  local maxLength = string.len(files[1])
  for i = 1, #files do
    if string.len(files[i]) > maxLength then
      maxLength = string.len(files[i])
    end
  end

  local estimatedTotalWidth = #files * maxLength
  local maxTotalWidth = 120
  local targetWidth = math.floor(maxTotalWidth / #files)

  for i = 1, #files do
    shortenedFileNames[i] = shortenFileName(files[i], targetWidth)
  end

  return shortenedFileNames
end

function shortenFileName(filename, targetWidth) 
  local index = string.find(filename, ".[^.]*$")
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