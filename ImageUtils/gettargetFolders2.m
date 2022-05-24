%
function folderList = gettargetFolders2(loc,date,fnames)
if nargin<3
    fnames = [];
end
cd(loc)
%markpoints?
%vectors?
%what about SI files?
folderList = dir(['*','TSeries-',date,'*']); 
for k = 1:length(folderList)
    folderListNames(k) = str2double(folderList(k).name(end-2:end));
end
if ~isempty(fnames)
    [~,targetFolders]=ismember(fnames,folderListNames);
    folderList = folderList(targetFolders);
end