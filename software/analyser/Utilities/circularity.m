function [metrics,flags,centroids] = circularity(bw,dodraw,threshold)

if nargin<2
    dodraw = false;
    threshold = 0.6;
end
if nargin<3
    threshold = 0.6;
end
% remove all object containing fewer than 30 pixels
% bw = bwareaopen(bw,30);

% fill a gap in the pen's cap
% se = strel('disk',1);
% bw = imclose(bw,se);

% fill any holes, so that regionprops can be used to estimate
% the area enclosed by each of the boundaries
% bw = imfill(bw,'holes');

% imshow(bw)

[B,L] = bwboundaries(bw,'noholes');
    
if isempty(B)
    metrics = 0;
    centroids = [];
    flags = [];
    return
end

% Display the label matrix and draw each boundary
if dodraw
    imshow(label2rgb(L, @jet, [.5 .5 .5]))
    hold on
    for k = 1:length(B)
      boundary = B{k};
      plot(boundary(:,2), boundary(:,1), 'k', 'LineWidth', 2)
    end
end

%output init
metrics = zeros(length(B),1);
centroids = zeros(length(B),2);
flags = false(length(B),1);

stats = regionprops(L,'Area','Centroid','PixelIdxList');


% loop over the boundaries
for k = 1:length(B)

  % obtain (X,Y) boundary coordinates corresponding to label 'k'
  boundary = B{k};

  % compute a simple estimate of the object's perimeter
  delta_sq = diff(boundary).^2;
  perimeter = sum(sqrt(sum(delta_sq,2)));

  % obtain the area calculation corresponding to label 'k'
  area = stats(k).Area;

  % compute the roundness metric
  metric = 4*pi*area/perimeter^2;
  
  %add to output
  metrics(k) = metric;
  
  
  % display the results
  metric_string = sprintf('%2.2f',metric);

  % mark objects above the threshold with a black circle
  if metric > threshold
      flags(k) = true;
      centroid = stats(k).Centroid;
      centroids(k,:) = centroid;
      if dodraw
          plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
        plot(centroid(1),centroid(2),'ko');
      end
  end

  if dodraw
      text(boundary(1,2)-35,boundary(1,1)+13,metric_string,'Color','y',...
           'FontSize',14,'FontWeight','bold');
  end

end

if dodraw
      title(['Metrics closer to 1 indicate that ',...
       'the object is approximately round']);
end
% %    
%    