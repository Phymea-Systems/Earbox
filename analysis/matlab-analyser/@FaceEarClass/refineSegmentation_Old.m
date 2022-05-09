function output = refineSegmentation_Old(obj)

import efa_descriptor.*

L = obj.highCutSegmentationLabels;
Iwat = obj.highCutSegmentation;

if obj.USECOLORMASK
    fert_mask = imclose(obj.fertileZoneMask,strel('disk',10));
    L = L.*fert_mask;
    Iwat = Iwat.*fert_mask;
end

% Create the list of elements : 
firstlayer.imageLabel = bwlabel(imerode(L,strel('disk',1)));

firstlayer.idx = 1:(max(firstlayer.imageLabel(:)));
lastlayer.imageLabel = bwlabel(Iwat);
lastlayer.idx = uint32(uint32(max(firstlayer.idx)) + uint32(1:+max(lastlayer.imageLabel(:))));
ss = regionprops(firstlayer.imageLabel,lastlayer.imageLabel,'Centroid','PixelValues','BoundingBox','Image');


subzoneidx = 1;
cleanzoneidx = 1;
cleanlayer = [];
sublayer = [];
for cellidx = firstlayer.idx
    
    Itmp = ss(cellidx).Image;
    Itmp(Itmp) = ss(cellidx).PixelValues;
    Itmp = bwareaopen(Itmp,350);
    [Itmp,num] = bwlabeln(Itmp);
    idx = find(circularity(Itmp)<=0.4);
    for i = idx'
        Itmp(Itmp==i)=0;
    end
    [Itmp,num] = bwlabeln(Itmp);
    
                
    if num<1
        continue
    end
    
    if (num==1) && (circularity(Itmp)>0.6)
        cleanlayer(cleanzoneidx).Centroid = ss(cellidx).Centroid;
        cleanlayer(cleanzoneidx).BoundingBox = ss(cellidx).BoundingBox;
        cleanlayer(cleanzoneidx).Image = Itmp;
        cleanlayer(cleanzoneidx).idxRef = cellidx;
        cleanzoneidx = cleanzoneidx+1;
    end

    
    % get subzone indexes : 
    sub_indices = unique(Itmp(Itmp>0));
    N = max(sub_indices); % nb of sub-zones
    
    
    
    if N>1 && N<10
        
        % number of possible combination : 
        nbC = 2^(N) - 1;
        
        combinaisons = zeros(nbC,N); % combination table :
        
        % enumerate indexes :  
        searchidx = zeros(N);
        for n = 1:N
            searchidx(:,n) = circshift(sub_indices,-(n-1));
            searchidx(N-(n-2):end,n) = 0;
        end
        
        done = zeros(size(searchidx)); % table of indexes already explored : 
        
        % enumerate combination : 
        for n = 1:nbC
            kk=1;
            indice = max(setdiff(searchidx(:,kk),done(:,kk)));
            combinaisons(n,kk) = indice;
            timeout = tic;
            while any(setdiff(searchidx(:,kk+1),done(:,kk+1)) > indice)
                if toc(timeout) > 120
                    error('timeout in missplaced kernel enumeration')
                end
                indice = max(setdiff(searchidx(:,kk+1),done(:,kk+1)));
                kk=kk+1;
                combinaisons(n,kk) = indice;
                if kk == N
                    break;
                end
            end
            done(1,kk) = indice;
            done(:,kk) = circshift(done(:,kk),1);
            done(:,kk+1:end) = zeros(size(done(:,kk+1:end)));
        end
        
        % spatial validation of combinaition (have to form a unique zero)
        
        for n = 1:nbC
            Ivalid = zeros(size(Itmp));
            souszones = combinaisons(n,:);
            souszones = souszones(souszones>0);
            for k = 1:length(souszones)
                Ivalid(Itmp==souszones(k)) = 1;
            end
            Ivalid = imdilate(Ivalid,strel('disk',1));
            [~,num] = bwlabeln(Ivalid);
            if num ==1
                [idxy,idxx] = find(Ivalid);
                cy = mean(idxy);
                cx = mean(idxx);
                if Ivalid(ceil(cy),ceil(cx))
                    bb = ss(cellidx).BoundingBox;
                    if bb(3) ~= size(Ivalid,2)
                        keyboard
                    end
                    sublayer(subzoneidx).Centroid = [bb(2) bb(1)] + [cx,cy];
                    sublayer(subzoneidx).BoundingBox = ss(cellidx).BoundingBox;
                    sublayer(subzoneidx).Image = Ivalid;
                    sublayer(subzoneidx).idxRef = cellidx;
                    sublayer(subzoneidx).combinaison = combinaisons(n,:);
                    subzoneidx = subzoneidx+1;
                end
            end
        end
        
    end
end

out_efd = zeros(length(cleanlayer),32);
out_area = zeros(length(cleanlayer),1);
out_equiv = zeros(length(cleanlayer),1);
for i = 1:length(cleanlayer)
    toto = cell2mat(bwboundaries(cleanlayer(i).Image,8,'noholes'));
    efd = fEfourier(toto,8,true,true);
    out_efd(i,:) = efd(:)';
    out_area(i) = sum(sum(cleanlayer(i).Image));
    tss = regionprops(cleanlayer(i).Image,'EquivDiameter');
    out_equiv(i) = cat(1,tss.EquivDiameter);
end
efdRef = mean(out_efd);
areaRef = median(out_area);
equivRef = median(out_equiv);
% Show zones to treat : 
Ititi = zeros(size(Iwat>0));
for i = 1:length(cleanlayer)
    toto = cell2mat(bwboundaries(cleanlayer(i).Image,8,'noholes'));
    bb = cleanlayer(i).BoundingBox;
    [X,Y] = meshgrid(ceil(bb(1)):ceil(bb(1))+bb(3)-1,ceil(bb(2)):ceil(bb(2))+bb(4)-1);
    idx = sub2ind(size(Ititi),Y,X);
    Ititi(idx) = cleanlayer(i).Image.*i + Ititi(idx);
end
cleanImageLabel = Ititi;


% Check if needs correction for sublayers and initialize : 
Itoto = zeros(size(Iwat>0));
needtobecorrected = 0;

if ~isempty(sublayer)

    idxlist = cat(1,sublayer.idxRef);
    idxcheck = unique(idxlist);

    correctedlayer = [];
    %         allaa = [];
    needtobecorrected = 1;
    
end

% Correct sublayers : 
if ~isempty(out_equiv) && needtobecorrected == 1
    for i = idxcheck'
        subidx = find(idxlist == i);
        k=1;
        err2=[];aa=[]; efd=[]; equiv = [];
        
        for j = subidx'
            toto = cell2mat(bwboundaries(sublayer(j).Image));
            efd = fEfourier(toto,8,true,true);
            tss = regionprops(sublayer(j).Image,'EquivDiameter','BoundingBox');
            bboxratio = tss.BoundingBox(3) / tss.BoundingBox(4);
            equiv = tss.EquivDiameter;
            aa(k,:) = [double(std(out_equiv)-sum(std([out_equiv;equiv]))),...
                double(sum(std(out_efd))-sum(std([out_efd; efd(:)']))),...
                double(0.1*(1-circularity(sublayer(j).Image))),...
                double(0.04*(numel(sublayer(j).combinaison) - sum(sublayer(j).combinaison > 0)))];
            if bboxratio > 1.5; aa(k,1) = 100; end;
            err2(k) = double(aa(1)^2 + aa(2)^2 + aa(4)^2 + aa(3)^4);
            err2(k);
            bb = sublayer(j).BoundingBox;
            [X,Y] = meshgrid(ceil(bb(1)):ceil(bb(1))+bb(3)-1,ceil(bb(2)):ceil(bb(2))+bb(4)-1);
            idx = sub2ind(size(Itoto),Y,X);
            Itoto(idx) = (sublayer(j).Image.*(sum(((efdRef - efd(:)').^2)) + (sum(sum(sublayer(j).Image))-areaRef).^2)) + Itoto(idx);

            Itoto(idx) = Itoto(idx) - (sublayer(j).Image.*(sum(((efdRef - efd(:)').^2)) + (sum(sum(sublayer(j).Image))-areaRef).^2));
            k=k+1;
        end
        
        
        [minval,minidx] = min(sum(aa.^2,2));
        scoretable = sum(aa.^2,2)';
        if minval > 0.1
            continue
        end
        best = minidx;
        
        scoretable(scoretable > 0.1) = 100;
        if aa(best,4) > 0
            ti = [];
            matchtable = [];
            k = 1;
            for j = subidx'
                tI = imerode(sublayer(j).Image,strel('disk',3));
                ti(k,:) = tI(:);
                k=k+1;
            end
            for k = 1:size(ti,1)
                for l = 1:size(ti,1)
                    matchtable(k,l) = sum(ti(k,:) & ti(l,:)) > 0;
                end
            end
            matchtable = logical(matchtable);
            timeout = tic;
            while any(scoretable ~= 100)
                if toc(timeout) > 120
                    error('timeout in kernel correction')
                end
                best = minidx;
                scoretable(best);
                
                scoretable(matchtable(best,:)) = 100;
                [minval,minidx] = min(scoretable);
                
                troi = zeros(size(obj.mask));
                troi(idx) = sublayer(subidx(best)).Image;
                correctss = regionprops(troi,'Centroid','BoundingBox','Image','SubArrayIdx');
                correctedlayer(end+1).Centroid  = correctss.Centroid ;
                correctedlayer(end).BoundingBox  = correctss.BoundingBox;
                correctedlayer(end).Image  = correctss.Image;
                correctedlayer(end).SubArrayIdx  = correctss.SubarrayIdx;
                
                bb = sublayer(subidx(best)).BoundingBox;
                [X,Y] = meshgrid(ceil(bb(1)):ceil(bb(1))+bb(3)-1,ceil(bb(2)):ceil(bb(2))+bb(4)-1);
                idx = sub2ind(size(Itoto),Y,X);
                Itoto(idx) = imerode(sublayer(subidx(best)).Image,strel('disk',3)) + Itoto(idx);
                
            end
        else
            
            troi = zeros(size(obj.mask));
            troi(idx) = sublayer(subidx(best)).Image;
            correctss = regionprops(troi,'Centroid','BoundingBox','Image','SubArrayIdx');
            correctedlayer(end+1).Centroid  = correctss.Centroid ;
            correctedlayer(end).BoundingBox  = correctss.BoundingBox;
            correctedlayer(end).Image  = correctss.Image;
            correctedlayer(end).SubArrayIdx  = correctss.SubarrayIdx;
            
            
            toto = cell2mat(bwboundaries(sublayer(subidx(best)).Image));
            efd = fEfourier(toto,8,true,true);
            tss = regionprops(sublayer(subidx(best)).Image,'EquivDiameter');
            equiv = tss.EquivDiameter;
            out_efd = [out_efd; efd(:)'];
            out_equiv = [out_equiv; equiv];
            
            bb = sublayer(subidx(best)).BoundingBox;
            [X,Y] = meshgrid(ceil(bb(1)):ceil(bb(1))+bb(3)-1,ceil(bb(2)):ceil(bb(2))+bb(4)-1);
            idx = sub2ind(size(Itoto),Y,X);
            Itoto(idx) = sublayer(subidx(best)).Image + Itoto(idx);
        end
        
    end
end

output = cleanImageLabel>0|Itoto>0;
end
