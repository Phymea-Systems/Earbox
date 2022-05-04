function output = resizeProps(obj)

    pp = obj.segmentedImageProps;
    kept_idx = pp.kept_idx;
    test = find(obj.horizontalAxis==1);
    % Resizing image :
    dmean = computeAdjacencyGraph(pp);

    posy = size(obj.mask,1)/2;
    [~,posx] = ind2sub(size(obj.mask), test(end));
    posx = posx+50;

    dgrain = zeros(size(pp.majors));
    dgrain_bis = dgrain;

    % get rid of overly large elements
    if isempty(pp.areas)
        output = struct();
        return 
    end
    
    kept_idx((pp.boxHeights > pp.profile(ceil(pp.centroids(:,1)))') | (pp.boxWidths > pp.profile(ceil(pp.centroids(:,1)))') ) = false;
    xx = ceil(pp.centroids(:,1));
    yy = ceil(pp.centroids(:,2));
    for it = 1:length(kept_idx)
        if obj.upOrDownMap(yy(it),xx(it)) == 0
            kept_idx(it) = false;
        end
    end


    xcut = zeros(size(obj.mask));
    idx = ~isnan(pp.profile);
    xcut(:,~idx) = zeros(size(xcut(:,~idx)));
    xcut(:,1:11) = zeros(size(xcut(:,1:11) ));
    for it = 1:length(idx)
        if idx(it)
            xcut(:,it) = ones(size(xcut(:,it))) .* (pp.profile(it) > (max(pp.profile(idx))-2*std(pp.profile(~isnan(pp.profile)))));
        end
    end
    %?????????????

    pp.profile(~isnan(pp.profile)) - mean((pp.profile(~isnan(pp.profile)))) < -0.5*std(pp.profile(~isnan(pp.profile)));

    % Correction des diametres equivalents et des positions des centroids
    centroids_cor = zeros(length(pp.majors),2);
    for it = 1:length(pp.majors)
        if kept_idx(it)
            xx = ceil(pp.centroids(it,1));
            yy = ceil(pp.centroids(it,2));
            a1 = 0.5.*pp.majors(it);
            b1 = a1.*sqrt(1-pp.eccents(it).^2);
            if (xx-10) < 0
                keyboard
            end
            if obj.upOrDownMap(yy,xx) == 1
                angle_up = pi/2 - atan2( (find(obj.horizontalAxis(:,xx+10),1,'first') - find(obj.horizontalAxis(:,xx-10),1,'first')),20);
                angle_axe = atan2( (find(obj.horizontalAxis(:,xx+10),1,'first') - find(obj.horizontalAxis(:,xx-10),1,'first')),20);
                dir_vect = [cos(angle_axe+pi/2) -sin(angle_axe+pi/2)];
                thetaY = pp.orients(it) - angle_up;

            elseif obj.upOrDownMap(yy,xx) == -1
                angle_down = pi/2 + atan2( (find(obj.horizontalAxis(:,xx+10),1,'first') - find(obj.horizontalAxis(:,xx-10),1,'first')),20);
                angle_axe = atan2( (find(obj.horizontalAxis(:,xx+10),1,'first') - find(obj.horizontalAxis(:,xx-10),1,'first')),20);
                dir_vect = [cos(angle_axe-pi/2) -sin(angle_axe-pi/2)];
                thetaY = pp.orients(it) - angle_down;

            else
                disp('outofbound');
                keyboard
            end


            if numel(dir_vect) == 0
                dir_vect = [cos(obj.upOrDownMap(yy,xx)*pi/2) -sin(obj.upOrDownMap(yy,xx)*pi/2)];
            end
            coscentre = obj.dist2AxisMap(yy,xx) / pp.profile(xx);
            coshigh = (obj.dist2AxisMap(yy,xx) + pp.equivDiams(it)/2) / pp.profile(xx);
            if coshigh > 1; coshigh=1; end
            coslow = (obj.dist2AxisMap(yy,xx) - pp.equivDiams(it)/2) / pp.profile(xx);
            sinhigh = sqrt(1 - coshigh^2);
            sinlow = sqrt(1 - coslow^2);

            costotal = (obj.dist2AxisMap(yy,xx) - pp.equivDiams(it)/2) / pp.profile(xx);%%% BOX
            if coscentre > 1; coscentre=1; end
            if costotal > 1; costotal=1; end
            if coscentre < 0; coscentre=0; end
            correct_norm = (pi/2 - acos(coscentre))*pp.profile(xx);
            centroids_cor(it,2) = pp.centroids(it,2) + (correct_norm - obj.dist2AxisMap(yy,xx)) * dir_vect(2);
            centroids_cor(it,1) = pp.centroids(it,1) - (correct_norm - obj.dist2AxisMap(yy,xx)) * dir_vect(1);
            theta = mod(acos(costotal) - acos(coscentre),pi);
            dgrain(it) = 2*pp.profile(xx)*sin(theta);
            dgrain_bis(it) = sqrt((pp.profile(xx) * (sinhigh-sinlow))^2 + (pp.profile(xx) * (coshigh-coslow))^2);
            if coscentre > 0.866
                kept_idx(it) = false;
            end
            %         end
        end
    end
    ratio = dgrain_bis./pp.equivDiams;


    %%% Elliptic correction : 
    toto = bwlabel(obj.refinedSegmentation);

    t = linspace(0,2*pi);
    major_cor = zeros(size(pp.majors));
    minor_cor = major_cor;
    orient_cor = major_cor;
    eccent_cor = major_cor;
    for i = 1:length(pp.majors)
        if kept_idx(i)
            a = 0.5.*pp.majors(i);
            b = a.*sqrt(1-pp.eccents(i).^2);
            w = pp.orients(i);
            %scale and project
            spa = [a*cos(w) ratio(i)*a*sin(w)];
            spr = [-b*sin(w) ratio(i)*b*cos(w)];
            theta =  atan2(spa(2),spa(1));
            theta2 = atan2(spr(2),spr(1)) - theta;
            if norm(spr) > norm(spa)
                tmp = spa;
                spa = spr;
                spr = tmp;
                theta = atan2(spr(2),spr(1));
                theta2 = atan2(spa(2),spa(1)) + pi - theta;
                if theta > pi/2
                    theta = pi-theta;
                    theta2 = atan2(spa(2),spa(1)) - theta;
                end
            end

            spb = sqrt( (sin(theta2)^2) / ( (1/norm(spr)^2) - ( cos(theta2)^2 / norm(spa)^2 ) ) );

            X = norm(spa).*cos(t);
            Y = spb.*sin(t);

            x = centroids_cor(i,1) - X*cos(theta) + Y*sin(theta);
            y = centroids_cor(i,2) + X*sin(theta) + Y*cos(theta);
    %         plot(x,y,'b-','LineWidth',2);

            major_cor(i) = norm(spa);
            minor_cor(i) = spb;
            orient_cor(i) = theta;
            eccent_cor(i) = sqrt(norm(spa)^2 - spb^2) / norm(spa);
        end
    %     drawnow
        %     figure(1)
    end
    for i = 1:length(pp.majors)
        if kept_idx(i)
            if abs(major_cor(i)-mean(major_cor(kept_idx))) > 2*std(major_cor(kept_idx)) || abs(minor_cor(i)-mean(minor_cor(kept_idx))) > 2*std(minor_cor(kept_idx))
                %             kept_idx(i) = false;
                %         scatter(pp.centroids(i,1),centroids_cor(i,2),20,'r','filled');
            end
        end
    end


    output.majors_cor = major_cor;
    output.minors_cor = minor_cor;
    output.centroids_cor = centroids_cor;
    output.orients_cor = orient_cor;
    output.eccents_cor = eccent_cor;
    output.kept_idx_cor = kept_idx;
    output.ratio_wtf = ratio;
    output.dgrain_wtf = dgrain;
    output.dgrain_bis_wtf = dgrain_bis;
    output.dmean = dmean;
    
    ss = regionprops(obj.refinedSegmentation,'BoundingBox');
    bbox = cat(1,ss.BoundingBox);
    output.bboxY_cor = bbox(:,4) .* ratio;
    output.bboxX_cor = bbox(:,3);
    


end
   


function dmean = computeAdjacencyGraph(pp)
    %%%%%%%%%%%%%% compute adjacency graph %%%%%%%%%%%%%%%%%%%%%%%%
    comp_val = zeros(length(pp.majors));
    voisins =  false(length(pp.majors));
    angles = NaN(length(pp.majors));
    list_voisins = cell(length(pp.majors),1);
    hline = zeros(length(pp.majors));
    dmean = 0;
    rgrainX = zeros(length(pp.majors),1);
    % r_Y = zeros(length(pp.majors),1);
    timeout = tic;
    for i=1:length(pp.majors)
        for j=1:length(pp.majors)
            if i~=j
                d_ij2 = (pp.centroids(i,1)-pp.centroids(j,1))^2 + (pp.centroids(i,2) - pp.centroids(j,2))^2;

                direct_angle = atan2(pp.centroids(j,2)-pp.centroids(i,2),pp.centroids(j,1)-pp.centroids(i,1));
                %             ortho_angle = atan2((pp.centroids(i,2)-10)-pp.centroids(i,2),pp.centroids(i,1)-pp.centroids(i,1));
                a1 = 0.5.*pp.majors(i);
                b1 = a1.*sqrt(1-pp.eccents(i).^2);
                a2 = 0.5.*pp.majors(j);
                b2 = a2.*sqrt(1-pp.eccents(j).^2);
                theta1 = pp.orients(i)+direct_angle;
                theta2 = pp.orients(j)+direct_angle;
                %             thetaortho = pp.orients(i)+ortho_angle;
                r_ellipse1 = 1/sqrt((cos(theta1)/a1)^2 + (sin(theta1)/b1)^2 );
                r_ellipse2 = 1/sqrt((cos(theta2)/a2)^2 + (sin(theta2)/b2)^2 );

                %             rgrainX(i) = 1/sqrt((cos(thetaortho)/a1)^2 + (sin(thetaortho)/b1)^2 );
                %             rgrainX(i) = (pp.centroids(i,2) + a1*sin(pp.orients(i))) - (pp.centroids(i,2) - a1*sin(pp.orients(i)));
                d_sumr = r_ellipse1 + r_ellipse2;
                comp_val(i,j) = abs(sqrt(d_ij2)-d_sumr);
                if comp_val(i,j) < 12
                    %                 hline(i,j) = line([pp.centroids(i,1) pp.centroids(j,1)],[pp.centroids(i,2) pp.centroids(j,2)]);
                    voisins(i,j) = true;
                    angles(i,j) = theta1-pp.orients(i);
                    if d_ij2 ~= 0
                        dmean = dmean + sqrt(d_ij2);
                    end

                end
                %   comp_val(i,j)


                %   delete(hline);
            end
        end
        list_voisins{i} = find(voisins(i,:));
        if toc(timeout) > 200
            error('timeout');
        end
    end
    dmean = dmean/sum(sum(voisins));


end