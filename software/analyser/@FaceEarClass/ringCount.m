function output = ringCount(obj)
        
        % Getting the right grains : 
        profile = obj.earDiameterProfile;
        RefSeg = (obj.refinedSegmentation);
        distmap = bwdist(~obj.mask);
        ss = regionprops(RefSeg,'PixelIdxList','Centroid');
        cc = cat(1,ss.Centroid);
        bordValid = true(length(ss),1);
        for i = 1:length(ss)
            if distmap(ceil(cc(i,2)),ceil(cc(i,1))) < max(profile)/7;
                bordValid(i) = false;
                RefSeg(ss(i).PixelIdxList) = 0;
            end
        end
        
        % All initial masks : 
        Temp_Mask = obj.mask - RefSeg;
        Max_Mask = zeros(1,size(RefSeg,2));
        DistMap = obj.dist2AxisMap;
        IsPositive = obj.upOrDownMap==1;
        IsNegative = obj.upOrDownMap==-1;
        DiffCosPositive = [];
        DiffCosNegative = [];
        
        for i = 1:size(IsPositive,2)
            DiffCosPositive(:,i) = diff(acos(double(DistMap(:,i).*IsPositive(:,i) ./ max([1 max((DistMap(:,i).*IsPositive(:,i)))]))));
            DiffCosNegative(:,i) = diff(acos(double(DistMap(:,i).*IsNegative(:,i) ./ max([1 max((DistMap(:,i).*IsNegative(:,i)))]))));
        end
        DiffCosPositive(DiffCosPositive<0) = 0;
        DiffCosPositive(end+1,:) = 0;
        DiffCosNegative = padarray(DiffCosNegative,1,0,'pre');
        DiffCosNegative(DiffCosNegative>0) = 0;
        for i = 1:size(IsPositive,2)
            CosMap(:,i) = abs(DiffCosPositive(:,i).*max((DistMap(:,i).*IsPositive(:,i))) + DiffCosNegative(:,i).*max((DistMap(:,i).*IsNegative(:,i))));
        end
        for i = 2:(size(CosMap,1)*size(CosMap,2))-1
            if CosMap(i) == 0
                CosMap(i) = min([CosMap(i-1) CosMap(i+1)]);
            end
        end
        
        for i = 1:size(obj.mask,2)
        Max_Mask(i) = max(bwlabeln(Temp_Mask(:,i)));
        end
        Relative_Mask = (sum(RefSeg.*CosMap)./(Max_Mask-1));
        vals = (profile.*pi ./ (Relative_Mask*1.2));
        coherentValid = true(length(vals),1);
        coherentValid(isnan(vals)) = false;
        coherentValid(isinf(vals)) = false;
        timeout = tic;
        while (std(vals(coherentValid))/mean(vals(coherentValid)) > 0.2) & (toc(timeout) < 10)
        coherentValid = abs(vals - mean(vals(coherentValid))) < (1.8*std(vals(coherentValid)));
        end
        vals  = vals(coherentValid);
        
        
        binvect = 1:length(vals)/9:length(vals);
        binvect(end+1) = length(vals);
        
        if binvect == 0
            warning('No ranks found');
            output.ringCountAvgBot = 0;
            output.ringCountAvgMid = 0;
            output.ringCountAvgTop = 0;
        else
        
        for i = 1:length(binvect)-1
        binval(i) = mean(vals(ceil(binvect(i)):ceil(binvect(i+1))));
        end
        
        % Store in outputs : 
        output.ringCountAvgBot = mean(binval(1:min([3 size(binval,2)])));
        output.ringCountAvgMid = mean(binval(min([4 size(binval,2)]):min([6 size(binval,2)])));
        output.ringCountAvgTop = mean(binval(min([7 size(binval,2)]):min([9 size(binval,2)])));
        end
end