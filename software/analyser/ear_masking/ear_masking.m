function ear_masking(handles,BDD_path,photodir)

% Reset the processing axes : 
guihandles = handles;

% Read config : 
readConfigFile(BDD_path);
gvars = getGlobalVars;
fprintf('%s\n',['Process saved in ' gvars.workdir]);
dpath = readDirectory(photodir);
gvars = updateGlobalVars(dpath);
fnames = ls([gvars.workdir '/image_lists']);

% Read image lists : 
fnames_cells = cellstr(fnames);
fnames=fnames_cells(~ismember(fnames_cells,{'.','..'}));

% Check existing earcodes for ears already masked :
if exist(fullfile(gvars.workdir, 'codelist'),'file')
    earsDone = fileread(fullfile(gvars.workdir, 'codelist'));
else
    fid = fopen(fullfile(gvars.workdir, 'codelist'),'w');
    fclose(fid);
    earsDone = fileread(fullfile(gvars.workdir, 'codelist'));
end

% Loop over ears for masking : 
for ii = 1:numel(fnames)
    
    % Separate code and assume 3 ears :
    [codes,nears] = separate_codes(strtrim(fnames{ii})); % filename parser
    
    % If already masked, continue to next ear :
    if ~isempty(earsDone)
        if strfind(earsDone,strjoin(codes(:),'\n'))
            continue
        end
    end
    
    % This one is in a try catch, skipping if not working for now :
    try 
        for iii = 1:numel(codes)
            for face = 1:6
                [~,~,messid] = mkdir(fullfile(gvars.workdir, 'data' ,codes{iii}, num2str(face)));
                % If rep already exists, new code / rep with a x1 ... 
                % Until infinity ! 
                if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
                    new_code = codes{iii};
                    new_code = new_code(1:end-1);
                    new_code = strcat(new_code,'x1');
                    codes{iii} = new_code;
                    mkdir(fullfile(gvars.workdir, 'data' ,new_code, num2str(face)));
                end
            end
        end
    catch 
       fprintf('Problem in image code %s, skipped.\n', fnames{ii});
    end
    
    
    % masking for all ear faces :
    badcodefound = false;
    for face = 1:6
        
        % Try masking :
        try
            if regexp(strtrim(fnames{ii}),'\d{1}U_*')
                [ROIs,positions,TLcorners,valid,nameatpos] = masknpos_ears(fullfile(gvars.dpath,['I' num2str(face) strtrim(fnames{ii}) '.jpeg']),codes,nears); % image masking
            else
                [ROIs,positions,TLcorners,valid,nameatpos] = masknpos_ears(fullfile(gvars.dpath,['I' num2str(face) 'xM_' strtrim(fnames{ii}) '.jpeg']),codes,nears); % image masking
            end
        catch
            fprintf('Problem with earmasking %s , skipped.\n', fnames{ii});
        end
        
        % Rewrite ear codes depending on positions and nears :
        nears = numel(positions);
        
        % Make folders for outputs :
        % We need to add a 'redo' ear option !
        for iii = 1:nears
            position = positions(iii);
            [~,~,messid] = mkdir(fullfile(gvars.workdir, 'data' ,codes{position}, num2str(face)));
            % If rep already exists, new code / rep with a x1 ...
            % Until infinity and beyond !
            if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
                new_code = codes{iii};
                new_code = new_code(1:end-1);
                new_code = strcat(new_code,'x1');
                codes{iii} = new_code;
                mkdir(fullfile(gvars.workdir, 'data' ,new_code, num2str(face)));
            end
        end
        
        % Write masked images in folders :
        % There is a redo between 'codes' and nameatpos !
        if all(valid)
            writeEarImages(strtrim(fnames{ii}),face,nameatpos,ROIs,positions,TLcorners);
        else
            badcodefound=true;
            break;
        end
                
    end
    
    if ~badcodefound
        fid = fopen(fullfile(gvars.workdir, 'codelist'),'a');
        fprintf(fid,'%s\n', codes{:});
        fclose(fid);
    end


end

% Update current process : 
current_process(handles,'Masking finished !')

end

