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

