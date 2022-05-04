classdef FaceEarClass < handle
    
    % For submitted variables on paper : 
    properties (Constant)
        
          % Change value if need paper outputs : 
          % Are we on the paper ears for outputs test : 
          paper = 0;
          % Which path are we on : 
          path_for_paper = 'D:\Path-to-my-ear-folder-for-test\B1E2-Face4';
          % More variables : 
          face_for_paper = 4;
          paper_grain_dimensions = 0;

    end
    
    properties (Access = public)
        max_PX2CM = 0.00996;
        min_PX2CM = 0.00998;
        dirpath;
        code;
        numero_face;
        ring_apical_truth = 0;
        ring_count = 0;
        USECOLORMASK = true ;
        USETEMPFOLDER = false;
        SEGMENTATIONTYPE = 'New';
        DEEPLEARNING=true;
    end
    
    properties (Transient)
        PX2CM; % dunno
        IRImage; %check
        MixedImage; %check
        RGBImage; %check
        horzAxisAngle; %bS
        horzAxisLength; %bS
        horizontalAxis; %bS
        mask; %check
        outline; %bS
        dist2AxisMap; %bS
        earRadiusProfile; %bS
        posRel2AxisMap; %bS
        fertileZoneMask; % !HOT!
        horzAxisLengthOriented; %bS
        earDiameterProfile; %bS
        earMaxDiameter; %bS
        lowCutSegmentation; %S
        highCutSegmentation; %S
        highCutSegmentationLabels; %S
        segmentedImageProps; %pS
        resizedProps; %pS !HOT!
        horzFilesProps; %pS
        vertFilesProps; %pS
        refinedSegmentation; %pS !HOT!
        apexMissingKernels; %pS
        ringCountAvg; %pS
        RanksCount ; 
        GrainPerRanksCount ; 
        GrainsAttributes ; 
        ZoneMasks ;
        ApicalAbortion ;
        FertileZoneLength ; 
        Abortion ;
        upOrDownMap; %bS
    end
    
    properties (Dependent, Transient)
        XAxisLength; %bS
    end
    
    properties (Access = private, Transient)
        % booleans to init most computed variables
        isPX2CMset = false; 
        isIRImageSet = false;
        isMixedImageSet = false;
        isRGBImageSet = false;
        isHorzAxisLengthSet = false;
        isHorzAxisSet = false;
        isMaskSet = false;
        isOutlineSet = false;
        isDist2AxisSet = false;
        isEarRadiusProfileSet = false;
        isDiameterProfileSet = false;
        isPosRel2AxisMapSet = false;
        isupOrDownMapSet = false;
        isFertileZoneMaskSet = false;
        isHorzAxisAngleSet = false;
        isHorzAxisLengthOrientedSet = false;
        isEarMaxDiameterSet = false;
        isLowCutSegmentationSet = false;
        isHighCutSegmentationSet = false;
        isSegmentedImagePropsSet = false;
        isResizedPropsSet = false;
        isHorzFilesPropsSet = false;
        isVertFilesPropsSet = false;
        isRefinedSegmentationSet = false;
        isRingCountAvgSet = false;
        isRanksCountSet= false ; 
        isGrainPerRanksCountSet = false ;
        isGrainsAttributesSet = false ;
        isZoneMasksSet = false ;
        isAbortionMaskSet = false ;
    end
    
    methods
        
        function obj = FaceEarClass(workdir,code,numero_face,varargin)
            obj.dirpath = workdir;
            obj.numero_face = numero_face;
            obj.code = code;
            
            % To be used only for development : 
            % obj.readAllImages();

            % Always reset compute variables first : 
            obj.resetComputedVariables;
            
            if nargin > 3
                
                obj.USECOLORMASK = varargin{1} ; 
                
                % For development only : 
                obj.SEGMENTATIONTYPE = varargin{2};
                obj.USETEMPFOLDER = varargin{3};
                
            end
            
        end
        
        function resetComputedVariables(obj)
            obj.isIRImageSet = false;
            obj.isMixedImageSet = false;
            obj.isRGBImageSet = false;
            obj.isHorzAxisLengthSet = false;
            obj.isHorzAxisSet = false;
            obj.isMaskSet = false;
            obj.isOutlineSet = false;
            obj.isDist2AxisSet = false;
            obj.isEarRadiusProfileSet = false;
            obj.isPosRel2AxisMapSet = false;
            obj.isFertileZoneMaskSet = false;
            obj.isHorzAxisAngleSet = false;
            obj.isHorzAxisLengthOrientedSet = false;
            obj.isDiameterProfileSet = false;
            obj.isEarMaxDiameterSet = false;
            obj.isLowCutSegmentationSet = false;
            obj.isHighCutSegmentationSet = false;
            obj.isSegmentedImagePropsSet = false;
            obj.isResizedPropsSet = false;
            obj.isHorzFilesPropsSet = false;
            obj.isVertFilesPropsSet = false;
            obj.isRefinedSegmentationSet = false;
            obj.isRingCountAvgSet = false;
            obj.isRanksCountSet = false;
            obj.isGrainPerRanksCountSet = false ;
            obj.isGrainsAttributesSet = false ;
            obj.isZoneMasksSet = false ;
        end
        
        function [Iim,Mim,Vim,mask] = readAllImages(obj)
            
            Iim = obj.IRImage;
            Mim = obj.MixedImage;
            Vim = obj.RGBImage;
            mask = obj.mask;
            obj.mask = mask;
            obj.IRImage = Iim;
            obj.MixedImage = Mim;
            obj.RGBImage = Vim;
            
        end
        
        function im = readImage(obj,type)
            switch type
                case 'A'
                    % This one is to get Deep Learning outputs :
                    % The output of deep learning masks is not directly compute here 
                    % and needs to be read from another script output :   
                    PathToRefined = 'E:\Phymea\EarBox\Deep Learning\Outputs\EarCode_Side.png';
                    im = imread(fullfile(PathToRefined,[obj.code,'_',num2str(obj.numero_face),'.png']));
                    im = logical(im);
                case 'I'
                    im = imread(fullfile(obj.dirpath,obj.code,num2str(obj.numero_face),'IR.png'));
                    obj.IRImage = im;
                case 'M'
                    % Compute mix image : 
                    IR_img = imread(fullfile(obj.dirpath,obj.code,num2str(obj.numero_face),'IR.png'));
                    RGB_img = imread(fullfile(obj.dirpath,obj.code,num2str(obj.numero_face),'RGB.png'));
                    [row,col,rgb] = size(IR_img);
                    
                    % Scaling factors :
                    Scaling = [0.7 , 0.425 ; 0.4 , 0.475 ; 0.925 , 0.3];
                    IR_trans = zeros(row,col,rgb);
                    RGB_trans = zeros(row,col,rgb);
                    MIX_trans =zeros(row,col,rgb);
                    for color = 1:3
                        IR_trans(:,:,color) = double(IR_img(:,:,color)) .* Scaling(color,1);
                        RGB_trans(:,:,color) = double(RGB_img(:,:,color)) .* Scaling(color,2);
                        MIX_trans(:,:,color) = IR_trans(:,:,color) + RGB_trans(:,:,color);
                    end
                    % Normalize mix :
                    im = uint8(255 * mat2gray(MIX_trans,[0 255]));        
                    obj.MixedImage = im;
                case 'V'
                    im = imread(fullfile(obj.dirpath,obj.code,num2str(obj.numero_face),'RGB.png'));
                    obj.RGBImage = im;
                case 'R'
                    im = imread(fullfile(obj.dirpath,obj.code,num2str(obj.numero_face),'ROI.png'));
                    obj.mask = im;
                otherwise
                    error('Type not allowed (use ''A'', ''I'', ''M'', ''V'' or ''R'')');
            end
        end
        
        function im = enumerateRingPosition(obj)
            
            % alternative to ranks to position all grains all the time : 
            toto = obj.refinedSegmentation >0;
            ss = regionprops(toto,'Centroid','BoundingBox','PixelIdxList');
            centroids = cat(1,ss.Centroid);
            bbox = cat(1,ss.BoundingBox);
            
            % If we have centroids : 
            if ~isempty(centroids)
                [~,sidx] = sort(centroids(:,1),'descend');
                scc = centroids(sidx,1);
                bx= bbox(sidx,1);
                pos = ones(length(scc),1);
                idx = 1;
                % Define sensitivity : 
                k = 20;
                while ~isempty(idx)
                    idx = find(scc < (bx(idx)-k),1,'first');
                    pos(idx:end) =  pos(idx:end)+1;
                end

                im = uint8(toto);
                for i = 1:length(ss)
                    im(ss(sidx(i)).PixelIdxList) = pos(i);
                end
            else
                im = uint8(toto);
            end
            
            % (Usually more ranks than with gpr)
        end
        
        function output = ringDimensions(obj)

            im = obj.enumerateRingPosition;
            ss = regionprops(im>0,im,'Image','MeanIntensity','BoundingBox','EquivDiameter','Centroid','Area');
            bbox = cat(1,ss.BoundingBox);
            equiv = cat(1,ss.EquivDiameter);
            avg_val = cat(1,ss.MeanIntensity);
            centroids = cat(1,ss.Centroid);
            area = cat(1,ss.Area);
            
            % ----------------
            % filter on grain position related to ear center :
            % Fixed to 0.8 from earbox paper : 
            threshold = 0.8;
            % ----------------

            dgrain = zeros(length(ss),1);
            cosinus = zeros(length(ss),1);
            position_x = zeros(length(ss),1);
            profile = obj.earDiameterProfile ./ 2 +30;
            Horizontal_axis = obj.horizontalAxis;
            corrected_dgrain = zeros(length(ss),1);
            ratio_deformation = zeros(length(ss),1);
            value_correction = zeros(length(ss),1);

            for i = 1:length(ss)
                
                % Correction : 
                xx = ceil(centroids(i,1));
                position_x(i) = ceil(centroids(i,1));
                yy = ceil(centroids(i,2));
                position_y(i) = ceil(centroids(i,2));
                % Force it so it is not higher thn one for border grains :  
                if obj.dist2AxisMap(yy,xx) / profile(xx) > 1
                    coscentre = 1;
                else 
                    coscentre = obj.dist2AxisMap(yy,xx) / profile(xx);
                end
                costotal = min(max((obj.dist2AxisMap(yy,xx) - equiv(i)/2) / profile(xx),-1),1);
                theta = mod(acos(costotal) - acos(coscentre),pi);
                dgrain(i) = 2*profile(xx)*sin(theta);
    
                % Move xmin and xmax with boxes : 
                xpos = ceil(centroids(i,1));
                minr = ceil(centroids(i,2)) ;
                maxr = ceil(centroids(i,2)) + (bbox(i,4));
                
                % Calculate the dist to axis : 
                a = find(Horizontal_axis(:,xpos)==1);
                dmax = find(obj.outline(:,xpos)==1,1,'last');
                dmin = find(obj.outline(:,xpos)==1,1,'first');
                r = obj.earDiameterProfile(xpos)/ 2;
                
                % For max sign: 
                dref = dmin;
                signmax = -1;
                if maxr >=a
                    dref=dmax;
                    signmax=1;
                end
                cosmax = signmax * (maxr-a) / abs(dref-a);
                
                cosmax_touse = max(min(cosmax,1),-1);
                angle = (pi/2) - acos(cosmax_touse);
                projmax = angle*abs(dref-a)*signmax + a;
                
                % For min sign: 
                dref = dmin;
                signmin = -1;
                if minr >=a
                    dref=dmax;
                    signmin=1;
                end
                cosmin = signmin * (minr-a) / abs(dref-a);                
                
                cosmin_touse =  max(min(cosmin,1),-1);
                angle = (pi/2) - acos(cosmin_touse);
                projmin = angle*abs(dref-a)*signmin + a;
                

                if cosmax_touse > threshold || cosmin_touse > threshold
                %if abs(projmin-projmax)/equiv(i) > threshold
                    corrected_dgrain(i) = NaN;
                    corrected_Xgrain(i) = NaN;
                    ratio_deformation(i) =  NaN;
                    value_correction(i) = max(cosmax_touse,cosmin_touse);
                else
                    corrected_dgrain(i) = abs(projmin-projmax);
                    corrected_Xgrain(i) = bbox(i,3);
                    ratio_deformation(i) =  abs(projmin-projmax)/equiv(i);
                    value_correction(i) = max(cosmax_touse,cosmin_touse);
                end
                
                
            end
            
            ratio = dgrain./equiv;
            
            % Position along Ear : 
            BaseEpi = find(sum(obj.mask),1,'last') ; % last
            PositionAlongEar = (BaseEpi - position_x); % BaseEpi - position_x
            PositionAlongDiameter = position_y;            
            
            for i = 1:length(ss)
                pos(i) = avg_val(i);
                equiv(i) = dgrain(i);
                % Old : 
                % Ydim(i) = bbox(i,4).*ratio(i);
                % New : 
                Ydim(i) = corrected_dgrain(i);
                Xdim(i) = corrected_Xgrain(i);
                
                % THIS IS NOT THE RIGHT SURFACE ! ! ! ! ! ! 
                if isnan(corrected_dgrain(i))
                    Area(i) = NaN;
                    PositionAlongEar(i) = NaN;
                else 
                    Area(i) = area(i);
                end
                
            end
            
            %%% !!!!!!!! %%%
            %%% We have two classification methods that hav to agree 
            % 1/ avg_val
            % 2/ label2rgb(obj.horzFilesProps.IfilesColor)
            % They mostly agree, more gpr for method 2, if limited to 1 we can recover all grains
            % method 2 is most of the time underestimating for ear no fully filled
            % than grain size can be less precise from the difficult positioning of the levels from method 1
            %%% !!!!!!!! %%%

            
            % Limit to number of gpr calc with "GrainPerRanksCount" (not gpr) ! 
            % We therefore limit the ranks between both methods
            RanksLim = obj.GrainPerRanksCount;
            Lim = min((RanksLim.MaxTop + RanksLim.MaxMid + RanksLim.MaxBot),max(pos));
                       
            % Info per gpr using max position : 
            for i = 1:max(pos)
                
                output.pos(i) = i;
                output.equiv(i) = nanmean(equiv(pos==i));
                output.N_grain(i) = length(Xdim(pos==i & ~isnan(Xdim)));
                output.sd_equiv(i) = std(equiv(pos==i),'omitnan');
                output.Ydim(i) = nanmean(Ydim(pos==i));
                output.sd_Ydim(i) = std(Ydim(pos==i),'omitnan');
                output.Xdim(i) = nanmean(Xdim(pos==i));
                output.sd_Xdim(i) = std(Xdim(pos==i),'omitnan');
                output.profile(i) = (nanmean(profile(ceil((centroids(pos==i,1)))))-30) * 2; % nanmean 
                output.position_x(i) = nanmean(PositionAlongEar(pos==i,1)); % nanmean
                output.sd_position_x(i) = std(PositionAlongEar(pos==i),'omitnan');
                output.area(i) = nanmean(Area(pos==i));
                output.sd_area(i) = std(Area(pos==i),'omitnan');
                
            end
                        
            % Info per grain :
            % Position along Ear without nans : 
            BaseEpi = find(sum(obj.mask),1,'last') ;
            PositionAlongEar_NoNaN = (BaseEpi- position_x); 
            
            output.Grain.PositionAlongEar = PositionAlongEar_NoNaN;
            output.Grain.PositionAlongDiameter = PositionAlongDiameter;
            output.Grain.Equiv = equiv;
            output.Grain.YDim = Ydim;
            output.Grain.Xdim = Xdim;
            output.Grain.Pos = pos;
            output.Grain.Projected_Area = Area;
            output.Grain.Threshold = value_correction;
            output.RanksAlongEar = obj.RanksCount.Ranks;
            output.Grain.Ranks = output.RanksAlongEar(output.Grain.PositionAlongEar);
           
            % If we need the outputs for paper : 
            if obj.paper_grain_dimensions == 1
                
                h = figure(4343);
                hold on 
                
%             % Position along Ear without nans : 
                Tru = find(sum(obj.mask),1,'first') ;
                Truc2 = (position_x - Tru);     
                
                PhymeaColor = [0 0.66 0] ;

                % Get data : 
                Ids = ~isnan(Truc2);
                
                X = Truc2(Ids) + BaseEpi;
                Y = PositionAlongDiameter(Ids);
                XdimToShow = Xdim(Ids); 
                YdimToShow = Ydim(Ids);
                ToShow = (avg_val(Ids));
                
                sizes = size(obj.RGBImage);
                sizeY = sizes(1);
                sizeX = sizes(2);
                PositionAxes = get(gca, 'Position');

                % Plot it :
                hold on
                
                imshow(obj.RGBImage,'Border','tight')
                imshowpair(obj.RGBImage,obj.refinedSegmentation)
                
                
                hold on 
                
                plot( X, Y, 'r*',  'MarkerSize', 4,'color', 'red');
                
                for t = 1:length(avg_val)
                    MyText = sprintf('%2.0f',ToShow(t));
                    text(X(t),Y(t),MyText,'color', 'red')
                end
                

                PositionAxes = get(gca, 'Position');

                % XDIM to plot : 
                HorizontalLines = [ (X-(XdimToShow'/2))  (X+(XdimToShow'/2))];
                PositionHor = [Y' Y'];
                % Ydim to plot : 
                VerticalLines = [ (Y-(YdimToShow/2))'  (Y+(YdimToShow/2))'];
                PositionVert = [X X];

                % Show lines : 
                for k = 1:length(HorizontalLines)
                    line(HorizontalLines(k,:),PositionHor(k,:),'color', 'b','LineWidth',1.5)
                    line(PositionVert(k,:),VerticalLines(k,:),'color', 'r','LineWidth',1.5)
                end            
                hold off

                % Figure : 
                figure(444), hold on
                imshow(label2rgb(obj.horzFilesProps.IfilesColor, 'jet', 'k', 'shuffle'),'Border','tight');    
                % Positioning the mean values : 
                hold off
                

                writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
                if ~isdir(fullfile(writepath,'tmp'))
                    mkdir(writepath,'tmp');
                end
                writepath = fullfile(writepath,'tmp');
                img = getframe(Showing_grains);

                % Write images : 
                imwrite(img.cdata,fullfile(writepath,'GrainData.png'))

                close(Showing_grains)
            
            end
            
            % Info per position (every 0.5cm of ear): 
            EarLength = floor(obj.horzAxisLength*obj.PX2CM) ; 
            EarCm = PositionAlongEar*obj.PX2CM ;
            k = 1;
            for i = 0:0.5:EarLength-0.5
                output.GrainPosition.pos(k) = i ; 
                output.GrainPosition.relpos(k) = round((i+0.25) / EarLength,2) ; 
                ID = find(EarCm < i+0.5 & EarCm > i) ; 
                if ~isempty(ID)
                    output.GrainPosition.equiv(k) = mean(equiv(ID));
                    output.GrainPosition.Ydim(k) = mean(Ydim(ID));
                    output.GrainPosition.Xdim(k) = mean(Xdim(ID));
                    output.GrainPosition.Level(k) = mean(pos(ID));
                    k = k+1;                
                end
            end
                        
        end
                
        function [A,F,B,Ratio,ratio_grain,Al,Fl,Bl] = fertileZoneMaskDimensions(obj,varargin)
            
            if nargin<2
                seuil1 = 0.7;
            elseif nargin<3
                seuil1 = varargin{1};
                seuil2 = 0.6;
            else
                seuil1 = varargin{1};
                seuil2 = varargin{2};
            end
            
            
            % Grain ratio from IfilesColor to have a better abortion :
            try 
                Test = obj.verticalFileDetection.IfilesColor;
                Test(obj.verticalFileDetection.IfilesColor>1) = 1 ;
            catch
                Test = obj.refinedSegmentation;
            end
            
            
            % All the time : 
            ToTreat = obj.refinedSegmentation;
            
            ratio_grain = sum(ToTreat)./sum(obj.mask);
            ratio_grain2 = sum(Test)./sum(obj.mask);
            
            ratio_grain(isnan(ratio_grain)) = 0;
            ratio_grain(ratio_grain>1) = 1;

            ratio_grain2(isnan(ratio_grain2)) = 0;
            ratio_grain2(ratio_grain2>1) = 1;

            %% Smooth objects at 5%: 
            Smoothed_toto =smooth(ratio_grain,round(obj.horzAxisLength*2/100,0));
            Smoothed_tata =smooth(ratio_grain2,round(obj.horzAxisLength*2/100,0));

            %% Mean of both objects 10%: 
            bobo = (Smoothed_toto+Smoothed_tata)/2;
            bibi =smooth(bobo,round(obj.horzAxisLength*10/100,0));
            
            % Inflexion points : 
            idxInfexion = find(sign(bibi(1:end-1)) ~= - sign(bibi(2:end))) + 2 + 1;  
            
            x0 = find(sum(obj.mask)>0,1,'first');
            x3 = find(sum(obj.mask)>0,1,'last');
            
            
            %% With refined seg : 
            bibu = uint8(ToTreat);
            x2 = find(sum(bibu)  > seuil2*sum(obj.mask),1,'last');
            
            
            %% Both infos : 
            x1 = find(bibi  > seuil1,1,'first');

            if any([isempty(x0) isempty(x1) isempty(x2) isempty(x3)])
                warning('probably no fertile kernels');
                A = NaN;
                F = NaN;
                B = NaN;
                Ratio = NaN;
                return
            end
            % Area ratio > 50% ?
            A = (x1-x0); % apex loss
            F = (x2-x1); % fertile zone
            B = (x3-x2); % basal zone
            
            x4 = find(sum(obj.fertileZoneMask)>0,1,'first');
            x5 = find(sum(obj.fertileZoneMask)>0,1,'last');
            
            % Limit (area ratio > 0%)
            Al = (x4-x0); % apex loss
            Fl = (x5-x4); % fertile zone
            Bl = (x3-x5); % basal zone
            
            Ratio = length(ratio_grain(ratio_grain(x1:x2)>seuil1))/(F);
           
        end
        
        function someLossWork(obj)

            % Losses using corrected values :
            pp = obj.resizedProps;
            idx = abs(pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4) - mean(pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4)))<std(pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4));
            seuil = max([2*std(pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4)),3e-10]) + ((pp.centroids_cor(:,1)\((pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4))-mean(pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4))))*3.*pp.centroids_cor(:,1))';
            idx = (pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4))-mean(pp.eccents_cor./(profile(ceil(pp.centroids_cor(:,1)))'.^4))>seuil';
            pp.kept_idx_cor(idx) = false;
            idx = circularity(obj.refinedSegmentation)<0.6;
            pp.kept_idx_cor(idx) = false;
            
            obj.resizedProps.kept_idx_cor = pp.kept_idx_cor;

        end
        
        function HorzFileImage = saveHorzFileImage(obj,visibility)
            
            writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
            if ~isdir(fullfile(writepath,'tmp'))
                mkdir(writepath,'tmp');
            end
            writepath = fullfile(writepath,'tmp');
            
            IfilesColor = zeros(size(obj.mask));
            for pt_idx = 1:length(obj.segmentedImageProps.majors)
                if obj.resizedProps.kept_idx_cor(pt_idx)
                    IfilesColor(cat(1,obj.segmentedImageProps.pixelIdxLists{pt_idx})) = obj.horzFilesProps.fileLookUp(pt_idx);
                end
            end
            
            if strcmp(visibility,'off')==1
            HorzFileImage = figure('name','HorzFileImage','Visible','off');
            else
            HorzFileImage = figure('name','HorzFileImage','Visible','on');
            end
            
            if obj.paper
                %%% OUTPUT LINE IMAGE
                % hold off
                % imagesc(IfilesColor)
                % imshow((obj.highCutSegmentationLabels>1)*0.45+obj.mask*0.4,'Border','tight');
                % hold on
                imshow(label2rgb(IfilesColor, 'jet', 'k', 'shuffle'),'Border','tight');
                %him.AlphaData = 0.6;
                hold off
                imwrite(label2rgb(IfilesColor, 'jet', 'k', 'shuffle'),fullfile(obj.path_for_paper,'Grain_Par_Rangs','Grain_Par_Rangs_couleurs.png'))
                close(HorzFileImage)
                % --------

        end
        
        function VertFileImage=saveVertFileImage(obj,visibility)
            
            writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
            if ~isdir(fullfile(writepath,'tmp'))
                mkdir(writepath,'tmp');
            end
            writepath = fullfile(writepath,'tmp');
            
            IfilesColor = zeros(size(obj.mask));
            for pt_idx = 1:length(obj.segmentedImageProps.majors)
                if obj.resizedProps.kept_idx_cor(pt_idx)
                    IfilesColor(cat(1,obj.segmentedImageProps.pixelIdxLists{pt_idx})) = obj.vertFilesProps.fileLookUp(pt_idx);
                end
            end
 
            if strcmp(visibility,'off')==1
                VertFileImage = figure('name','HorzFileImage','Visible','off');
            else
                VertFileImage = figure('name','HorzFileImage','Visible','on');
            end
            
            if obj.paper
                %%% OUTPUT LINE IMAGE
                % hold off
                % imagesc(IfilesColor)
                % imshow((obj.highCutSegmentationLabels>1)*0.45+obj.mask*0.4,'Border','tight');
                imshow(label2rgb(IfilesColor, 'jet', 'k', 'shuffle'),'Border','tight');
                % him.AlphaData = 0.6;
                hold off
                imwrite(label2rgb(IfilesColor, 'jet', 'k', 'shuffle'),fullfile(obj.path_for_paper,'Rangs','Rangs_couleurs.png'))
                close(VertFileImage)
                % --------

        end
        
        function ResultsImage = showAndSaveResultsImage(obj,EarLengthHalfImage,FigLength,Visibility,Save,EarMask,ColorMask) % 35cm 
        
            % Image name : 

            ImageName = strcat('EarMeasurements_EarMask',EarMask,'_ColorMask',num2str(ColorMask));
            
            %%% Image is less than a 6th of A4 (if wants to be printed correctly)
            %%% But proportions of the ear object (length/diam) in the
            %%% image have to be kept for visualisation
            %%% EarMaxLength determines the Ear length in cm that does 3/4 of the
            %%% image length. All ears are scaled according to this value 
            
            % Set figure sizes : 
            FigureWidth = FigLength * 0.95 * (1/6);
            FigureLength = FigLength * 0.7070 ;
            
            % Get image size / object proportion: 
            ImSize = size(obj.mask);
            EarSize = obj.horzAxisLength*obj.PX2CM ;
            EarDiam = obj.earMaxDiameter*obj.PX2CM ;
            ObjRatio = ImSize(2)/ ImSize(1);
            
            % Set Image size and scaling factor of ear in image : 
            Scaling = EarSize/EarLengthHalfImage ;
            gcaLength = FigureLength * 0.75 * (Scaling)  ;
            gcaWidth = gcaLength / ObjRatio  ;
            RGB = obj.RGBImage ;
            Lfertile = num2str(round(obj.ZoneMasks.FertileZone*obj.PX2CM,1));
            Lapex = num2str(round(obj.ZoneMasks.ApexAbortion*obj.PX2CM,1));
            Lbase = num2str(round(obj.ZoneMasks.BasalAbortion*obj.PX2CM,1)) ;
            Ratio = num2str(round(obj.ZoneMasks.FertileZoneGrainRatio,2)*100);
            
            %-------------------------------------------------------------------------%

            ResultsImage = figure('Name','ResultsImage'); ...

                set(ResultsImage,'Visible',Visibility,'InvertHardcopy','off');

                hold on

                set(gcf,'units','pixels','position',[50,50,FigureLength,FigureWidth],'Color',[0 0 0])

                set(gca,'units','pixels',...
                    'position',[(FigureLength/2)-(gcaLength/2),(FigureWidth/2)-(gcaWidth/2),gcaLength,gcaWidth],...
                    'Visible','on',...
                    'XLim',[0 ImSize(2)*Scaling],...
                    'YLim',[0 ImSize(1)*Scaling])

                % Setup  : 
                Xmin = 0.015 ;
                Xmax = 0.76 ;
                Ymin = 0.03 ; 
                Ymax = 0.9 ;
                PhymeaColor = [0 0.66 0] ; 
                
                CurrentAxes = gca ;
                CurrentFigure = gcf ;  
                
                
                % Mask :
                imshow(imresize(RGB, Scaling),'Parent', gca)
            
                %-------------------------------------------------------------------------%
                
                % Fertile Zone + Used and unused Grains :

                if strcmp(EarMask,'on')
                    
                    SegmentedImageToShow = imerode(obj.refinedSegmentation,strel('disk',5));                   
                    RedSegmentation = ind2rgb(SegmentedImageToShow,[0,0,0;254,0,0]);
                    him = imshow(imresize(RedSegmentation, Scaling),'Parent', gca);
                    him.AlphaData = 0.3;
                    
                    if sum(obj.refinedSegmentation(:)) ~= 0;
 
                        SegmentedImageToShow = imerode(obj.verticalFileDetection.IfilesColor,strel('disk',5));
                        GreenSegmentation = ind2rgb(SegmentedImageToShow,[0,0,0;0,254,254]);
                        her = imshow(imresize(GreenSegmentation, Scaling),'Parent', gca);
                        her.AlphaData = 0.6;
                                            
                        
                    end
                    
                end
                       
                % Draw the outline of the object : 
                Stats = regionprops(imresize(obj.mask, Scaling),'Boundingbox');

                rectangle('Position', Stats.BoundingBox,'Parent',gca,'EdgeColor',[0,1,0]);
        
                % Ear Length and zones :
                annotation(gcf,'textbox',...
                    [(CurrentAxes.Position(1)/CurrentFigure.Position(3)) 0.88 0.1 0.1],...
                    'String','Ear dimensions :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',10.5);
                
                annotation(gcf,'textbox',...
                    [0.46 0.77 0.1 0.1],...
                    'String',strcat('L_{ear}= ',num2str(round(EarSize,1)),'cm '),...
                    'color', PhymeaColor,'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                

                %-------------------------------------------------------------------------%

                % Three zones along the ear  : 
                
                
                ApexEpi = (1-(find(sum(obj.mask),1,'last')/length(obj.mask)))*Scaling  ;
                BaseEpi = (find(sum(obj.mask),1,'first')/length(obj.mask))*Scaling ;
                Base = (obj.ZoneMasks.BasalAbortion/length(obj.mask))*Scaling*0.75 ;
                Apical =  (obj.ZoneMasks.ApexAbortion/length(obj.mask))*Scaling*0.75; 
                
                
                Xlength = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi...
                    (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi] ;
                Ylength = [ (CurrentAxes.Position(2)+CurrentAxes.Position(4))/CurrentFigure.Position(4)...
                    (CurrentAxes.Position(2)+CurrentAxes.Position(4))/CurrentFigure.Position(4)] ;
                
                % Small bars for cutting the rectangle (Abortion) : 
                YsmallBars = [(CurrentAxes.Position(2)+CurrentAxes.Position(4))/CurrentFigure.Position(4)...
                                CurrentAxes.Position(2)/CurrentFigure.Position(4)] ;
                
                annotation(gcf,'doublearrow',Xlength,[0.7 0.7],'color', PhymeaColor,'HeadStyle','hypocycloid');

                if isnan(Base) || isnan(Apical)

                    % Lines 
                    X = [0.5 0.5];
                   annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');
                    
                    % Text : 
                    annotation(gcf,'textbox',[.45 .15 .1 .1],'String','No fertile zone','color', [1 0 0 ],...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                    annotation(gcf,'textbox',[.3 .15 .1 .1],...
                        'String',strcat('L_{apex}= ',num2str(round(EarSize/2,1)),'cm'),'color', PhymeaColor,...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                    annotation(gcf,'textbox',[.6 .15 .1 .1],...
                        'String',strcat('L_{base}= ',num2str(round(EarSize/2,1)),'cm'),'color', PhymeaColor,...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');


                else
                    
                    % Lines
                    X = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical...
                        (CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical] ;
                    annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');
                    X = [(CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base...
                        (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base] ;
                    annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');

                    
                    % Text :
                    annotation(gcf,'textbox',[.45 .1 .1 .1],'String',...
                        strcat('L_{fertile}',{' '},'=',{' '},Lfertile,'cm'),...
                        'color', PhymeaColor,'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                    
                    annotation(gcf,'textbox',[.3 .1 .1 .1],...
                        'String',strcat('L_{apex}',{' '},'=',{' '},Lapex,'cm'),'color', PhymeaColor,...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none','EdgeColor','none');
                    annotation(gcf,'textbox',[.6 .1 .1 .1],...
                        'String',strcat('L_{base}',{' '},'=',{' '},Lbase,'cm'),'color', PhymeaColor,...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none','EdgeColor','none');

                end

                % Annotate diameter :
                HalfDiameter = (obj.earMaxDiameter/ImSize(1))* (gcaWidth/FigureWidth) /2 ; 
                Xdiam = [0.5+(gcaLength/(2*FigureLength)) 0.5+(gcaLength/(2*FigureLength))  ] ;
                Ydiam = [ 0.5-HalfDiameter 0.5+HalfDiameter   ] ;
                annotation(gcf,'doublearrow',Xdiam,Ydiam,'color', PhymeaColor,'HeadStyle','hypocycloid');
                annotation(gcf,'textbox',[0.5+(gcaLength/(2*FigureLength)) 0.46 .1 .1],...
                    'String',strcat('D_{max}',{' '},'=',{' '},num2str(round(EarDiam,1)),'cm'),...
                    'color', PhymeaColor,'FitBoxToText','on','fontweight','bold','EdgeColor','none');

                %-------------------------------------------------------------------------%
                % Grain size :
 
                annotation(gcf,'rectangle',[Xmin+0.005 0.05 0.2 0.3],'color', [0 0.66 0],'FaceColor', [0.5 0.5 0.5],'FaceAlpha',0.3 )
                annotation(gcf,'textbox',[Xmin 0.35 0.1 0.1],...
                    'String','Average ear grain dimensions :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',10.5);

                annotation(gcf,'rectangle',[Xmax+0.005 0.05 0.2 0.3],'color', [0 0.66 0],'FaceColor', [0.5 0.5 0.5],'FaceAlpha',0.3)
                annotation(gcf,'textbox',[Xmax 0.35 0.1 0.1],...
                    'String','Ear grain organisation :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',10.5); 

                % Orientation :
                if isnan(Base) || isnan(Apical)

                    annotation(gcf,'textbox',[0.025 0.175 0.1 0.1],...
                        'String','Probably no kernel','color', [1 0 0],...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                    annotation(gcf,'textbox',[Xmax+0.01 0.175 0.1 0.1],...
                        'String','Probably no kernel','color', [1 0 0],...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');

                else
                    
                    Ydim = mean(obj.GrainsAttributes.ringDimensions.Ydim);
                    Xdim = mean(obj.GrainsAttributes.ringDimensions.Xdim);
                    Largeur = min(round(Ydim,1),round(Xdim,1));
                    Longueur = max(round(Ydim,1),round(Xdim,1));
                    NbRanks = num2str(round(obj.RanksCount.Mid,1));
                    NbGpR = num2str(round((obj.GrainPerRanksCount.Bot+obj.GrainPerRanksCount.Mid+obj.GrainPerRanksCount.Top),1));

                    % Values :
                    annotation(gcf,'textbox',[Xmin+0.005 0.22 0.1 0.1],...
                        'String',strcat('Grain_{length}= ',num2str(round(Largeur*obj.PX2CM,2)),'cm'),'color', [0 0.66 0],...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                    annotation(gcf,'textbox',[Xmin+0.005 0.12 0.1 0.1],...
                        'String',strcat('Grain_{width}',{' '},'=',{' '},num2str(round(Longueur*obj.PX2CM,2)),'cm'),'color', [0 0.66 0],...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                    
                    annotation(gcf,'textbox',[Xmax+0.005 0.06 0.1 0.1],...
                        'String',strcat('Grain number',{' '},'=',{' '},num2str(round(obj.GrainsAttributes.NbGr,0))),...
                        'color', [0 0.66 0],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',10);
                    annotation(gcf,'textbox',[Xmax+0.005 0.16 0.1 0.1],...
                        'String',strcat('Ranks in mid zone',{' '},'=',{' '},NbRanks),'color', [0 0.66 0],...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');
                    annotation(gcf,'textbox',[Xmax+0.005 0.26 0.1 0.1],...
                        'String',strcat('Grains per rank',{' '},'=',{' '},NbGpR),'color', [0 0.66 0],...
                        'FitBoxToText','on','fontweight','bold','EdgeColor','none');

                end


                %-------------------------------------------------------------------------%
                % Date and Time / Ear / Face :

                Code = obj.code;
                Num_Face = num2str(obj.numero_face);
                t = datetime('now');

                % Ear details : 
                annotation(gcf,'textbox',[Xmin 0.9 0.1 0.1],...
                    'String',strcat('Ear code :',{' '},Code),...
                    'color', [1 1 1],'FitBoxToText','on','EdgeColor','none','color', [0.6 0.6 0.6],'Interpreter', 'none','FontSize',9);
                annotation(gcf,'textbox',[Xmin 0.83 0.1 0.1],...
                    'String',strcat('Face ',{' '},Num_Face),...
                    'color', [1 1 1],'FitBoxToText','on','EdgeColor','none','color', [0.6 0.6 0.6],'Interpreter', 'none','FontSize',9);

                % Image details : 
                annotation(gcf,'textbox',[Xmax 0.98-0.07 0.1 0.1],...
                    'String',strcat('Time of analysis :',{' '},char(t)),'color', [0.6 0.6 0.6],'FitBoxToText','on','EdgeColor','none','Interpreter', 'none','FontSize',9);
                annotation(gcf,'textbox',[Xmax 0.98-0.14 0.1 0.1],...
                    'String','EarBox Analyser v.0.0.1','color', [0.6 0.6 0.6],'FitBoxToText','on','EdgeColor','none','Interpreter', 'none','FontSize',9);

        hold off


        if strcmp(Save,'on')
            % Save figure :
            % (high res png)
            img = getframe(ResultsImage);
            imwrite(img.cdata, [strcat(fullfile(obj.dirpath,obj.code,num2str(obj.numero_face)),'\',ImageName,'.png')]);
            % (Pdf) 
            set(gcf,'PaperOrientation','landscape')        
            print(obj.code,'-dpdf','-bestfit')
        end
        
        close(ResultsImage)

        end
        
        % All getters : 
        function im = get.mask(obj)
            if ~obj.isMaskSet
                obj.mask = obj.readImage('R');
                obj.isMaskSet = true;
            end
            im = obj.mask;
        end
        
        function value = get.PX2CM(obj)
            if ~obj.isPX2CMset
                
                ApproximateMaxDiameter = max(medfilt1(double(obj.earDiameterProfile),5));
                ApproximatePX2CM = (obj.min_PX2CM+obj.max_PX2CM)/2;
                ApproximateMaxDiameterCm = round(ApproximateMaxDiameter*ApproximatePX2CM,2);
                % Scale the PX2CM to Ear maxDiameter : 
                % Diameter with ear center on the rollers plane : ~3 cm
                % Diameter with ear center 2cm above the rollers plane : ~5,80 cm
                % Diametre avec centre d'epi dans le plan des rouleaux : ~3 cm de diametre
                CmRatio = (ApproximateMaxDiameterCm-3)/(5.8-3);
                obj.PX2CM = max(obj.min_PX2CM + (obj.max_PX2CM-obj.min_PX2CM) * CmRatio,obj.min_PX2CM);
                obj.isPX2CMset = true;
            end
            value = obj.PX2CM;
        end
        
        function im = get.outline(obj)
            if ~obj.isOutlineSet
                obj.outline = bwmorph(obj.mask,'remove');
                obj.isOutlineSet = true;
            end
            im = obj.outline;
        end
        
        function im = get.horizontalAxis(obj)
            if ~obj.isHorzAxisSet
                % Principal axes position : 
                [M,N] = size(obj.outline);
                horz_axe = zeros(M,N);
                horz_axe_avg = horz_axe;
                
                for ix = 101:(N-100)
                    val=0;
                    [idxy,~] = find(obj.outline(:,(ix-100):(ix+100)));
                    val = ceil(mean(idxy));
                    if val~=0 && ~isnan(val)
                        horz_axe(val,ix) = 1;
                    end
                end
                
                for ix = 41:(N-40)
                    val=0;
                    [idxy,~] = find(horz_axe(:,(ix-40):(ix+40)));
                    val = ceil(mean(idxy));
                    if val~=0 && ~isnan(val)
                        horz_axe_avg(val,ix) = 1;
                    end
                end
                
                horz_axe = horz_axe_avg;
                [~,x0] = find(sum(obj.outline)>0,1,'first');
                [~,x1] = find(sum(horz_axe)>0,1,'first');
                y1 = find(horz_axe(:,x1)>0,1,'first');
                [~,x2] = find(sum(horz_axe)>0,1,'last');
                y2 = find(horz_axe(:,x2)>0,1,'first');
                [~,x3] = find(sum(obj.outline)>0,1,'last');
                horz_axe(y1,x0:x1) = 1;
                horz_axe(y2,x2:x3) = 1;
                % Horizontal ear axis : 
                obj.horizontalAxis = horz_axe;
                obj.isHorzAxisSet = true;
            end
            im = obj.horizontalAxis;
        end
        
        function val = get.horzAxisLength(obj)
            if ~(obj.isHorzAxisLengthSet)
                I = obj.horizontalAxis;
                obj.isHorzAxisLengthSet = true;
                obj.horzAxisLength = sum(I(:));
            end
            val = obj.horzAxisLength;
        end
        
        function val = get.XAxisLength(obj)
            val = size(obj.ROI,2);
        end
        
        function im = get.dist2AxisMap(obj)
            if ~obj.isDist2AxisSet
                
                obj.dist2AxisMap = bwdist(obj.horizontalAxis,'chessboard').*obj.mask;
                obj.isDist2AxisSet = true;
                
                % Are we producing data for the paper : 
                if obj.paper == 1
                    
                    % Test if thats the one : 
                    if obj.numero_face == obj.face_for_paper
                        for Erosion = 1:4
                            pathToSave = fullfile(obj.path_for_paper,'Longueur');
                            nameOfImage = strcat('Axe_Longueur_Erosion',num2str(Erosion),'_side',num2str(obj.numero_face),'.png');
                            pathToImage = fullfile(pathToSave,nameOfImage);

                            Axe_Longeur = figure('name','Axe_Longeur','Visible','off');

                                imtoshow = imerode(obj.dist2AxisMap,strel('disk',Erosion));    
                                imshow(imtoshow,'Border','tight');
                                imwrite(imtoshow,pathToImage);
                                
                            close(Axe_Longeur)
                        end
                        
                    gpr(obj)
                    obj.RanksCount
                    
                    end

                end
                
                
            end
            im = obj.dist2AxisMap;
        end
        
        function vect = get.earRadiusProfile(obj)
            if ~obj.isEarRadiusProfileSet
                npxpercolumn = sum(obj.outline);
                obj.earRadiusProfile = sum(obj.dist2AxisMap.*obj.outline)./npxpercolumn;
                obj.isEarRadiusProfileSet = true;
            end
            vect = obj.earRadiusProfile;
        end % Rough radius with pedoncule (edge errors)
        
        function vect = get.earDiameterProfile(obj)

            if ~obj.isDiameterProfileSet

                diam = zeros(1,size(obj.mask,2));
                for ix = 1:size(obj.mask,2)
                    diam(ix) = max(obj.posRel2AxisMap(:,ix)) + abs(min(obj.posRel2AxisMap(:,ix)));
                end
                vect = diam;
                obj.earDiameterProfile = vect;
                obj.isDiameterProfileSet = true ; 
            end
            vect = obj.earDiameterProfile;
            
        end % Clean diameter (with pedoncule)
        
        function im = get.posRel2AxisMap(obj)
            if ~obj.isPosRel2AxisMapSet
                posreltoaxe = obj.dist2AxisMap;
                for it = 1:size(posreltoaxe,2)
                    ylim = find(obj.horizontalAxis(:,it),1,'first');
                    posreltoaxe(ylim+1:end,it) = -posreltoaxe(ylim+1:end,it);
                end
                obj.posRel2AxisMap = posreltoaxe;
                obj.isPosRel2AxisMapSet = true;
            end
            im = obj.posRel2AxisMap;
        end
        
        function im = get.upOrDownMap(obj) % Axis is 1 for now
            
            if ~obj.isupOrDownMapSet
                
                upordown = -(obj.posRel2AxisMap < 0) + (obj.posRel2AxisMap >= 0);
                upordown(~obj.mask) = 0;
                obj.upOrDownMap = upordown;
                obj.isupOrDownMapSet = true;
            end
            im = obj.upOrDownMap;
            
        end
        
        function im = get.fertileZoneMask(obj)
            if ~obj.isFertileZoneMaskSet
                obj.fertileZoneMask = zeros(size(obj.mask));
                I = obj.RGBImage;
                Ilab = rgb2lab(I);
                Ib = Ilab(:,:,3);
                Ib_norm = (Ib-min(Ib(:)))./255; % Absolute value
                fmask = (imobrcbr(Ib_norm,strel('disk',10)))>0.14;%0.5
                obj.fertileZoneMask = imopen(fmask,strel('disk',15));
                obj.isFertileZoneMaskSet= true;
            end
            im = obj.fertileZoneMask;
            
        end 
        
        function val = get.horzAxisAngle(obj) % radians
            if ~obj.isHorzAxisAngleSet
                test = find(obj.horizontalAxis==1);
                [M,N] = size(obj.mask);
                [yt,~] = ind2sub([M,N],test(round(2*length(test)/5):round(2*length(test)/5)+5));
                [yt2,~] = ind2sub([M,N],test(round(3*length(test)/5):round(3*length(test)/5)+5));
                [~,xt] = ind2sub([M,N],test(round(2*length(test)/5):round(2*length(test)/5)+5));
                [~,xt2] = ind2sub([M,N],test(round(3*length(test)/5):round(3*length(test)/5)+5));
                xtm = mean(xt);
                ytm = mean(yt);
                yt2m = mean(yt2);
                xt2m = mean(xt2);
                yaxe = (ytm-yt2m);
                xaxe = (xtm-xt2m);
                obj.horzAxisAngle = atan2(yaxe,xaxe);
                obj.isHorzAxisAngleSet = true;
            end
            val = obj.horzAxisAngle;
        end
        
        function val = get.horzAxisLengthOriented(obj)
            if ~(obj.isHorzAxisLengthOrientedSet)
                obj.isHorzAxisLengthOrientedSet = true;
                obj.horzAxisLengthOriented = (find(sum(obj.mask)>0,1,'last') - find(sum(obj.mask)>0,1,'first')) / abs(cos(obj.horzAxisAngle)) * obj.PX2CM;
            end
            val = obj.horzAxisLengthOriented;
        end
        
        function val = get.earMaxDiameter(obj)
            if ~obj.isEarMaxDiameterSet
                obj.earMaxDiameter = max(medfilt1(double(obj.earDiameterProfile),5));
                obj.isEarMaxDiameterSet = true;
            end
            val = obj.earMaxDiameter;
        end
        
        function im = get.IRImage(obj)
            if ~obj.isIRImageSet
                obj.IRImage = obj.readImage('I');
                obj.isIRImageSet = true;
            end
            im = obj.IRImage;
        end
        
        function im = get.MixedImage(obj)
            if ~obj.isMixedImageSet
                obj.MixedImage = obj.readImage('M');
                obj.isMixedImageSet = true;
            end
            im = obj.MixedImage;
        end
        
        function im = get.RGBImage(obj)
            if ~obj.isRGBImageSet
                obj.RGBImage = obj.readImage('V');
                obj.isRGBImageSet = true;
            end
            im = obj.RGBImage;
        end
        
        function im = get.lowCutSegmentation(obj)
            if ~obj.isLowCutSegmentationSet
                
                %%% Write preprocessing image :
                writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
                if ~isdir(fullfile(writepath,'tmp'))
                    mkdir(writepath,'tmp');
                end
                writepath = fullfile(writepath,'tmp');
                se = strel('disk',30);
                se2 = strel('disk',10);
                
                % Low cut seg : 
                Iadapt =  wiener2(medfilt2(adapthisteq(uint8(rgb2gray(obj.MixedImage))),[5,5]),[5,5]);
                Iobrcbr = imobr(imcbr(Iadapt,se),se2);
                Iblurlow = ordfilt2(Iobrcbr,1500,ones(45)); %1800
                Idifflow = (imobrcbr(adapthisteq(Iblurlow-0.75*Iadapt),strel('disk',10)));
                
                L = watershed(Idifflow);
                bgm = imdilate( obj.outline | ((((L&obj.mask)|~obj.mask)==0|obj.outline)), ones(3,3));
                bgm = (imclose(bgm,strel('disk',10)));
                obj.lowCutSegmentation = bgm;
                obj.isLowCutSegmentationSet = true;
                
            end
            im = obj.lowCutSegmentation;
        end
        
        function im = get.highCutSegmentation(obj)
            if ~obj.isHighCutSegmentationSet
                
                %%% Write preprocessing image :
                writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
                if ~isdir(fullfile(writepath,'tmp'))
                    mkdir(writepath,'tmp');
                end
                writepath = fullfile(writepath,'tmp');
                
                % TODO replace all the shit in here
                se = strel('disk',25);
                se2 = strel('disk',10);
                
                Iadapt =  wiener2(medfilt2(adapthisteq(uint8(rgb2gray(obj.MixedImage))),[5,5]),[5,5]);
                Iobrcbr = imobr(imcbr(Iadapt,se),se2);
                Iblurlow = ordfilt2(Iobrcbr,1500,ones(45)); %1800
                Idifflow = (imobrcbr(adapthisteq(Iblurlow-0.75*Iadapt),strel('disk',10)));
                
                se = strel('disk',10);
                se2 = strel('disk',5);
                IRfilt = wiener2(medfilt2(uint8(uint8(rgb2gray(obj.IRImage))),[5 5]),[5,5]);
                Iobrcbr = imobr(imcbr(IRfilt,se),se2);
                Iblur = ordfilt2(Iobrcbr,1800,ones(55)); %1800
                Idiff = (imobrcbr((Iblur-0.95*IRfilt),strel('disk',3)));
                rgm = imregionalmin(Idiff);
                rgm = bwareaopen(rgm, 30);
                
                % dynamic otsu segmentation
                out = zeros(30,5);
                Io = otsu(imcomplement(Idiff),80);
                allc = cell(30,1);
                
                for i =50:79
                    yolo = imopen(Io>i,strel('disk',3));
                    [Lt,num] = bwlabeln(yolo);
                    ss = regionprops(Lt,'Centroid','Area');
                    areas = cat(1,ss.Area);
                    otsucentroids = cat(1,ss.Centroid);
                    yoloss = regionprops(Lt,'Area');
                    yoloa = cat(1,yoloss.Area);
                    out(i-49,1) = num;
                    out(i-49,2) = std(yoloa);
                    out(i-49,3) = mean(yoloa(yoloa<100000));
                    [Lt,num] = bwlabeln(imcomplement(yolo));
                    out(i-49,4) = num;
                    allc{i-49} = otsucentroids(areas<10000,:);
                end
                allcc = cat(1,allc{:});
                idx = sub2ind(size(obj.mask),ceil(allcc(:,2)),ceil(allcc(:,1)));
                uidx = unique(idx);
                nbidx = zeros(size(uidx));
                for i = 1:length(uidx)
                    idx2 = find(idx == uidx(i));
                    nbidx(i) = length(idx2);
                end
                
                Icc = zeros(size(obj.mask));
                Icc(uidx) = Icc(uidx)+nbidx;
                
                % Sensitive part : fspecial arg, TreshFilt arg  and n :
                h = fspecial('gaussian',[120,120],8); % 100 / 5
                Iccfilt = imfilter(Icc,h);
                
                n = 2; % 2
                avg = mean2(Iccfilt);
                sigma = std2(Iccfilt);
                BorneInf =avg-n*sigma;
                BorneSup = avg+n*sigma;
                if BorneInf < 0 ;  BorneInf = 0 ; end
                if BorneSup > 1 ; BorneSup = 1 ; end
                IccfiltNorm = imadjust(Iccfilt,[BorneInf BorneSup],[]);
                 
                % Tresholding :
                TreshFilt = im2bw(IccfiltNorm,0.9); % 0.9
%                 imshow(TreshFilt)
                
                %% Take out low intensity points (play with LowFilter) :                 
                rgm = bwareaopen(imopen(TreshFilt,strel('disk',2)),20);
                rgm = rgm & ~imdilate(bwmorph(imdilate(obj.lowCutSegmentation,strel('disk',2)),'remove'),strel('disk',2));
               
                Imined = imimposemin(Idifflow, rgm | obj.lowCutSegmentation);
                Iwat = watershed(Imined);
                
                % Carefull, can impact with a loss of grains : 
                L = watershed(Idifflow);               
                L(~obj.mask) = 0;
                L = double(L) .* ~bwareaopen(L,50000);
                Iwat = double(Iwat) .* ~bwareaopen(Iwat,40000);
                ss = regionprops(L,'Area','PixelIdxList');
                areas = cat(1,ss.Area);
                while any(abs(areas-mean(areas)) > (5*std(areas)))
                    for i = 1:length(areas)
                        if abs(areas(i)-mean(areas)) > (5*std(areas))
                            L(ss(i).PixelIdxList) = 0;
                        end
                    end
                    ss = regionprops(L,'Area','PixelIdxList');
                    areas = cat(1,ss.Area);
                end
                
                ss = regionprops(Iwat,'Area','PixelIdxList');
                areas = cat(1,ss.Area);
                while any(abs(areas-mean(areas)) > (5*std(areas)))
                    for i = 1:length(areas)
                        if abs(areas(i)-mean(areas)) > (5*std(areas))
                            Iwat(ss(i).PixelIdxList) = 0;
                        end
                    end
                    ss = regionprops(Iwat,'Area','PixelIdxList');
                    areas = cat(1,ss.Area);
                end
                L(L<0) = 0;
                Iwat(Iwat<0) = 0;
                L = bwlabel(L);
                Iwat = bwlabel(Iwat);                
                Iwat = bwareaopen(Iwat,30);
                
                obj.highCutSegmentationLabels = L;     
                obj.highCutSegmentation = Iwat;                
                obj.isHighCutSegmentationSet = true;
                
            end
            im = obj.highCutSegmentation;
        end
        
        function im = get.highCutSegmentationLabels(obj)
            if ~obj.isHighCutSegmentationSet
                obj.highCutSegmentation;
            end
            im = obj.highCutSegmentationLabels;
        end
        
        function outstruct = get.segmentedImageProps(obj)
            if ~obj.isSegmentedImagePropsSet
                
                ss = regionprops(obj.refinedSegmentation,'BoundingBox','Centroid','Area','EquivDiameter','MajorAxisLength','MinorAxisLength','PixelIdxList','Eccentricity','Orientation');
                pp.kept_idx = true(1,length(ss))';
                pp.areas = cat(1,ss.Area);
                pp.equivDiams = cat(1,ss.EquivDiameter);
                pp.centroids = cat(1,ss.Centroid);
                pp.majors = cat(1,ss.MajorAxisLength);
                pp.minors = cat(1,ss.MinorAxisLength);
                pp.eccents = cat(1,ss.Eccentricity);
                pp.orients = degtorad(cat(1,ss.Orientation));
                pp.boxs = cat(1,ss.BoundingBox);
                if ~isempty(pp.boxs)
                    pp.boxWidths = pp.boxs(:,3);
                    pp.boxHeights = pp.boxs(:,4);
                    pp.profile = obj.earDiameterProfile ./ 2;
                end
                pixelIdxLists = cell(length(ss),1);
                for i = 1:length(ss)
                    pixelIdxLists{i} = ss(i).PixelIdxList;
                end
                pp.pixelIdxLists = pixelIdxLists;
                
                obj.segmentedImageProps = pp;
                obj.isSegmentedImagePropsSet = true;
        
                
            end
            outstruct = obj.segmentedImageProps;
        end
        
        function outstruct = get.resizedProps(obj)
            if ~obj.isResizedPropsSet
                
                obj.resizedProps = obj.resizeProps;
                obj.isResizedPropsSet = true;
                
            end
            outstruct = obj.resizedProps;
        end
        
        function outstruct = get.horzFilesProps(obj)
            if ~obj.isHorzFilesPropsSet
                obj.horzFilesProps = obj.horizontalFileDetection;
                obj.isHorzFilesPropsSet = true;
            end
            outstruct = obj.horzFilesProps;
        end
        
        function outstruct = get.vertFilesProps(obj)
            if ~obj.isVertFilesPropsSet
                obj.vertFilesProps = obj.verticalFileDetection;
                obj.isVertFilesPropsSet = true;
            end
            outstruct = obj.vertFilesProps;
        end
        
        function outstruct = get.RanksCount(obj)
            
            if ~obj.isRanksCountSet
                
            shrinkifyx = zeros(size(obj.refinedSegmentation));
            for i = 1:size(obj.refinedSegmentation,2)
                vectx = obj.refinedSegmentation(:,i);
                shrinkifyx(:,i) = bwmorph(vectx,'shrink',inf);
            end
            shrinkifyx_mt10 = bwareaopen(shrinkifyx,10);
            
            if obj.paper == 1
                
                if obj.numero_face == obj.face_for_paper
                    
                    pathToSave = fullfile(obj.path_for_paper,'Rangs');
                    nameOfImage = strcat('Rangs.png');
                    pathToImage = fullfile(pathToSave,nameOfImage);
                    
                    IM_gpr = figure('name','IM_gpr','Visible','on');
                    
                    imtoshow =imdilate(shrinkifyx_mt10,ones(3,3));
                    
                    imshow(imtoshow,'Border','tight');
                    imwrite(imtoshow,pathToImage);
                    close(IM_gpr)

                    imwrite(shrinkifyx_mt10,fullfile(pathToSave,'shrinkifyx_mt10.png'));
                    imwrite(shrinkifyx,fullfile(pathToSave,'shrinkifyx.png'));

                    saveVertFileImage(obj,'on')
                    
                end
                
            end
            
            xrange = find(sum(obj.mask),1,'last') - find(sum(obj.mask),1,'first');
            x1 = ceil(xrange/3 + find(sum(obj.mask),1,'first'));
            x2 = ceil(xrange/3 + x1);
            
            n=0; 
            leaky_avg = 0;
            S_dvect=0; N_dvect=0;
            adjusted_S_dvect=0; adjusted_N_dvect=0;
            N_grains=nan(1,size(obj.mask,2));
            rapport = N_grains;
            Grains =  nan(1,size(obj.mask,2)) ;
            Dist = nan(1,size(obj.mask,2)) ;
            Leaky_Ranks = nan(1,size(obj.mask,2)) ;
            Perimeter = nan(1,size(obj.mask,2)) ;
            
            for i = 1:size(obj.refinedSegmentation,2)
                vectx = shrinkifyx_mt10(:,i);
                
                % Add a grain at edges when grains are detected : 
                if sum(vectx) > 1
                    vectx(1) = 1;
                    vectx(end) = 1; 
                end
                
                R = obj.earDiameterProfile(i)/2;
                adjusted_vectx = R .* ((pi/2) - acos(obj.posRel2AxisMap(vectx,i)./R));

                dvect = diff(find(vectx));
                
                adjusted_dvect = diff(sort(adjusted_vectx));

                % Useful to calculate intermediate values for paper : 
                Grains(i) = numel(adjusted_dvect);
                Dist(i) = mean(dvect);
                Perimeter(i) = 2 * R * pi;
                
                S_dvect = S_dvect + sum(dvect);
                N_dvect = N_dvect + numel(dvect);
                adjusted_S_dvect = adjusted_S_dvect + sum(adjusted_dvect);
                adjusted_N_dvect = adjusted_N_dvect + numel(adjusted_dvect);

                rapport(i) = sum(dvect)/(2*R);
                
                if ~isempty(dvect)
                    N_grains(i) = 2 * R * pi / (sum(adjusted_dvect)/numel(adjusted_dvect));
                end
                
                for j = 1:numel(dvect)
                    leaky_avg = (n*leaky_avg + dvect(j))/(n+1);
                    Leaky_Ranks(i) = leaky_avg;
                    n = n+1;
                end
                
                % Calculate Ranks everywhere : 
                Ranks(i) = obj.earDiameterProfile(i) * pi / mean(dvect);
                
                if i == x1; 
                    adjusted_S_top=adjusted_S_dvect; adjusted_N_top=adjusted_N_dvect; 
                    S_top=S_dvect; N_top=N_dvect;
                    avg_top = leaky_avg; leaky_avg=0; n=0; 
                    Leaky_Ranks(i) = leaky_avg;
                end;
                if i == x2; 
                    adjusted_S_mid=adjusted_S_dvect-adjusted_S_top; adjusted_N_mid=adjusted_N_dvect-adjusted_N_top; 
                    S_mid=S_dvect-S_top; N_mid=N_dvect-N_top;
                    avg_mid = leaky_avg; leaky_avg=0; n=0; 
                    Leaky_Ranks(i) = leaky_avg;
                end;
            end
            
            % Output data : 
            rc.Grains = Grains;
            rc.Dist = Dist; 
            rc.Perimeter = Perimeter;
            rc.Ranks = Ranks;
            
            if obj.paper == 1
                
                if obj.numero_face == obj.face_for_paper
                    

                    Mask = fliplr(sum(obj.mask));
                    
                    % Discretisation of ear cm : 
                    EarLength =  obj.horzAxisLength*obj.PX2CM;
                    bottom_ear = find(Mask,1,'first');
                    end_ear = find(Mask,1,'last');

                    % Begin at ear base : 
                    GrainsTemp = fliplr(Grains);
                    DistsTemp = fliplr(Dist);
                    RanksTemp = fliplr(Ranks);
                    PerimeterTemp = fliplr(Perimeter);
                    
                    % Get the right indexes at top and base ear : 
                    GrainsToWrite = GrainsTemp(bottom_ear:end_ear);
                    DistsToWrite = DistsTemp(bottom_ear:end_ear);
                    RanksToWrite = RanksTemp(bottom_ear:end_ear);
                    PerimeterToWrite = PerimeterTemp(bottom_ear:end_ear);
                    Position_pixel = 1:1:length(PerimeterToWrite);
                    Position_cm = 0:(EarLength/(length(PerimeterToWrite)-1)):EarLength;
                
                    %% Now write the csv : 
                    pathToSave = fullfile(obj.path_for_paper,'Rangs');
                    nameOfcsv = strcat('Discretisation_Rangs.csv');
                    pathToCsv = fullfile(pathToSave,nameOfcsv);
                    
                    fileID = fopen(pathToCsv,'wt');
                    
                    fprintf(fileID,'%s','Code');
                    fprintf(fileID,';%s','Face',...
                                   'Ranks_side','Dist_Side','Perimeter_ear','Ranks_ear',...
                                   'Position_ear_cm','Position_ear_pixel');
                    fprintf(fileID,'\n');
                    
                    for i  = 1 : length(Position_cm)
                        
                        fprintf(fileID,'%s%s',obj.code,';') ;
                        fprintf(fileID,'%s%s',num2str(obj.numero_face),';');
                        fprintf(fileID,'%2.0f',GrainsToWrite(i));
                        if isnan(DistsToWrite(i))
                            fprintf(fileID,';%s','NA');
                        else
                            fprintf(fileID,';%2.4f',DistsToWrite(i));
                        end
                        fprintf(fileID,';%2.4f',PerimeterToWrite(i));
                        if isnan(RanksToWrite(i))
                            fprintf(fileID,';%s','NA');
                        else
                            fprintf(fileID,';%2.4f',RanksToWrite(i));
                        end                        
                        fprintf(fileID,';%2.4f',Position_cm(i));
                        fprintf(fileID,';%2.0f',Position_pixel(i));
                        fprintf(fileID,'\n');
                        
                    end
                    
                    fclose(fileID);
                
                    
                end
                
            end
            
                    
            avg_bot = leaky_avg;         
            S_bot=S_dvect-S_mid-S_top;
            N_bot=N_dvect-N_mid-N_top;
            adjusted_S_bot=adjusted_S_dvect-adjusted_S_mid-adjusted_S_top;
            adjusted_N_bot=adjusted_N_dvect-adjusted_N_mid-adjusted_N_top;
            
            % method1
            h = fspecial('gaussian',[1,400],50);
            imfiltx = imfilter(double(shrinkifyx_mt10),h);
            sumx = sum(imfiltx);
            
            % The first derivative gives an information on grain organisation : 
            % sum(diff(sumx(1:x1)))
            rc.Top = max(sumx(1:x1)*3); %top
            rc.Mid = max(sumx(x1:x2)*3); %mid
            rc.Bot = max(sumx(x2:end)*3); %bot
            
            % method2 ###### Test mean and median ############
            rc.Top_ = max(obj.earDiameterProfile(1:x1)) * pi / avg_top; %top
            rc.Mid_ = max(obj.earDiameterProfile(x1:x2)) * pi / avg_mid; %mid
            rc.Bot_ = max(obj.earDiameterProfile(x2:end)) * pi / avg_bot; %bot 
            if isinf(rc.Top_); rc.Top_ = 0; end
            if isinf(rc.Mid_); rc.Mid_ = 0; end
            if isinf(rc.Bot_); rc.Bot_ = 0; end
            
            % methods 3,4,5,6
            rc.top_method2 = 0; rc.top_method3 = 0; rc.top_method4 = 0; rc.top_method5 = 0; rc.top_method6 = 0;
            rc.mid_method2 = 0; rc.mid_method3 = 0; rc.mid_method4 = 0; rc.mid_method5 = 0; rc.mid_method6 = 0;
            rc.bot_method2 = 0; rc.bot_method3 = 0; rc.bot_method4 = 0; rc.bot_method5 = 0; rc.bot_method6 = 0;
            
            rc.top_method2 = max(obj.earDiameterProfile(1:x1)) * pi / avg_top; %top
            rc.mid_method2 = max(obj.earDiameterProfile(x1:x2)) * pi / avg_mid; %mid
            rc.bot_method2 = max(obj.earDiameterProfile(x2:end)) * pi / avg_bot; %bot             

            rc.top_method3 = median(obj.earDiameterProfile(1:x1)) * pi / avg_top; %top
            rc.mid_method3 = median(obj.earDiameterProfile(x1:x2)) * pi / avg_mid; %mid
            rc.bot_method3 = median(obj.earDiameterProfile(x2:end)) * pi / avg_bot; %bot    
            
            using_ratio_vertical = ((rapport>0.2).*N_grains);
            % TOP
            if ( sum(~isnan(N_grains(1:x1))) / sum(isnan(N_grains(1:x1))) ) > 0.1
                rc.top_method4 = median(obj.earDiameterProfile(1:x1)) * pi / (S_top/N_top);
                rc.top_method5 = max(obj.earDiameterProfile(1:x1)) * pi / (S_top/N_top);
                rc.top_method6 = mean(obj.earDiameterProfile(1:x1)) * pi / (S_top/N_top);
            end
            % MID
            if ( sum(~isnan(N_grains(x1:x2))) / sum(isnan(N_grains(x1:x2))) ) > 0.1
                rc.mid_method4 = median(obj.earDiameterProfile(x1:x2)) * pi / (S_mid/N_mid);
                rc.mid_method5 = max(obj.earDiameterProfile(x1:x2)) * pi / (S_mid/N_mid);
                rc.mid_method6 = mean(obj.earDiameterProfile(x1:x2)) * pi / (S_mid/N_mid);
            end
            % BOT
            if ( sum(~isnan(N_grains(x2:end))) / sum(isnan(N_grains(x2:end))) ) > 0.1
                rc.bot_method4 = median(obj.earDiameterProfile(x2:end)) * pi / (S_bot/N_bot);
                rc.bot_method5 = max(obj.earDiameterProfile(x2:end)) * pi / (S_bot/N_bot);
                rc.bot_method6 = mean(obj.earDiameterProfile(x2:end)) * pi / (S_bot/N_bot);
            end
            
            % Zero divison case : 
            if isinf(rc.top_method2); rc.top_method2 = 0; end;
            if isinf(rc.mid_method2); rc.mid_method2 = 0; end;
            if isinf(rc.bot_method2); rc.bot_method2 = 0; end;
            
            if isinf(rc.top_method3); rc.top_method3 = 0; end;
            if isinf(rc.mid_method3); rc.mid_method3 = 0; end;
            if isinf(rc.bot_method3); rc.bot_method3 = 0; end;
            
            if isinf(rc.top_method4); rc.top_method4 = 0; end;
            if isinf(rc.mid_method4); rc.mid_method4 = 0; end;
            if isinf(rc.bot_method4); rc.bot_method4 = 0; end;
            
            if isinf(rc.top_method5); rc.top_method4 = 0; end;
            if isinf(rc.mid_method5); rc.mid_method4 = 0; end;
            if isinf(rc.bot_method5); rc.bot_method4 = 0; end;
            
            if isinf(rc.top_method6); rc.top_method4 = 0; end;
            if isinf(rc.mid_method6); rc.mid_method4 = 0; end;
            if isinf(rc.bot_method6); rc.bot_method4 = 0; end;
            
            obj.RanksCount = rc ; 
            obj.isRanksCountSet = true; 
            end
            
            outstruct = obj.RanksCount ;
            
        end

        function value = median_nan(obj,X,varargin)
            if isempty(X); value = NaN; return; end;   
            if nargin<3
                if size(X,1) == 1 && size(X,2)>0;
                    dim=2;
                else
                    dim=1;
                end
            else
                dim = varargin{1};
            end
            sz = size(X);
            for i = 1:sz(~(dim-1)+1)
                inds = repmat({i},1,ndims(X));
                inds{dim} = 1:sz(dim);
                X_ = X(inds{:});
                X_ = X_(~isnan(X_));
                if isempty(X_)
                    value(i)=0;
                else
                    value(i) = median(X_);
                end
            end
            if dim==2
                value=value';
            end
        end

        function val = gpr(obj) 
            
            shrinkifyy = zeros(size(obj.refinedSegmentation));
            for i = 1:size(obj.refinedSegmentation,1)
                vecty = obj.refinedSegmentation(i,:);
                shrinkifyy(i,:) = bwmorph(vecty,'shrink',inf);
            end
            shrinkifyy_mt10 = bwareaopen(shrinkifyy,10);
            
            h = fspecial('gaussian',[100,100],50);
            imfilty = imfilter(double(shrinkifyy_mt10),h);
            
            val = max(sum(imfilty,2));        
            
            if obj.paper == 1
                
                if obj.numero_face == obj.face_for_paper
                    
                    % Write the images : 
                    pathToSave = fullfile(obj.path_for_paper,'Grain_Par_Rangs');
                    nameOfImage = strcat('Grain_Par_Rangs.png');
                    pathToImage = fullfile(pathToSave,nameOfImage);
                    
                    IM_gpr = figure('name','IM_gpr','Visible','on');
                    
                    imtoshow = imdilate(shrinkifyy, ones(3,3));
                    
                    imshow(imtoshow,'Border','tight');
                    imwrite(imtoshow,pathToImage);
                    close(IM_gpr)
                    
                    imwrite(shrinkifyy_mt10,fullfile(pathToSave,'shrinkifyy_mt10.png'));
                    imwrite(shrinkifyy,fullfile(pathToSave,'shrinkifyy.png'));  
                    
                    saveHorzFileImage(obj,'on')
                    
                    %% Now the csv : 
                    GprToWrite = sum(imfilty,2);
                    
                    % Discretisation of ear cm : 
                    EarDiam =  obj.earMaxDiameter*obj.PX2CM;
                    start_ear = find(sum(obj.mask,2),1,'first');
                    end_ear = find(sum(obj.mask,2),1,'last');
                    
                    % Get the right indexes at top and base ear :
                    GprToWrite = GprToWrite(start_ear:end_ear);
                    Position_pixel = 1:1:length(GprToWrite);
                    Position_cm = 0:(EarDiam/(length(GprToWrite)-1)):EarDiam;
                    pathToSave = fullfile(obj.path_for_paper,'Grain_Par_Rangs');
                    nameOfcsv = strcat('Discretisation_Grain_Par_Rangs.csv');
                    pathToCsv = fullfile(pathToSave,nameOfcsv);
                    
                    fileID = fopen(pathToCsv,'wt');
                    
                    fprintf(fileID,'%s','Code');
                    fprintf(fileID,';%s','Face','GPR','Position_eardiam_cm','Position_eardiam_pixel');
                    fprintf(fileID,'\n');
                    
                    for i  = 1 : length(Position_cm)
                        
                        fprintf(fileID,'%s%s',obj.code,';') ;
                        fprintf(fileID,'%s%s',num2str(obj.numero_face),';');
                        fprintf(fileID,'%2.0f',GprToWrite(i));
                        fprintf(fileID,';%2.4f',Position_cm(i));
                        fprintf(fileID,';%2.0f',Position_pixel(i));
                        fprintf(fileID,'\n');
                        
                    end
                    
                    fclose(fileID);
                    
                end
            end
            
        end

        function val = gprmean(obj) 
            
            shrinkifyy = zeros(size(obj.refinedSegmentation));
            for i = 1:size(obj.refinedSegmentation,1)
                vecty = obj.refinedSegmentation(i,:);
                shrinkifyy(i,:) = bwmorph(vecty,'shrink',inf);
            end
            shrinkifyy_mt10 = bwareaopen(shrinkifyy,10);
            
            h = fspecial('gaussian',[100,100],50);
            imfilty = imfilter(double(shrinkifyy_mt10),h);
            val = mean(sum(imfilty,2)); 
            
            if obj.paper == 1
                
                if obj.numero_face == obj.face_for_paper
                    
                    % Write the images : 
                    pathToSave = fullfile(obj.path_for_paper,'Grain_Par_Rangs');
                    nameOfImage = strcat('Grain_Par_Rangs.png');
                    pathToImage = fullfile(pathToSave,nameOfImage);
                    
                    IM_gpr = figure('name','IM_gpr','Visible','on');
                    
                    imtoshow = imdilate(shrinkifyy, ones(3,3));
                    
                    imshow(imtoshow,'Border','tight');
                    imwrite(imtoshow,pathToImage);
                    close(IM_gpr)
                    
                    imwrite(shrinkifyy_mt10,fullfile(pathToSave,'shrinkifyy_mt10.png'));
                    imwrite(shrinkifyy,fullfile(pathToSave,'shrinkifyy.png'));  
                    
                    saveHorzFileImage(obj,'on')
                    
                    %% Now the csv : 
                    GprToWrite = sum(imfilty,2);
                    
                    % Discretisation of ear cm : 
                    EarDiam =  obj.earMaxDiameter*obj.PX2CM;
                    start_ear = find(sum(obj.mask,2),1,'first');
                    end_ear = find(sum(obj.mask,2),1,'last');
                    
                    % Get the right indexes at top and base ear :
                    GprToWrite = GprToWrite(start_ear:end_ear);
                    Position_pixel = 1:1:length(GprToWrite);
                    Position_cm = 0:(EarDiam/(length(GprToWrite)-1)):EarDiam;
                    pathToSave = fullfile(obj.path_for_paper,'Grain_Par_Rangs');
                    nameOfcsv = strcat('Discretisation_Grain_Par_Rangs.csv');
                    pathToCsv = fullfile(pathToSave,nameOfcsv);
                    fileID = fopen(pathToCsv,'wt');
                    
                    fprintf(fileID,'%s','Code');
                    fprintf(fileID,';%s','Face','GPR','Position_eardiam_cm','Position_eardiam_pixel');
                    fprintf(fileID,'\n');
                    
                    for i  = 1 : length(Position_cm)
                        
                        fprintf(fileID,'%s%s',obj.code,';') ;
                        fprintf(fileID,'%s%s',num2str(obj.numero_face),';');
                        fprintf(fileID,'%2.0f',GprToWrite(i));
                        fprintf(fileID,';%2.4f',Position_cm(i));
                        fprintf(fileID,';%2.0f',Position_pixel(i));
                        fprintf(fileID,'\n');
                        
                    end
                    
                    fclose(fileID);
                    
                end
            end
            
        end
        
        function im = get.refinedSegmentation(obj)
            if ~obj.isRefinedSegmentationSet
                
                % Test, because its possible DL didn't output the image
                % correctly and tho we still need to correct it : 
                DL = 0 ;
                
                % Check for DL : 
                if obj.DEEPLEARNING
                    try
                        obj.refinedSegmentation = readImage(obj,'A');
                        obj.refinedSegmentation(obj.refinedSegmentation>0)=1;
                        Size = size(obj.RGBImage);
                        obj.refinedSegmentation = imresize(obj.refinedSegmentation,[Size(1) Size(2)]);
                        
                        if obj.paper == 1
                            
                            if obj.numero_face == obj.face_for_paper
                                
                                pathToSave = fullfile(obj.path_for_paper);
                                nameOfImage = strcat('RefinedSegmentation.png');
                                pathToImage = fullfile(pathToSave,nameOfImage);
                                
                                IM_gpr = figure('name','IM_gpr','Visible','on');
                                                                
                                imshow(obj.refinedSegmentation,'Border','tight');
                                imwrite(obj.refinedSegmentation,pathToImage);
                                close(IM_gpr)
                                                                
                            end
                
                        end
            
                        DL = 1;
                    catch
                        DL = 0;
                    end
                end
                
                % Check for the empiric seg : 
                if DL == 0
                    if strcmp(obj.SEGMENTATIONTYPE,'New')
                        obj.refinedSegmentation = obj.refineSegmentation;
                    elseif strcmp(obj.SEGMENTATIONTYPE,'Old')
                        obj.refinedSegmentation = obj.refineSegmentation_Old;
                    end
                end
                
                obj.isRefinedSegmentationSet = true;
                
            end
            im = obj.refinedSegmentation;
        end

        function output = get.apexMissingKernels(obj)
            
            profile = obj.earDiameterProfile;
            ss = regionprops(imopen(obj.refinedSegmentation,strel('disk',3)),'Area','PixelIdxList');
            toto = uint8(obj.refinedSegmentation);
            areas = cat(1,ss.Area);
            for i = 1:length(ss)
                if areas(i) < (mean(areas) - 1.5*std(areas))
                    toto(ss(i).PixelIdxList) = 2;
                end
            end
            ratio_grain = sum(imfill(imclose(obj.fertileZoneMask,strel('disk',2)),'holes') - (toto==2))./sum(obj.mask);
            ratio_grain(isnan(ratio_grain)) = 0;
            ratio_grain(ratio_grain>1) = 1;
            
            x0 = find(sum(obj.mask)>0,1,'first');
            x1 = find(ratio_grain>0.7,1,'first');
            
            
            rc = obj.ring_apical_truth;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            x = zeros(ceil((x1-x0)/50),1);
            kernelSize = x;
            
            kernelSize(1) = 0.85 * (pi*profile(x1))/rc;
            x(1) = x1;
            n=2;
            
            while (x(n-1) > x0)
                kernelSize(n) = max([0.85 * (pi*profile(x(n-1)))/rc, 6]);
                x(n) = floor(x(n-1) - kernelSize(n));
                n=n+1;
            end
            %             val = n-2;
            xPx = x;
            xPx(xPx<(x0+6)) = [];
            novaries = length(xPx);
            output.n = novaries;
            output.pos = xPx;
            
        end
        
        function struct = get.ringCountAvg(obj)
            if ~obj.isRingCountAvgSet
                obj.ringCountAvg = obj.ringCount;
                obj.isRingCountAvgSet = true;
            end
            struct = obj.ringCountAvg;
        end
        
        function struct = get.GrainPerRanksCount(obj)
            
            if ~obj.isGrainPerRanksCountSet
                
                
                RanksTop = obj.RanksCount.Top ;
                RanksMid = obj.RanksCount.Mid ;
                RanksBot = obj.RanksCount.Bot ;
                
                if RanksTop ~= 0
                WhichRanksTop = min(length(obj.horzFilesProps.sortedFileLengthTop),max(2,round(RanksTop/2-2))) ;
                gpr.Top = mean(obj.horzFilesProps.sortedFileLengthTop(1:WhichRanksTop));
                gpr.MaxTop = obj.horzFilesProps.sortedFileLengthTop(1);
                else 
                    gpr.Top = 0 ;
                    gpr.MaxTop = 0 ;
                end
                
                if RanksMid ~= 0
                WhichRanksMid = min(length(obj.horzFilesProps.sortedFileLengthMid),max(2,round(RanksMid/2-2))) ;
                gpr.Mid = mean(obj.horzFilesProps.sortedFileLengthMid(1:WhichRanksMid));
                gpr.MaxMid = obj.horzFilesProps.sortedFileLengthMid(1);
                else 
                    gpr.Mid = 0 ;
                    gpr.MaxMid = 0 ;
                end
                
                if RanksBot ~= 0
                WhichRanksBot = min(length(obj.horzFilesProps.sortedFileLengthBot),max(2,round(RanksBot/2-2))) ;
                gpr.Bot = mean(obj.horzFilesProps.sortedFileLengthBot(1:WhichRanksBot));
                gpr.MaxBot = obj.horzFilesProps.sortedFileLengthBot(1);
                else 
                    gpr.Bot = 0 ;
                    gpr.MaxBot = 0 ;
                end
                
                obj.GrainPerRanksCount = gpr ; 
                obj.isGrainPerRanksCountSet = true ;
                
            end
            
            struct = obj.GrainPerRanksCount ; 
        
        end
        
        function struct = get.GrainsAttributes(obj)
            
            if ~obj.isGrainsAttributesSet
                
                if sum(obj.refinedSegmentation(:)) ~= 0;
                    
                obj.GrainsAttributes.ringDimensions = obj.ringDimensions;
                
                obj.GrainsAttributes.NbGr = ...
                    obj.GrainPerRanksCount.Bot * obj.RanksCount.Bot+...
                    obj.GrainPerRanksCount.Mid * obj.RanksCount.Mid + ...
                    obj.GrainPerRanksCount.Top * obj.RanksCount.Top ;  
                                
                obj.GrainsAttributes.SurfGrainsPixel = sum(sum(obj.refinedSegmentation==1));
                obj.GrainsAttributes.SurfEarPixel = sum(sum(obj.mask==1));
                obj.GrainsAttributes.SurfGrains = (obj.PX2CM ^2) * obj.GrainsAttributes.SurfGrainsPixel ;
                obj.GrainsAttributes.SurfEar = (obj.PX2CM^2) * obj.GrainsAttributes.SurfEarPixel ;
                obj.GrainsAttributes.GrainRatio = obj.GrainsAttributes.SurfGrains / obj.GrainsAttributes.SurfEar ;
                obj.GrainsAttributes.MeanGrainSurf = obj.GrainsAttributes.SurfGrains / obj.GrainsAttributes.NbGr ;
                
                obj.isGrainsAttributesSet = true ;

                else
                    
                    obj.GrainsAttributes.ringDimensions = {};
                    obj.GrainsAttributes.NbGr = 0;
                    obj.GrainsAttributes.SurfGrainsPixel = 0;
                    obj.GrainsAttributes.SurfEarPixel = 0 ;
                    obj.GrainsAttributes.SurfGrains = 0;
                    obj.GrainsAttributes.SurfEar = 0;
                    obj.GrainsAttributes.GrainRatio = 0;
                    obj.GrainsAttributes.MeanGrainSurf = 0 ;
                 
                obj.isGrainsAttributesSet = true ;
                
                end
                
            end
            
            struct = obj.GrainsAttributes;
        end
          
        function struct = get.ZoneMasks(obj)
 
            if ~obj.isZoneMasksSet
                
                % Change zonemask : 
                [A,F,B,Ratio,ratio_grain] = obj.fertileZoneMaskDimensions(0.5,0.5); % 0.6
                
                % Deal with empty ears :
                if any([isnan(A) isnan(F) isnan(B)])
                    F = 0;
                    A = round((obj.horzAxisLength)/2,2);
                    B = round((obj.horzAxisLength)/2,2);
                end
                
                % Stock outputs :
                obj.ZoneMasks.ApexAbortion = A ;
                obj.ZoneMasks.BasalAbortion = B ;
                obj.ZoneMasks.FertileZone = F ;
                obj.ZoneMasks.FertileZoneGrainRatio = Ratio;
                obj.ZoneMasks.ear_to_grain_ratio = ratio_grain;
                
                obj.isZoneMasksSet = true ;
                
            end
            
            struct = obj.ZoneMasks;    
        end
        
        % Savers : 
        function populateTempFolder(obj)
                
            writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
            if ~isdir(fullfile(writepath,'tmp'))
                mkdir(writepath,'tmp');
            end
            writepath = fullfile(writepath,'tmp');
            
            % Write images : 
            imwrite(obj.horzFilesProps.IfilesColor,fullfile(writepath,'finalSeg.png'))
            imwrite(obj.refinedSegmentation,fullfile(writepath,'refinedSeg.png'))
            
        end
        
        function save_eardata(obj)
            
            writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
            FaceEarOutputs = obj ; 
            save(fullfile(writepath,'FaceEarOutputs.mat'),'FaceEarOutputs');            
            
        end
            
        % definition of methods declared in different files
        output = refineSegmentation(obj)
        output = refineSegmentation_Old(obj)
        output = resizeProps(obj) 
        output = horizontalFileDetection(obj) 
        output = verticalFileDetection(obj)
        output = ringCount(obj)
        
    end
    
    methods (Access = private)
    end
end