function Status  = writeEarImages(workdir,dpath,fname,face,nameatpos,ROIs,positions,TLcorners,ImInfo)

    % Loop over the number of ears in image : 
    for i = 1:numel(positions)
        
        % get the position of the ear in the image : 
        p = positions(i) ; 
        
        % get the path of this specific ear
        writepath = fullfile(workdir, 'data' ,char(nameatpos{p}), num2str(face));

        % Read the right images : 
        if regexp(fname,'\d{1}U_*')
            IR_image = imread(fullfile(dpath,['I' num2str(face) fname '.jpeg']));
            RGB_image = imread(fullfile(dpath,['V' num2str(face) fname '.jpeg']));
             MIX_image = imread(fullfile(dpath,['M' num2str(face) fname '.jpeg']));
        else
            IR_image = imread(fullfile(dpath,['I' num2str(face) 'xM@' fname '.jpeg']));
            RGB_image = imread(fullfile(dpath,['V' num2str(face) 'xM@' fname '.jpeg']));
             MIX_image = imread(fullfile(dpath,['M' num2str(face) 'xM_' fname '.jpeg']));
        end

        try
            %% Now check exif infos :
            RGB_image = do_undistortion( ImInfo,RGB_image );
            IR_image = do_undistortion( ImInfo,IR_image );
        catch
             warning('phymea:writeEarImages', 'Problem with un-distortion');
        end
        
        
        %% Now crop images accordingly : 
        % crop images : 
        IR_crop = maskAndCrop(IR_image, TLcorners(p,:), ROIs{p});
        RGB_crop = maskAndCrop(RGB_image, TLcorners(p,:), ROIs{p});
         MIX_crop = maskAndCrop(MIX_image, TLcorners(p,:), ROIs{p});
        MASK = padarray(ROIs{p},[50,50]);
        MASK = imopen(MASK,strel('disk',10));
        
        % Write images : 
        imwrite(IR_crop, fullfile(writepath,'IR.png'));
        imwrite(RGB_crop, fullfile(writepath,'RGB.png'));
         imwrite(MIX_crop, fullfile(writepath,'MIX.png'));
        imwrite(MASK, fullfile(writepath,'ROI.png'));
        
        save(fullfile(strcat(writepath,'\','Image.Metadata')),'ImInfo');
        Status = 1;
        
    end
end

function im = maskAndCrop(I,TLcorner,ROI)
    M = size(I,1);
    N = size(I,2);
    x0 = TLcorner(1);
    y0 = TLcorner(2);
    roi = ROI;
    [X,Y] = meshgrid(x0:(x0+size(roi,2)-1),y0:(y0+size(roi,1)-1));
    idx = sub2ind([M,N],Y,X);
    if size(I,3) == 3  % 3 channel image
        I_channel = uint8(zeros(size(roi,1)+100,size(roi,2)+100,3));
        for channel = 1:3
            I_tmp = uint8(I(:,:,channel));
            I_tmp = I_tmp(idx).*uint8(roi);
            I_channel(:,:,channel) = padarray(I_tmp,[50,50]);
        end
        im = I_channel;
    elseif size(I,3) == 1 % intensity image
        I_tmp = uint8(I(idx)).*uint8(roi);
        I_tmp = padarray(I_tmp,[50,50]);
        im = I_tmp;
    end
end