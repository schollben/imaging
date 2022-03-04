% code to use NormCorre nonrigid registration
% usually used to register dendrite/spine imaging data
%
% 2022-03-01

%%%%%
%initialize parallel
clear 
delete(gcp)
parpool
%%%%%
%initialize params
niter = 1; %number of iterations
gridWidth = 256; %decrease for better registration (in px)
gridHeight = 256; %decrease for better registration (in px)
op = 32; %grid overlap
doimagSpatSamp = 0; %flag to use 0.5x downsampling
datatype = 'BRUKER'; %BRUKER or SI - (SI uses bigtiffreader and file names are different)
%%%%%
%data location and folder(s)
fname{1} = 'TSeries-02232022-1150-002'; %MAKE MORE FLEXIBLE- USE GUI TO DO BATCH?
%%%%%
%find images and 
    
    for z = length(fname)
  
        cd(['D/BRUKER:])
        folderList = dir('*');
        
        for fnum = 1:length(folderList)
            if folderList(fnum).isdir && length(folderList(fnum).name)>2
                
                fileName = [drive,':\',dates,'\',folderList(fnum).name];
                %%%%%%go to directory and make folders
                mkdir(fileName,'\Registered');
                outputDir = [fileName '\Registered\Channel1'];
                outputDir2 = [fileName '\Registered\Channel2'];
                mkdir(outputDir)
                mkdir(outputDir2)
                disp(['reading in data from ' fileName ' and grabbing templates']);
                cd(fileName);
                files  = dir('*.tif');
                
                
                %%%%read metadata
                metadata=ScanImageTiffReader([fileName,'/',files(1).name]).metadata;
                meta = regexp(metadata,'[\w\.]+','match');
                desc = [];
                %check if there 2 channels saved
                loc = find(ismember(meta, 'SI.hChannels.channelSave'));
                if str2double(meta{loc+1})==1
                    disp 'found green channel (1)'
                    desc.ch1 = 'saved';
                end
                if str2double(meta{loc+2})==2
                    disp 'found red channel (2)'
                    desc.ch2 = 'saved';
                    useCh2template = 1;
                else
                    useCh2template = 0;
                    disp 'no red channel'
                end
                
                %check how many ROIs there (and if mROI imaging)
                loc = find(ismember(meta, 'scanimage.mroi.Roi'));
                numROIs = length(loc);
                desc.numROIs = numROIs;
                if numROIs>1
                    disp 'mROI imaging detected'
                end
                %framerate
                loc = find(ismember(meta, 'SI.hRoiManager.scanFrameRate'));
                desc.framerate = str2double(meta(loc+1));
                %zoom angle size
                loc = find(ismember(meta, 'SI.hRoiManager.scanZoomFactor'));
                desc.zoom = str2double(meta(loc+1));
                %actual xy resolution imaged
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%find brightest image across a few stacks
                tic;
                template = [];
                
                imgStack = ScanImageTiffReader([cd,'\',files(round(length(files)/2)).name]).data;
                imgStack = squeeze(imgStack);
                
                %%%%% is there and do you have channel 2 for collecting?
                if useCh2template
                    imgStack = imgStack(:,:,2:2:end);
                end
                dat = squeeze(squeeze(sum(sum(imgStack(:,:,31:end-31),1),2)));
                [a,id] = max(dat);
                template(:,:,1) = mean(imgStack(:,:,id+10:id+10),3);
                
                template(:,:,1) = mean(imgStack(:,:,:),3);
                
                [a,id] = max(sum(sum(template,1),2));
                template = squeeze(template(:,:,id));
                if doimagSpatSamp==1
                    template = imresize(template,.5,'bilinear');
                elseif doimagSpatSamp==0.5
                    template = imresize(template,[512 250],'bilinear');
                end
                toc;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%begin working files
                for fileNum = 1:length(files)
                    
                    imgStack = ScanImageTiffReader([cd,'/',files(fileNum).name]).data;
                    
                    imgStack = squeeze(imgStack);
                    
                    %%%%%2x spatial downsampling
                    if doimagSpatSamp>0
                        if doimagSpatSamp==1
                            resamppx = size(imgStack,1)/2;
                            resamppy = size(imgStack,2)/2;
                        elseif doimagSpatSamp==0.5
                            resamppx = 512;
                            resamppy = 250;
                        end
                        for frnum = 1:size(imgStack,3)
                            im = squeeze(imgStack(:,:,frnum));
                            if doimagSpatSamp==1
                                im = imresize(im,0.5);
                            elseif doimagSpatSamp==0.5
                                im = imresize(im,[512 250]);
                            end
                            im(im<0) = 0;
                            imgStack(1:resamppx,1:resamppy,frnum) = im;
                        end
                        imgStack = imgStack(1:resamppx,1:resamppy,:);
                        disp(['spat resamp and thresh done'])
                    end
                    
                    %%%%%%split channels if needed or wanted
                    if useCh2template
                        ch1Stack = imgStack(:,:,1:2:end);
                        imgStack = imgStack(:,:,2:2:end);
                    end
                    [height,width,depth] = size(imgStack);
                    
                    
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%
                    if strcmp(regtype,'downsample')
                        
                        tic;
                        regOffsetsX = zeros(depth,1);
                        regOffsetsY = zeros(depth,2);
                        for r=1:length(downsampleRates)
                            sampRate = downsampleRates(r);
                            if r>1
                                prevsampRate = downsampleRates(r-1);
                            end
                            disp(['registering images, iteration ' num2str(r)]);
                            downHeight = height*sampRate;
                            downWidth = width*sampRate;
                            
                            templateImg = imresize(template, [downHeight,downWidth]);
                            for d=1:depth
                                
                                regImg = imresize(imgStack(:,:,d), [downHeight,downWidth]);
                                
                                if r==1
                                    %initial offset
                                    minOffsetY = -round(maxMovement*downHeight/2);
                                    maxOffsetY = round(maxMovement*downHeight/2);
                                    
                                    minOffsetX = -round(maxMovement*downWidth/2);
                                    maxOffsetX = round(maxMovement*downWidth/2);
                                    
                                else
                                    %we are refining an earlier offset
                                    minOffsetY = regOffsetsY(d)*sampRate - sampRate/prevsampRate/2;
                                    maxOffsetY = regOffsetsY(d)*sampRate + sampRate/prevsampRate/2;
                                    
                                    minOffsetX = regOffsetsX(d)*sampRate - sampRate/prevsampRate/2;
                                    maxOffsetX = regOffsetsX(d)*sampRate + sampRate/prevsampRate/2;
                                end
                                bestCorrValue = -1;
                                bestCorrX = 0;
                                bestCorrY = 0;
                                for y=minOffsetY:maxOffsetY
                                    for x=minOffsetX:maxOffsetX
                                        %determine the offsets in X and Y for which the overlap
                                        %between the images correlates best
                                        subTemplateY1 = 1+max(y,0);
                                        subTemplateY2 = downHeight+min(y,0);
                                        subTemplateX1 = 1+max(x,0);
                                        subTemplateX2 = downWidth+min(x,0);
                                        
                                        subRegY1 = 1+max(-y,0);
                                        subRegY2 = downHeight+min(-y,0);
                                        subRegX1 = 1+max(-x,0);
                                        subRegX2 = downHeight+min(-x,0);
                                        
                                        subTemplateImg = templateImg(subTemplateY1:subTemplateY2,...
                                            subTemplateX1:subTemplateX2);
                                        subRegImg = regImg(subRegY1:subRegY2,subRegX1:subRegX2);
                                        
                                        corrValue = corr2(subRegImg, subTemplateImg);
                                        if corrValue > bestCorrValue
                                            bestCorrX = x;
                                            bestCorrY = y;
                                            bestCorrValue = corrValue;
                                        end
                                    end
                                end
                                regOffsetsY(d) = bestCorrY*1/sampRate;
                                regOffsetsX(d) = bestCorrX*1/sampRate;
                            end
                        end
                        
                        disp('Registration offsets in (Y,X) format:');
                        for d=1:depth
                            img = imgStack(:,:,d);
                            shiftedY1 = 1+max(regOffsetsY(d),0);
                            shiftedY2 = height+min(regOffsetsY(d),0);
                            shiftedX1 = 1+max(regOffsetsX(d),0);
                            shiftedX2 = width+min(regOffsetsX(d),0);
                            
                            subRegY1 = 1+max(-regOffsetsY(d),0);
                            subRegY2 = height+min(-regOffsetsY(d),0);
                            subRegX1 = 1+max(-regOffsetsX(d),0);
                            subRegX2 = width+min(-regOffsetsX(d),0);
                            
                            shiftedImg = ones(height,width)*double(min(min(img)));
                            shiftedImg(shiftedY1:shiftedY2,shiftedX1:shiftedX2) = img(subRegY1:subRegY2,...
                                subRegX1:subRegX2);
                            imgStack(:,:,d) = shiftedImg;
                            if useCh2template
                                img = ch1Stack(:,:,d);
                                shiftedImg = ones(height,width)*double(min(min(img)));
                                shiftedImg(shiftedY1:shiftedY2,shiftedX1:shiftedX2) = img(subRegY1:subRegY2,...
                                    subRegX1:subRegX2);
                                ch1Stack(:,:,d) = shiftedImg;
                            end
                        end
                        toc;
                        
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%
                    elseif strcmp(regtype,'nonrigid')
                        
                        disp go
                        options_rigid = NoRMCorreSetParms('d1',size(imgStack,1),'d2',size(imgStack,2),...
                            'grid_size',[gridWidth,gridHeight],'overlap_pre',...
                            op,'bin_width',50,'max_shift',100,'us_fac',50,'iter',niter);
                        options_rigid.use_parallel = 1;
                        tic;
                        [M_final,shifts,~] = normcorre(imgStack,options_rigid,template);
                        imgStack = M_final;
                        clear M_final
                        if useCh2template
                            %applying red shifts to green
                            M_final = apply_shifts(ch1Stack,shifts,options_rigid);
                            ch1Stack = M_final;
                            clear M_final
                        end
                        toc;
                        
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%save current imgStack to outputDir
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    disp('Saving tiff stack');
                    filename = [outputDir '\' sprintf('%06i',fileNum) '.tif'];
                    filename2 = [outputDir2 '\' sprintf('%06i',fileNum) '.tif'];
                    %save desc data
                    save([fileName '\Registered\desc'],'desc')
                    for d = 1:depth
                        if d==1
                            if useCh2template
                                imwrite(uint16(ch1Stack(:,:,d))',filename,'tif','writemode','overwrite');
                                imwrite(uint16(imgStack(:,:,d))',filename2,'tif','writemode','overwrite');
                            else
                                imwrite(uint16(imgStack(:,:,d))',filename,'tif','writemode','overwrite');
                            end
                        else
                            if useCh2template
                                imwrite(uint16(ch1Stack(:,:,d))',filename,'tif','writemode','append');
                                imwrite(uint16(imgStack(:,:,d))',filename2,'tif','writemode','append');
                            else
                                imwrite(uint16(imgStack(:,:,d))',filename,'tif','writemode','append');
                            end
                        end
                    end
                    
                    disp(['Done, Saved in  ', outputDir]);
                    
                end
            end
        end
    end
end

