function output = horizontalFileDetection(obj)

% if seg is empty dont even try
if sum(obj.refinedSegmentation(:)) == 0;
    output.fileLookUp = [];
    output.sortedFileLength = 0;
    output.fileLength = 0;
    output.sortedIdx = [];
    output.fileYavg = 0;
    output.fileYstd = 0;
    output.sortedFileLengthTop = 0;
    output.sortedFileLengthMid = 0;
    output.sortedFileLengthBot = 0;
    output.IfilesColor = 0 ;
    return
end
    
% FILE DETECTION
pp = obj.resizedProps;
pp2 = obj.segmentedImageProps;
[~,basetoapex_idx] = sort(pp.centroids_cor(:,1),'descend');
pp.kept_idx_cor(basetoapex_idx);

endposx = find(sum(obj.horizontalAxis) > 0,1,'last');
endposy = find(obj.horizontalAxis(:,endposx),1,'first');
eucl_d_to_base =  sqrt(sum((ones(length(pp.kept_idx_cor),1)*[endposx endposy]-pp.centroids_cor).^2,2));

vert_mean_dist = zeros(size(pp2.majors));
vert_mean_pos = zeros(size(pp2.majors));
for it = 1:length(pp2.majors)
    vert_mean_dist(it) = mean(obj.dist2AxisMap(cat(1,pp2.pixelIdxLists{it})));
    vert_mean_pos(it) = mean(obj.posRel2AxisMap(cat(1,pp2.pixelIdxLists{it})));
end

start_cost = eucl_d_to_base + vert_mean_dist;
edge_cost = vert_mean_dist; 
done = false(length(pp2.majors),1);
done(~pp.kept_idx_cor) = true;
current_angle = obj.horzAxisAngle;
file_number = 1;
file_lookup = zeros(size(pp2.majors));
    
% if we get two grains exactly outside of segmentation : 
if isempty(start_cost(~done))
    
    output.fileLookUp = [];
    output.sortedFileLength = 0;
    output.fileLength = 0;
    output.sortedIdx = [];
    output.fileYavg = 0;
    output.fileYstd = 0;
    output.sortedFileLengthTop = 0;
    output.sortedFileLengthMid = 0;
    output.sortedFileLengthBot = 0;
    output.IfilesColor = 0 ;
    return
    
else 
    good_idx = find(start_cost == min(start_cost(~done)));
end


IfilesColor = zeros(size(obj.mask));
mean_dist = zeros(length(pp2.majors),1);
timeout = tic;
while(~all(done))
    % We need a timeout else its a never ending loop :
    if toc(timeout) > 120
        error('timeout in file detection')
    end
    bool_idx = false(size(pp.kept_idx_cor));
    bool_idx(good_idx) = true;
    eucl_d = sqrt(sum((ones(length(bool_idx),1)*pp.centroids_cor(bool_idx,:)-pp.centroids_cor(bool_idx>-1,:)).^2,2));
    angle_to = -atan2(pp.centroids_cor(bool_idx>-1,2)-ones(length(bool_idx),1)*pp.centroids_cor(bool_idx,2),pp.centroids_cor(bool_idx>-1,1)-ones(length(bool_idx),1)*pp.centroids_cor(bool_idx,1));
    angle_error = ones(length(bool_idx),1)*current_angle - angle_to;
    angle_error(angle_error>pi) = -2*pi+angle_error(angle_error>pi);
    angle_error(angle_error<-pi) = 2*pi+angle_error(angle_error<-pi);
    size_error = abs(mean(pp.dgrain_wtf(bool_idx | (file_lookup == file_number))) - pp.dgrain_wtf);
    vert_error = abs(vert_mean_pos(bool_idx) - vert_mean_pos);
    bad_angle = abs(angle_error) > atan2((sin(deg2rad(72.5424))*2*pp.dmean),eucl_d.*cos(angle_error)) | (cos(abs(angle_error)) < 0.4);%
    cost = sqrt((0.3.*(eucl_d.*eucl_d) + 0.7.*(vert_error.*vert_error) + 3.*(size_error).*(size_error)));
    
    cost(bool_idx | done | cost < 0| bad_angle) = Inf;

    [~,idx] = min(cost);
    if length(idx) ~= 1
        keyboard
    end
    if cost(idx) > 50
        mean_dist(good_idx) = NaN;
        done(good_idx) = true;
        file_lookup(good_idx) = file_number;
        
        for pt_idx = 1:length(pp2.majors)
            if pp.kept_idx_cor(pt_idx)
                IfilesColor(cat(1,pp2.pixelIdxLists{pt_idx})) = file_lookup(pt_idx);
            end
        end
        line_repulse = (-bwdist(~(1-(IfilesColor > 0))));
        line_repulse = line_repulse - min(line_repulse(:));
        
        file_number = file_number+1;
        if ~all(done)
            good_idx = find(start_cost == min(start_cost(~done)));
        end
    else
        done(good_idx) = true;
        file_lookup(good_idx) = file_number;
        good_idx = idx;
        mean_dist(good_idx) = eucl_d(idx);
    end
end
%%%%%%%%%%%%%%




for iii = 1:max(file_lookup)
    file_length(iii) = sum(file_lookup == iii);
end


% REGROUPER LES LIGNES
for fileidx = 1:max(file_lookup)
    idx = find(file_lookup == fileidx);
    min(pp.centroids_cor(idx,1));
    n=1;
    for i = idx'
        angle_to = -atan2(abs(pp.centroids_cor(idx(idx~=i),2)-ones(sum(idx~=i),1)*pp.centroids_cor(i,2)),abs(pp.centroids_cor(idx(idx~=i),1)-ones(sum(idx~=i),1)*pp.centroids_cor(i,1)));
        n=n+1;
        file_axis(n) = mean(rad2deg(angle_to));
        file_std(n) = std(rad2deg(angle_to));
    end
    mean_file_axis = abs(obj.horzAxisAngle + mean(file_axis));
    mean_std_axis = mean(file_std);
end



% Divide in 3 zones :
x3 = find(sum(obj.mask),1,'first');
x0 = find(sum(obj.mask),1,'last');
xrange = x0 - x3;
x2 = ceil(xrange/3 + x3);
x1 = ceil(xrange/3 + x2);
%Top : 
ToLookAt = file_lookup(pp2.centroids(:,1) < x0 & pp2.centroids(:,1) >= x1);
if ~isempty(ToLookAt) && sum(ToLookAt)~=0
    for iii = 1:max(ToLookAt)
        output.filetop(iii) = sum(ToLookAt == iii);
    end
    [output.sortedFileLengthTop,~] = sort(output.filetop,'descend');
else
    output.sortedFileLengthTop = 0 ;
end

%Mid :
ToLookAt = file_lookup(pp2.centroids(:,1) < x1 & pp2.centroids(:,1) >= x2);
if ~isempty(ToLookAt) && sum(ToLookAt)~=0
    for iii = 1:max(ToLookAt)
        output.filemid(iii) = sum(ToLookAt == iii);
    end
    [output.sortedFileLengthMid,~] = sort(output.filemid,'descend');
else
    output.sortedFileLengthMid = 0 ;
end
%Bot : 
ToLookAt = file_lookup(pp2.centroids(:,1) < x2 & pp2.centroids(:,1) >= x3);
if ~isempty(ToLookAt) &&  sum(ToLookAt)~=0
    for iii = 1:max(ToLookAt)
        output.filebot(iii) = sum(ToLookAt == iii);
    end
    [output.sortedFileLengthBot,~] = sort(output.filebot,'descend');
else
    output.sortedFileLengthBot = 0 ;
end

[sorted_file_length,sorted_idx] = sort(file_length,'descend');

output.fileLookUp = file_lookup;
output.sortedFileLength = sorted_file_length;
output.fileLength = file_length;
output.sortedIdx = sorted_idx;
output.IfilesColor = IfilesColor;

n=1;
for i = 1:max(file_lookup)
    Yavg(n) = mean(pp.centroids_cor(file_lookup==i,2));
    Ystd(n) = std(pp.centroids_cor(file_lookup==i,2));
    n=n+1;
end
output.fileYavg = Yavg;
output.fileYstd = Ystd;


end