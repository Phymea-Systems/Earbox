function readConfigFile(BDD_path)
    try
        options = fileread('options.txt');
    catch
        error('phymea:readConfigFile','Can''t find option.txt file');
    end
    
    options = strsplit(options,'\n');
    options = options(1:end-1);
    
    optionNames = {};
    optionValues = [];
    for i = 1:numel(options)
        %remove spaces
        current_option = strsplit(options{i},' ');
        current_option = strcat(current_option{1:end});
        
        %get option name and value
        current_option = strsplit(current_option,'=');
        optionNames{i} = current_option{1};
        optionValues(i) = str2num(current_option{2});
    end
   
    % loop through options and initialize global variables accordingly
    gvars = getGlobalVars;
    for i = 1:numel(optionNames)
        % In case we use a temp directory : 
        if strcmp(optionNames{i},'UseTempDirectory')
                if (optionValues(i)==1)
                    workdir = createWorkingDirectory();
                else
                    workdir = 0;
                    workdir = fullfile(BDD_path);
                    if workdir == 0
                        error('No output directory selected');
                    end
                end
                updateGlobalVars(workdir);
        end
        % In case colormask is specified : 
        % Put it in global vars for the session
        % %aybe the the best idea ? 
    end
        
end
