function output = verticalFileDetection(obj)

pp = obj.resizedProps;
pp2 = obj.segmentedImageProps;

% FILE (VERTICAL) DETECTION
% figure(3)
% hold off
% imshow(Itransition)
% hold on
if ~isempty(pp2.areas)
    
    [~,basetoapex_idx] = sort(pp.centroids_cor(:,1),'descend');
    pp.kept_idx_cor(basetoapex_idx);
    
    % attention, faut-il ici introduire les zones a grains plutot que de
    % chercher de bas en haut completement?
    endposx = find(sum(obj.horizontalAxis) > 0,1,'last');
    endposy = find(obj.horizontalAxis(:,endposx),1,'first');
    eucl_d_to_base =  sqrt(sum((ones(length(pp.kept_idx_cor),1)*[endposx endposy]-pp2.centroids).^2,2));
    
    posreltobase = double(obj.mask);
    for i = 1:size(posreltobase,2)
        posreltobase(:,i) = double(double(obj.mask(:,i)).*(endposx-i+1));
    end
    
    vert_mean_dist = zeros(size(pp2.majors));
    horz_mean_pos = zeros(size(pp2.majors));
    for it = 1:length(pp2.majors)
        vert_mean_dist(it) = mean(posreltobase(cat(1,pp2.pixelIdxLists{it})));
        horz_mean_pos(it) = mean(posreltobase(cat(1,pp2.pixelIdxLists{it})));
    end
    % xx = ceil(pp2.centroids(:,1));
    % yy = ceil(pp2.centroids(:,2));
    % crop_idx = sub2ind(size(obj.mask),yy,xx);
    
    % start_cost = eucl_d_to_base + obj.dist2AxisMap(crop_idx);
    start_cost = eucl_d_to_base + vert_mean_dist;
    edge_cost = vert_mean_dist; %obj.dist2AxisMap(crop_idx);
    done = false(length(pp2.majors),1);
    done(~pp.kept_idx_cor) = true;
    current_angle = obj.horzAxisAngle+pi/2;
    file_number = 1;
    rank_idx = 1;
    rank_lookup = zeros(size(pp2.majors));
    rank_idx_lookup = rank_lookup;
    
    if ~isempty(min(start_cost(~done)))
        
        good_idx = find(start_cost == min(start_cost(~done)));
        % scatter(pp2.centroids(good_idx,1),pp2.centroids(good_idx,2),20,'g','filled');
        % frameit = 0;
        % print(fig,'-djpeg','-r300',[outputdir 'video_' num2str(frameit) '.jpg']);
        
        
        IfilesColor = zeros(size(obj.mask));
        % line_repulse = IfilesColor;
        mean_dist = zeros(length(pp2.majors),1);
        timeout = tic;
        while(~all(done))
            if toc(timeout) > 120
                error('timeout in rank detection')
            end
            % if good_idx == 193
            %     keyboard;
            % end
            bool_idx = false(size(pp.kept_idx_cor));
            bool_idx(good_idx) = true;
            eucl_d = sqrt(sum((ones(length(bool_idx),1)*pp.centroids_cor(bool_idx,:)-pp.centroids_cor(bool_idx>-1,:)).^2,2));
            angle_to = -atan2(pp.centroids_cor(bool_idx>-1,2)-ones(length(bool_idx),1)*pp.centroids_cor(bool_idx,2),pp.centroids_cor(bool_idx>-1,1)-ones(length(bool_idx),1)*pp.centroids_cor(bool_idx,1));
            angle_error = ones(length(bool_idx),1)*current_angle + angle_to;
            angle_error(angle_error>pi) = -2*pi+angle_error(angle_error>pi);
            angle_error(angle_error<-pi) = 2*pi+angle_error(angle_error<-pi);
            size_error = abs(mean(pp.dgrain_wtf(bool_idx | (rank_lookup == file_number))) - pp.dgrain_wtf);
            %     hquiv = quiver(pp2.centroids(bool_idx,1), pp2.centroids(bool_idx,2), 20*cos(current_angle), 20*sin(current_angle));
            %     pause
            %     xx = ceil(pp2.centroids(bool_idx,1));
            %     yy = ceil(pp2.centroids(bool_idx,2));
            % vert_error = obj.dist2AxisMap(yy,xx) - obj.dist2AxisMap(crop_idx);
            horz_error = abs(horz_mean_pos(bool_idx) - horz_mean_pos - 5);% mean(vert_mean_pos(bool_idx | (file_lookup == file_number))) - vert_mean_pos
            bad_angle = abs(angle_error) > atan2((sin(deg2rad(35.5424))*2*pp.dmean),2*eucl_d.*cos(angle_error)) | (cos(abs(angle_error)) < 0.8);%
            % bad_angle = (cos(angle_error) < 0);
            cost = sqrt((0.3.*(eucl_d.*eucl_d) + 0.7.*(horz_error.*horz_error) + 3.*(size_error).*(size_error)));% + rad2deg(angle_error).*rad2deg(angle_error)));% +  0.7.*line_repulse(crop_idx).*line_repulse(crop_idx)));%;.*(1+0.1*rad2deg(abs(angle_error)));% .* (abs(sin(angle_error)).*cos(angle_error));
            % cost = [cost(:,1)./max(cost(:,1)) cost(:,2)./max(cost(:,2))];
            % cost = (cost(:,1) + cost(:,2)) ./ 2;
            %     if good_idx == 199
            %         keyboard
            %     end
            
            cost(bool_idx | done | cost < 0| bad_angle) = Inf;
            %     cost(bool_idx | done | cost < 0) = Inf;
            %     hs = scatter3(pp2.centroids(:,1),pp2.centroids(:,2),cost,'filled','MarkerFaceColor','r');
            % frameit = frameit+1;
            % print(fig,'-djpeg','-r300',[outputdir 'video_' num2str(frameit) '.jpg']);
            %     pause()
            [~,idx] = min(cost);
            % [good_idx cost(idx)]
            if length(idx) ~= 1
                keyboard
            end
            if cost(idx) > 60
                mean_dist(good_idx) = NaN;
                done(good_idx) = true;
                %             scatter(pp2.centroids(good_idx,1),pp2.centroids(good_idx,2),20,'r','filled');
                % frameit = frameit+1;
                %     print(fig,'-djpeg','-r300',[outputdir 'video_' num2str(frameit) '.jpg']);
                rank_lookup(good_idx) = file_number;
                rank_idx_lookup(good_idx) = rank_idx;
                rank_idx = rank_idx+1;
                
                for pt_idx = 1:length(pp2.majors)
                    if pp.kept_idx_cor(pt_idx)
                        IfilesColor(cat(1,pp2.pixelIdxLists{pt_idx})) = rank_lookup(pt_idx);
                    end
                end
                line_repulse = (-bwdist(~(1-(IfilesColor > 0))));
                line_repulse = line_repulse - min(line_repulse(:));
                
                file_number = file_number+1;
                rank_idx= 1;
                if ~all(done)
                    good_idx = find(start_cost == min(start_cost(~done)));
                    %                     scatter(pp2.centroids(good_idx,1),pp2.centroids(good_idx,2),20,'g','filled');
                    % frameit = frameit+1;
                    %         print(fig,'-djpeg','-r300',[outputdir 'video_' num2str(frameit) '.jpg']);
                end
            else
                %             scatter(pp2.centroids(idx,1),pp2.centroids(idx,2),20,'b','filled');
                %             quiver(pp2.centroids(bool_idx,1), pp2.centroids(bool_idx,2), pp2.centroids(idx,1)-pp2.centroids(bool_idx,1), pp2.centroids(idx,2)-pp2.centroids(bool_idx,2));
                % frameit = frameit+1;
                %     print(fig,'-djpeg','-r300',[outputdir 'video_' num2str(frameit) '.jpg']);
                %             hquivUP = quiver(pp2.centroids(bool_idx,1), pp2.centroids(bool_idx,2), 50*cos(current_angle + atan2((sin(deg2rad(45))*pp.dmean),eucl_d(idx).*cos(angle_error(idx)))), 50*sin(current_angle + atan2((sin(deg2rad(45))*pp.dmean),eucl_d(idx).*cos(angle_error(idx)))));
                %             hquivDN = quiver(pp2.centroids(bool_idx,1), pp2.centroids(bool_idx,2), 50*cos(current_angle - atan2((sin(deg2rad(45))*pp.dmean),eucl_d(idx).*cos(angle_error(idx)))), 50*sin(current_angle - atan2((sin(deg2rad(45))*pp.dmean),eucl_d(idx).*cos(angle_error(idx)))));
                done(good_idx) = true;
                rank_lookup(good_idx) = file_number;
                rank_idx_lookup(good_idx) = rank_idx;
                rank_idx = rank_idx+1;
                good_idx = idx;
                mean_dist(good_idx) = eucl_d(idx);
            end
            %     drawnow
            %     pause(0.01)
            %     delete([hquivUP hquivDN hquiv hs]);
            %     delete(hs)
        end
    end
    
    %%%%%%%%%%%%%%
    
    % keyboard
    
    if sum(rank_lookup)~=0

        for iii = 1:max(rank_lookup)
            rank_length(iii) = sum(rank_lookup == iii);
        end

        IfilesColor = zeros(size(obj.mask));%double(L>1);
        for pt_idx = 1:length(pp2.majors)
            if pp.kept_idx_cor(pt_idx)
                IfilesColor(cat(1,pp2.pixelIdxLists{pt_idx})) = rank_lookup(pt_idx);
            end
        end

        [sorted_rank_length,sorted_idx] = sort(rank_length,'descend');

        output.fileLookUp = rank_lookup;
        output.sortedFileLength = sorted_rank_length;
        output.fileLength = rank_length;
        output.sortedIdx = sorted_idx;
        output.lookUpIdx = rank_idx_lookup;
        output.IfilesColor = IfilesColor;
    else 
        output.fileLookUp = 0;
        output.sortedFileLength = 0;
        output.fileLength = 0;
        output.sortedIdx = 0;
        output.lookUpIdx = 0;
        output.IfilesColor = 0;
    end
    
    

else
    output = struct();
end
