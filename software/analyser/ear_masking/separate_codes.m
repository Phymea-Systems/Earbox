function [codes,n] = separate_codes(filename)
% take an image name from mauguio tests and seperate ears codes 
% Normally there is a @ before each ear code (not the first one): 
if ~isempty(strfind(filename, '@'))
    
    namesplit_tmp= strsplit(filename,'@');
    
    if  regexp(namesplit_tmp{1},'\d{1}U')
        
        %assume there is 3 ears
        for kk = 1 : 3
            namesplit{kk} = strcat(strjoin(namesplit_tmp(2:end),'_'),'.',namesplit_tmp{1},num2str(kk));
        end
        
    else
        
        namesplit = namesplit_tmp;
        
    end

else
    
    namesplit = strsplit(filename,'_');
    
    if regexp(namesplit{1},'\d{1,2}_?\d{1,2}_?[W]{1}[DW]{1}')
        % MAUGUIO CODES
        k=1;
        namesplit_tmp = [];
        for kk = 1:7:length(namesplit);
            namesplit_tmp{k} = strjoin(namesplit(kk:kk+6),'_');
            k=k+1;
        end
        namesplit = namesplit_tmp;
    elseif regexp(namesplit{1},'Morph');
        k=1;
        namesplit_tmp = [];
        for kk = 1:5:length(namesplit);
            namesplit_tmp{k} = strjoin(namesplit(kk:kk+4),'_');
            k=k+1;
        end
        namesplit = namesplit_tmp;
    elseif regexp(namesplit{1},'(B[1-9]+E[1-9]{1,2})');
    elseif regexp(namesplit{1},'\d{1}U');
        %assume there is 3 ears
        for kk = 1:3
            namesplit_tmp{kk} = strcat(strjoin(namesplit(2:end),'_'),'.',namesplit{1},num2str(kk));
        end
        namesplit = namesplit_tmp;
    else
        namesplit = namesplit(1:end);% individual earcodes
    end
end


n = length(namesplit);
for c = 1:n
    codes(c,:) = namesplit(c);
end