function dpath = readDirectory(workdir,dpath)

    % prepare directory and write image lists : 

    fnames = [];
    fnames = ls(fullfile(dpath, 'I*.jpeg')); %list IR images names
    % (remember there's a regexp check inside ls function it's useful!)

    fnames_list = cellstr(fnames) ; 

    working_directory = workdir;
    if ~isdir(fullfile(working_directory,'image_lists'))
        mkdir(working_directory,'image_lists');
    else
        delete(fullfile(working_directory,'image_lists','*'));
    end
    
    for ii = 1:numel(fnames_list)-1
        current_name = fnames_list{ii};
        current_name = strsplit(current_name,'/');
        current_name = current_name{end};
        if isImageFileOK(current_name,dpath);
            fid = fopen(fullfile(working_directory,'/image_lists/', [current_name(6:end-5)]),'a');
            fprintf(fid,'%s\n',fullfile(dpath,current_name));
            fclose(fid);
        elseif current_name(4) == 'U'
            fid = fopen(fullfile(working_directory,'/image_lists/', [current_name(3:end-5)]),'a');
            fprintf(fid,'%s\n',fullfile(dpath,current_name));
            fclose(fid);
        end
    end
    
    
    

end

function bool = isImageFileOK(fname,dpath)
    % perform some checks on image files before processing them
    % wrong prefix
    if ~( (fname(1) == 'I') & all(fname(3:4) == 'xM') )
        bool = false;
        return
    end

    % can't find all the corresponding images (RGB and RGB+IR)
    for i = 1:6
        for letter = ['V' 'I']
            if ~exist(fullfile(dpath,[letter num2str(i) fname(3:end)]),'file')
                bool = false;
                return
            end
        end
    end
    
    bool = true;
    return

end