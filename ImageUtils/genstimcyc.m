% function []=genstimcyc(stimInfo)
% example: genstimcyc([2 0.25 0])
% [stimDur prestim poststim]
%
function []=genstimcyc(stimInfo)

global ce

if nargin==0
    stimDur = 2;
    pre = 0;
    slag = 0;
else
    stimDur = stimInfo(1);
    pre = stimInfo(2);
    slag = stimInfo(3);
end


if isfield(ce,'stimOn2pFrame')
    stimID = ce(1).stimID;
    if floor(length(stimID)/length(unique(stimID)))>2 %dont run unless many trials per stim condition

        stimOn2pFrame = ce(1).stimOn2pFrame;
        uniqStims = ce(1).uniqStims;
        ntrials = floor(length(stimID) / length(uniqStims));

        %convert time in sec to frames ( which might be downsampled)
        stimDur = round(stimDur / ce(1).framePeriod);
        pre = round(pre / ce(1).framePeriod);
        slag = round(slag / ce(1).framePeriod);


        for cc = 1:length(ce)

            ce(cc).cyc = [];
            ce(cc).cyc = zeros( length(uniqStims), ntrials, stimDur + pre);
            ce(cc).cycspk = ce(cc).cyc;

            dff = ce(cc).dff;
            if isfield(ce,'spikeInference')
                spk = ce(cc).spikeInference;
            end

            trialList = zeros(1,length(uniqStims));

            for ii = 1:length(stimOn2pFrame)

                if sum(trialList==ntrials)~=uniqStims

                    tt = stimOn2pFrame(ii) - pre + 1 + slag : stimOn2pFrame(ii) + stimDur + slag;

                    ind = find(uniqStims==stimID(ii));

                    trialList(ind) = trialList(ind)+1;

                    if tt(end) < length(dff)
                        f = dff(tt);
                        if isfield(ce,'spikeInference')
                            s = spk(tt);
                        end
                    else
                        f = NaN(length(tt),1);
                        s = NaN(length(tt),1);
                    end

                    ce(cc).cyc(ind,trialList(ind),:) = f;
                    if isfield(ce,'spikeInference')
                        ce(cc).cycspk(ind,trialList(ind),:) = s;
                    end
                end
            end

            fprintf(num2str(cc))

        end
    end
end






