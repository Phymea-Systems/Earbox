function [ status ] = ReadOrWriteOutputFile( EarTreatmentOutputs,EarList,Task )
%Reading and Writing the principal output file /
%   this functions reads and writes the global outputfile at the start and
%   end of a session / Maybe to a read and write function ? 
% File name is always GlobalOutputs and integrates all informations about
% the session.
% Matrix size is :
% rows = num ears *6
% cols = all flags + isMasked+isTreated+isColormask+isImaged+isPDFed
status = 'starting';
FullOutputFilePath = strcat(workspaceSession,'\Outputs','\GlobalOutputs.csv');

switch  Task
    
    case 'write'
        
        fileID = fopen(FullOutputFilePath,'wt') ;
        fprintf(fileID,'%s','Code');
        fprintf(fileID,';%s','Face','Ear Length','Ear max diameter','Fertile zone','Basal abortion','Apical abortion','Grains per rank','Number of ranks','Grain height','Grain diameter','Number of grains');
        fprintf(fileID,'\n');
        fprintf(fileID,'%s','-');
        fprintf(fileID,';%s','-','cm','cm','cm','cm','cm','grains','grains','cm','cm','grains');
        fprintf(fileID,'\n');
        
        status = 'written';
        return
        
        
        
        
    case 'read'
        
        
        
        status = 'read';
        return
        
        

end

end

