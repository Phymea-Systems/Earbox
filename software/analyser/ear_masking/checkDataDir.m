function [isValid,badindex] = checkDataDir(dpath)
    
    dpath = fullfile(dpath,'data');
    isValid = true;
    badindex = [];
    info = dir(dpath);
    info(1:2) = [];
    
    for i=1:numel(info)
        if info(i).isdir
            subfolder = dir(fullfile(dpath,info(i).name));
            subfolder(1:2) = [];
            if numel(subfolder)~=6
                isValid = false;
                badindex(end+1) = i;
            else
                for ii = 1:6
                    subsubfolder = dir(fullfile(dpath,info(i).name,subfolder(ii).name));
                    subsubfolder(1:2) = [];
                    if sum(cat(1,subsubfolder.bytes)) < 50000
                        isValid = false;
                        badindex(end+1) = i;
                    end
                end
            end
        end
    end
end
