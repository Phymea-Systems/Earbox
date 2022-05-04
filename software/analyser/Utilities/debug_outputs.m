function [Debug,NewOutputs] = debug_outputs( workspaceImages , workspaceSession, Outputs, earsFacesDone, string)



% New outputs (potentially changed) are initialized to the outputs : 
NewOutputs = Outputs;


% For now all debug info after a session is done here. 
% To be checked maybe after ? 
% Which options to use : 
% 1 - Only Masking is done | 2 - Masking and treatment are done 
if strcmp(string,'MaskDone')
    
    ToDo = 1;
    
elseif strcmp(string,'AllDone')

    ToDo = 5;

else
    
    error('Please provide a correct string value (MaskDone / AllDone / X')

end


% First check images and codes from source :
fileList = dir(fullfile(workspaceImages, '*.jpeg'));
Debug.EarboxImages = struct();

if isempty(fileList)
    fprintf('No earbox images !\n');
    return
end

earList = cellstr(ls(fullfile(strcat(workspaceSession,'\data'))));
earList=earList(~ismember(earList,{'.','..'}));
% Check if we have masked anything : 
if isempty(earList)
    fprintf('No masked ears !\n');
    return
end

% Second check if we have the same number of data folders than the number of
% earFacesDone : 
if length(earsFacesDone) ~= length(earList)*6
    
    %     fprintf('Something changed in data folder, can''t debug and check outputs !\n');
    %     fprintf('Session wil be updated to its current status. \n');   
    DeletedEars = setdiff(EarsDone,earList);
    AddedEars = setdiff(earList,EarsDone);

    % For all added ears : (working even if empty)
    % We can add stuff at the end that will be processed :
    % !!!!!!!! This should actually never happen !!!!!!!!!!!! 
    for addedearnum = 1: length(AddedEars)
%         code = AddedEars    ;


    end

    % For all deleted ears : 
    for deletedearnum = 1 : length(DeletedEars)

        
    end

end


try

    
        
    for numcode = 1:length(fileList)

        FullName = fileList(numcode,1).name;
        OutputsStrSplit = strsplit(FullName,'_');
        Last = strsplit(OutputsStrSplit{end},'.');
        OutputsStrSplit(end) = Last(1);
        Debug.EarboxImages.ImageType(numcode) = OutputsStrSplit(1);
        Debug.EarboxImages.Codes{numcode} = strjoin(OutputsStrSplit(2:end),'_');

    end
    Debug.EarboxImages.Plots = unique(Debug.EarboxImages.Codes);


    if ToDo > 1 
        
        % Masked Ears : 
        Debug.MaskedEars = struct();
        Debug.MaskedEars.isFaceTreated = zeros(length(earList),6);
        Debug.MaskedEars.isTreatmentFinished = zeros(length(earList));
        for numcode = 1: length(earList)

            OutputsStrSplit = strsplit(earList{numcode},'_');
            Last = strsplit(OutputsStrSplit{end},'.');
            OutputsStrSplit(end) = Last(1);
            ToCalc = strsplit(Last{2},'U');
            NbOfEars = (str2double(ToCalc{1})-1)*3 + str2double(ToCalc{2});
            Debug.MaskedEars.NbOfEars(numcode) = NbOfEars;
            Debug.MaskedEars.Codes{numcode} = strjoin(OutputsStrSplit(1:end),'_');

            % Did the analysis work : 
            Debug.MaskedEars.isFaceTreated(numcode,1:6) = earsFacesDone((numcode-1)*6+1:(numcode-1)*6+6);
            Debug.MaskedEars.isTreatmentFinished(numcode) = sum(Debug.MaskedEars.isFaceTreated(numcode,1:6)) / 6 ; 

        end
        Debug.MaskedEars.Plots = unique(Debug.MaskedEars.Codes);
        Debug.MaskedEars.NotAnalysed = setdiff(Debug.MaskedEars.Plots,Debug.EarboxImages.Plots);

        % Will be removed when the bug will be dealt with : 
        Debug.MaskedEars.BadMasking = unique(Debug.MaskedEars.Codes(Debug.MaskedEars.NbOfEars>9)).';

    end
    
catch 
    
   fprintf('Problem while checking outputs !\n');

end

end


function [splitted_code,NbOfEars] = split_code(EarCodeAsFolder)

    OutputsStrSplit = strsplit(EarCodeAsFolder,'_');
    Last = strsplit(OutputsStrSplit{end},'.');
    OutputsStrSplit(end) = Last(1);
    ToCalc = strsplit(Last{2},'U');
    NbOfEars = (str2double(ToCalc{1})-1)*3 + str2double(ToCalc{2});
    splitted_code = strjoin(OutputsStrSplit(1:end),'_')

end


