function [dFF,F0] = compute_dFF(F,fps)%,method)
% Input:
%   F = calcium trace as T x n_rois array
%   fps = frames per second
%   method: 'Konnerth' or 'medfilt'
% Output:
%   dFF = (F-F0)/F0, as an array of same size as F

    eps = 1e-8;
    
    dFF = zeros(size(F));
    F0 = zeros(size(F));
    n_rois = size(F,2);
    for i = 1:n_rois
%         switch method
%             case 'Konnerth'
%                 F0(:,i) = extractBaseline(F(:,i),fps);
%             case 'medfilt'
%                 pts = round((99 / 7.5) * fps); 
%                 F0(:,i) = medfilt1(F(:,i),pts);
%             case 'prctfilt'
                pts = round((99 / 7.5) * fps); 
                %pad F trace
                F_temp = F(:,i);
                value = median(F_temp(1:1e3));
                F_temp = cat(1,repmat(value,pts,1),F_temp);
                value = median(F_temp(end-1e3:end));
                F_temp = cat(1,F_temp,repmat(value,pts,1));
                %25th percentile medfilt
                F_temp = prctfilt1(F_temp,pts);
                %remove padding
                F0(:,i) = F_temp(pts+1:end-pts);
%             otherwise
%         end
        dFF(:,i) = (F(:,i)-F0(:,i))./(F0(:,i)+eps);
    end
end