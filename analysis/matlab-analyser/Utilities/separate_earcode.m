function [ code , num_ear ] = separate_earcode( ear_code )

% Separate code names : 
namesplit = strsplit(ear_code,'.');

% Unicode : 
if length(namesplit) == 1
    code = namesplit(1);
    num_ear = 1; 
elseif length(namesplit) ==2
    code = namesplit{1};
    ToCut = namesplit{end};
    cut = strsplit(char(ToCut),'U');
    num_ear = (str2num(char(cut(1)))-1)*3+str2num(char(cut(2)));

% If someone put a '.' in the codename ?
else
    code = strjoin(namesplit{1,end-1}) ; 
    ToCut = namesplit{end};
    cut = strsplit(char(ToCut),'U');
    num_ear = (str2num(char(cut(1)))-1)*3+str2num(char(cut(2)));
end

if iscell(code)
    code = code{1};
end
if iscell(num_ear)
    code = num_ear{1};
end



