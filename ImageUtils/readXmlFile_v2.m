%Geffen lab code
%edited by B Scholl 051722
%
%
function recInfo = readXmlFile_v2(filename)
% read xml file
fclose('all');
x = fopen(filename);
sForm = '%s'; nSamples = 1;
stuffToExtract = {
    '.ome.tif',...
    'framePeriod',...
    'date',...
    'bitDepth',...
    'dwellTime',...
    'laserPower',...
    'laserWavelength',...
    'micronsPerPixel',...
    'objectiveLens',...
    'opticalZoom',...
    'pmtGain',...
    'positionCurrent',...
    'Sequence type'};
ste = stuffToExtract;
% nFrames = 0;
counter = 0;
tic
while ~counter % ~feof(x)
    
    data = textscan(x,sForm,nSamples,'Delimiter','\t');
    for ii=1:length(ste)
        stf = strfind(data{1}{1},ste{ii});
        if ~isempty(stf)
            
            switch ste{ii}
                case 'date'
                    qm = strfind(data{1}{1},'"');
                    recInfo.date = data{1}{1}(qm(3)+1:qm(4)-1);
                    ste(~cellfun(@isempty,strfind(ste,'date')))=[];
                    break
                case 'framePeriod'
                    qm = strfind(data{1}{1},'"');
                    recInfo.framePeriod = data{1}{1}(qm(3)+1:qm(4)-1);
                    ste(~cellfun(@isempty,strfind(ste,'date')))=[];
                    break
                case 'bitDepth'
                    qm = strfind(data{1}{1},'"');
                    recInfo.bitDepth = str2double(data{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'bitDepth')))=[];
                    break
                case 'dwellTime'
                    qm = strfind(data{1}{1},'"'); 
                    recInfo.dwellTime = str2double(data{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'dwellTime')))=[];
                    break
                case 'laserPower'
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    recInfo.pockels = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'laserPower')))=[];
                    break
                case 'laserWavelength'
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    recInfo.laserWavelength = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'laserWavelength')))=[];
                    break
                case 'micronsPerPixel'
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    mpp(1) = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    mpp(2) = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    recInfo.micronsPerPixel = mpp;
                    ste(~cellfun(@isempty,strfind(ste,'micronsPerPixel')))=[];
                    break
                case 'objectiveLens'
                    qm = strfind(data{1}{1},'"');
                    recInfo.objective = data{1}{1}(qm(3)+1:qm(4)-1);
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    recInfo.objectiveMag = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    recInfo.objectiveNA = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'objectiveLens')))=[];
                    break
                case 'opticalZoom'
                    qm = strfind(data{1}{1},'"');
                    recInfo.opticalZoom = str2double(data{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'opticalZoom')))=[];
                    break
                case 'pmtGain'
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    recInfo.PMTgain_ch01 = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    qm = strfind(dat{1}{1},'"');
                    recInfo.PMTgain_ch02 = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'pmtGain')))=[];
                    break
                case 'positionCurrent'
                    for zz=1:8
                        dat = textscan(x,sForm,nSamples,'Delimiter','\t');
                    end
                    qm = strfind(dat{1}{1},'"');
                    recInfo.Zdepth = str2double(dat{1}{1}(qm(3)+1:qm(4)-1));
                    ste(~cellfun(@isempty,strfind(ste,'ZAxis')))=[];
                    break
                case 'Sequence type'
                    qm = strfind(data{1}{1},'"');
                    recInfo.timeOfRec = data{1}{1}(qm(5)+1:qm(6)-1);
                    ste(~cellfun(@isempty,strfind(ste,'Sequence type')))=[];
                    break
%                 case '.ome.tif'
%                     nFrames = nFrames+1;                   
            end

            counter = counter+1;
        
        end
    end
end
% recInfo.nFrames = nFrames;
fclose('all')
toc