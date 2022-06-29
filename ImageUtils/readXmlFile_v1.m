%%%function recInfo = readXmlFile_v2_20170730(filename)

filename = 'TSeries-06172022-0138-002.xml';

% read xml file
fclose('all');
x = fopen(filename);
sForm = '%s'; nSamples = 1;
stuffToExtract = {'Frame relativeTime','absoluteTime','.ome.tif'}; %,'bitDepth','dwellTime','laserPower','laserWavelength','micronsPerPixel','objectiveLens','opticalZoom','pmtGain','positionCurrent','Sequence type'};
ste = stuffToExtract;
nFrames = 0;
counter = 0;
tic
while ~feof(x)
    data = textscan(x,sForm,nSamples,'Delimiter','\t');
    counter = counter+1;
    for ii=1:length(ste)
        stf = strfind(data{1}{1},ste{ii});
        if ~isempty(stf)
            
            switch ste{ii}
                case 'Frame relativeTime'
                    qm = strfind(data{1}{1},'"');
                    recInfo(nFrames+1).relativeTime = data{1}{1}(qm(1)+1:qm(2)-1);
                    ste(~cellfun(@isempty,strfind(ste,'date')))=[];
                    break
                case 'absoluteTime'
                    qm = strfind(data{1}{1},'"');
                    recInfo(nFrames+1).absoluteTime = data{1}{1}(qm(1)+1:qm(2)-1);
                    ste(~cellfun(@isempty,strfind(ste,'date')))=[];
                    break
                case '.ome.tif'
                    nFrames = nFrames+1;
            end
        end
    end
end
recInfo(nFrames+1).nFrames = nFrames;
fclose('all')
toc