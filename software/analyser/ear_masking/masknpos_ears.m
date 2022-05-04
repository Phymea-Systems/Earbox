function [Old,New,ROIs,positions,TLcorners,isValid,nameatpos,Im_info] = masknpos_ears(filename,codes,NB_EARS,typephoto)


% loose initial ear position
C1 = [1747    1814];
C2 = [1710    1266];
C3 = [1697    691];

% Read image : 
I_im = imread(filename);


% Read exif info if valid : 
ExifData = struct();
ExifData.Status = 'Not Read' ; 
try
    ExifData.ExifInfo = imfinfo(filename); 
    ExifData = parse_exif(ExifData);
    ExifData.Status = 'Read' ; 
catch 
    ExifData.Status = 'Invalid' ; 
    warning('phymea:masknpos_ears', 'Problem gathering exif data');
end


%% Undistort image if neeeded : 
try
I_im = do_undistortion( ExifData,I_im );
catch 
    ExifData.Status = 'Invalid' ; 
    warning('phymea:masknpos_ears', 'Problem with un-distortion');

figure(020212),hold on
imshowpair(I_im, imobrcbr(I_im,strel('rectangle',[100 40])), 'montage')% 
hold off

end

% mask ears
I_im = rgb2gray(I_im);
I_im(:,1:250) = 0;
I_im(:,(end-249):end) = 0;

%% Careful now we can have 4 ears max, so need to clear borders ! :
% We assume 3 ears : 
mask = imopen(imfill(bwareafilt(imclearborder(imerode(I_im,strel('disk',5))>80),NB_EARS),'holes'),strel('disk',15)); % base 50 : 
mask = bwareafilt(mask,NB_EARS);
mask = bwareaopen(mask, 10000);

ss_tot = regionprops(mask,'Centroid','PixelIdxList');

% Remove data if centroids are too close from the sides : 
% (lim = <300 and >2200)
n=1;
for c = 1:length(ss_tot)
    if ss_tot(c).Centroid(2) > 300 && ss_tot(c).Centroid(2) < 2200
        ss(n)=ss_tot(c);
        n=n+1;
    end
end
    
cc = cat(1,ss.Centroid);

Old = cell(1,length(cc));
New = cell(1,length(cc));


% Put everything together : 
sorted_cc = sortrows(cc,2) ;

% Now check what is in each potential position : 
% Checking from bottom (C1) to top (C2) of image : 
ispos1 = abs(C1(2) - sorted_cc(:,2)) < 200;
ispos2 = abs(C2(2) - sorted_cc(:,2)) < 200;
ispos3 = abs(C3(2) - sorted_cc(:,2)) < 200;

validpos = ~all(ispos1 & ispos2 & ispos3);
if ~validpos
    error('phymea:masknpos_ears', 'impossible to find ear position');
end

if (sum(ispos1)>1 |sum(ispos2)>1 | sum(ispos3)>1)
    error('phymea:masknpos_ears', 'two ears objects seem to be at the same position');

end

maskPerEar =  zeros([size(mask) 3]);

% Correct to find the right number of ears on the image
% Independently of the location of the ear on the image ! 
% Replace mask with a 3D matrix mask of all ears ? ==> Not working
ispos = [ispos1 ispos2 ispos3];
nameatpos = cell(1,3);
NB_EARS = min(3,sum(sum(ispos)));
Old_centroid = [0 0 0];
New_Centroid = [0 0 0];
k=1;
for pos = 1:3
    if sum(ispos(:,pos)) == 1
        
        if strcmp(typephoto,'U')
            nameatpos{pos} = codes(pos);
        else
            nameatpos{pos} = codes(k);
        end
        
        New{pos} = nameatpos{pos};
        k=k+1; 
        TempMask = zeros(size(mask));
        TempMask2 = zeros(size(mask));

        % Find its right place in the non sorted one : 
        NonSortedPosition = find(cc(:,2)==sorted_cc(ispos(:,pos),2)); 
        TempMask(ss(NonSortedPosition).PixelIdxList) = 1;

        New_Centroid(pos)=ss(NonSortedPosition).Centroid(2);
        Old_centroid(pos)=ss(ispos(:,pos)).Centroid(2);
        
        maskPerEar(:,:,pos) = TempMask ; 
        mask(ss(ispos(:,pos)).PixelIdxList) = 1;
    end
end


ROIs = cell(3,1);
positions = zeros(NB_EARS,1);
isValid = true(NB_EARS,1);
TLcorners = zeros(3,2);
for ear = 1:NB_EARS
    
    ear_pos = find([ispos1(ear) ispos2(ear) ispos3(ear)]);
    
    if isempty(ear_pos)
        warning('%s\n%s\n%s','MEA:EarCount',filename,'Number of codes differs from visible ears number');
        isValid(ear) = false;
    else
        ear_mask = uint8(maskPerEar(:,:,ear_pos));

        
        [val,pos] = max(ear_mask~=0,[],1);
        y0 = min(pos(val));
        [val,pos] = max(ear_mask~=0,[],2);
        x0 = min(pos(val));
        [val,pos] = max(flipud(ear_mask)~=0,[],1);
        y1 = size(ear_mask,1) - min(pos(val)) + 1;
        [val,pos] = max(fliplr(ear_mask)~=0,[],2);
        x1 = size(ear_mask,2) - min(pos(val)) + 1;
        [X,Y] = meshgrid(x0:x1,y0:y1);
        idx = sub2ind(size(ear_mask),Y,X);
        ROIs{ear_pos} = logical(ear_mask(idx));
        positions(ear) = ear_pos; 
        TLcorners(ear_pos,:) = [x0,y0]; 
        
    end 
end

Im_info = ExifData ; 


function ImInfo = parse_exif(ExifData)

% Exif examples : 
% IFD1.ImageDescription=fx349.3601s111.1111fy349.7267cx258.0883cy210.5905ra111.0504rb111.0504ta111.1111tb-111.1651sp111.1111nc1 
% IFD1.Software=zea_ui_v1.0
% IFD1.Artist=19-25-19_Masession

StringCamera = ExifData.ExifInfo.ExifThumbnail.ImageDescription;
StringCamera = strrep(ExifData.ExifInfo.ExifThumbnail.ImageDescription,'sp','dp');
StringVersioning = ExifData.ExifInfo.ExifThumbnail.Software;
StringSession = ExifData.ExifInfo.ExifThumbnail.Artist;

% Output exif : 
SplitVersion = strsplit(StringVersioning,'zea_ui_v');
ExifData.Version = SplitVersion{2};  % Convert to numeric ? 
SplitSession = strsplit(StringSession,'_');
ExifData.DateOfCreation = SplitSession{1};  
ExifData.SessionName = StringSession(length(SplitSession{1})+2:end);  

try
    % Parse camera :
    Strings = {'fx','s','fy','cx','cy','ra','rb','ta','tb','dp','nc'};
    ParamsValue = zeros(1,numel(Strings));
    StringCut = StringCamera;
    for param = 1:numel(Strings)
        StringCut = strsplit(StringCamera,Strings{param});
        if ~strcmp(Strings{param},Strings{end})
            StringCut = strsplit(StringCut{2},Strings{param+1});
            ParamsValue(param) = str2num(StringCut{1});
            StringCut = StringCut{2};
        else
            ParamsValue(param)=str2num(StringCut{2});
        end
    end
    
    ExifData.CameraParams = {'fx','s','fy','cx','cy','k1','k2','p1','p2','k3','nc'};
    ExifData.CameraParamsValue = ParamsValue;
catch
    
    ExifData.CameraParams = 'NaN';
    ExifData.CameraParams = Strings;
    
end

ImInfo = ExifData;

