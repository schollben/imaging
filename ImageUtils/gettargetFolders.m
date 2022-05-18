%
function folderList = gettargetFolders(loc,fnames)

cd(loc)
folderList = dir(['*TSeries*']); % EVENTUALLY WILL NEED TO EXAMINE MARKPOINTS AS WELL
for k = 1:length(folderList)
    folderListNames(k) = str2double(folderList(k).name(end-2:end));
end
[~,targetFolders]=ismember(fnames,folderListNames);
folderList = folderList(targetFolders);