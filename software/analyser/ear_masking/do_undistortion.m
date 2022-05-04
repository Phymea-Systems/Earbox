function [ Im_output ] = do_undistortion( ImInfo,Im_input )
% Typical undistortion for imaged via image itself and camera parameters

if isfield(ImInfo,'CameraParams')
    IntrinsicMatrix = [ImInfo.CameraParamsValue(1) 0 0;...
        ImInfo.CameraParamsValue(2) ImInfo.CameraParamsValue(3) 0;...
        ImInfo.CameraParamsValue(4) ImInfo.CameraParamsValue(5) 1];
    radialDistortion = [ImInfo.CameraParamsValue(6) ImInfo.CameraParamsValue(7) ImInfo.CameraParamsValue(10)];
    tangentialDistortion =[ImInfo.CameraParamsValue(8) ImInfo.CameraParamsValue(9)];
    cameraParams = cameraParameters('IntrinsicMatrix',IntrinsicMatrix,...
        'RadialDistortion',radialDistortion,...
        'TangentialDistortion',tangentialDistortion);
    
    Im_output = undistortImage(Im_input,cameraParams,'OutputView','valid');
else
    Im_output = Im_input;
end


end

