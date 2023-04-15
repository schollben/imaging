%
function folderList = gettargetFolders2(loc,date,fnames,filetype)
if nargin<3
    fnames = [];
    filetype = 'TSeries';
end
cd(loc)
if strcmp(loc(4:end-1),'BRUKER')
    folderList = dir(['*','TSeries-',date,'*']);
elseif strcmp(loc(4:end-1),'SCANIMAGE')
    folderList = dir(['*','TSeries_',date(end-3:end),'-',date(1:2),'-',date(3:4),'*']);
end
% folderList = dir(['*',filetype,'-',date,'*']);

if isempty(folderList)

disp 'no data'

else    

    for k = 1:length(folderList)
        folderListNames(k) = str2double(folderList(k).name(end-2:end));
    end

    if ~isempty(fnames)
        [~,targetFolders]=ismember(fnames,folderListNames);
        targetFolders = targetFolders(targetFolders~=0);
        folderList = folderList(targetFolders);
    end

end