%
function folderList = gettargetFolders2(loc,date,fnames)
if nargin<3
    fnames = [];
end
cd(loc)

% % if strcmp(loc(4:end-1),'BRUKER')
% %     folderList = dir(['*','TSeries-',date,'*']);
% % elseif strcmp(loc(4:end-1),'SCANIMAGE')
% %     folderList = dir(['*','TSeries_',date(end-3:end),'-',date(1:2),'-',date(3:4),'*']);
% % end

folderList = dir(['*','TSeries-',date,'*']);


if isempty(folderList)

disp 'no data'

else    

    for k = 1:length(folderList)
        folderListNames(k) = str2double(folderList(k).name(end-2:end));
    end

    if ~isempty(fnames)
        [~,targetFolders]=ismember(fnames,folderListNames);
        folderList = folderList(targetFolders);
    end

end