% ------------------------------------------------------------

% Begin initialisation - DO NOT EDIT

function varargout = main(varargin)
% MAIN MATLAB code for main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help main
% Last Modified by GUIDE v2.5 27-Sep-2019 13:17:11
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
               
% Remplacer par un handle PATH :
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% end initialisation- DO NOT EDIT

% ------------------------------------------------------------
% ------------------------------------------------------------

% Begin functions :

% Function to open a dialog box with a button 'ok'
% To remove later : 
function mydialog(Name,String)

d = dialog('Position',[300 300 250 150],'Name',Name');
txt = uicontrol('Parent',d,'Style','text','Position',[20 80 210 40],'String',String);
btn = uicontrol('Parent',d,'Position',[85 20 70 25],'String','Close','Callback','delete(gcf)');

waitfor(d)

% Functions to handle outputpath : 
function OutputPath = define_output_path(handles)

% Set path : 
if ~handles.IsSetOutputPath
    Path = fullfile(handles.SessionPath,'outputs');
    Path = uigetdir(Path,'Ou sauver les fichiers de sortie ?');
    if Path~= 0
        OutputPath = fullfile(Path);
    else
        OutputPath = 'none' ; 
    end
else 
    OutputPath = handles.OutputPath;
end

% Functions to process ears : 
function [FaceEarOutputs,outputs] = process_ear(dpath,code,face,flags,UseColorMask,UseTempFolder,Graph,Segmentation,Calibration)

% Reset warnings : 
warning('');

% Check if needs to reload old outputs or redo : 
FileToSearch = strcat('FaceEarOutputs_',Segmentation,'_',num2str(UseColorMask),'.mat');

PathToCheck = fullfile(dpath, code,num2str(face),FileToSearch);
obj = FaceEarClass(dpath, code,face,UseColorMask,Segmentation,UseTempFolder);

% Get calibration info to calculate PX2CM properly : 
obj.max_PX2CM = Calibration.MaxValue;
obj.min_PX2CM = Calibration.MinValue;

if exist(PathToCheck,'file') == 2
    load(PathToCheck)
else
    
    % Stock outputs : 
    FaceEarOutputs = struct();
    FaceEarOutputs.EarSize.Diam = struct();
    FaceEarOutputs.EarSize.Length = struct();
    FaceEarOutputs.EarSize.Abortion = struct();
    FaceEarOutputs.EarOrganisation.Ranks = struct();
    FaceEarOutputs.GrainsAttributes.ringDimensions = struct();
    FaceEarOutputs.GrainsAttributes.NbGr = [];
    FaceEarOutputs.UseColorMask = UseColorMask ;
    FaceEarOutputs.dpath = dpath ;
    FaceEarOutputs.code = code ;
    FaceEarOutputs.face = face ;
    FaceEarOutputs.toCalculate = [1 1 1 1 1 1 1 1];
    FaceEarOutputs.Warning = '';
    
    % For Visualisation : 
    outputs = zeros(1,length(flags));
    FaceEarOutputs.Visual = struct();
    FaceEarOutputs.Visual.Mask = obj.mask;
    FaceEarOutputs.Visual.RGBImage = obj.RGBImage;
    FaceEarOutputs.PX2CM = obj.PX2CM;
%     return 

end

PreCalc = sum(FaceEarOutputs.toCalculate);
% L / l / Lfer / Abase / Aapi / NbR / NbGpr / Grain dim [2] / Nb Grain            
outputs = zeros(1,length(flags));

if flags(1) || any(Graph)
    try
        if FaceEarOutputs.toCalculate(1)
            FaceEarOutputs.EarSize.Length.Pxl = obj.horzAxisLength;
            FaceEarOutputs.EarSize.Length.PX2CM = obj.PX2CM;
            FaceEarOutputs.EarSize.Length.Cm = round(FaceEarOutputs.EarSize.Length.Pxl*FaceEarOutputs.EarSize.Length.PX2CM,2);
            FaceEarOutputs.EarSize.EarBasePxL = find(sum(obj.mask),1,'first');
            FaceEarOutputs.EarSize.EarApexPxL = find(sum(obj.mask),1,'last');
            FaceEarOutputs.toCalculate(1) = 0;
            
        end
        outputs(1) = FaceEarOutputs.EarSize.Length.Cm;
    catch
        outputs(1) = NaN;
    end
end

if flags(2) || any(Graph)
    try
        if FaceEarOutputs.toCalculate(2)
            FaceEarOutputs.EarSize.Diam.Pxl = obj.earMaxDiameter;
            FaceEarOutputs.EarSize.Diam.PX2CM = obj.PX2CM;
            FaceEarOutputs.EarSize.Diam.Cm = round(FaceEarOutputs.EarSize.Diam.Pxl*FaceEarOutputs.EarSize.Diam.PX2CM,2);
            FaceEarOutputs.EarSize.Diam.RadiusProfile =  obj.earRadiusProfile ;
            FaceEarOutputs.EarSize.EarBasePxL = find(sum(obj.mask),1,'first');
            FaceEarOutputs.EarSize.EarApexPxL = find(sum(obj.mask),1,'last');
            FaceEarOutputs.toCalculate(2) = 0;
        end
        outputs(2) = FaceEarOutputs.EarSize.Diam.Cm ;
    catch
        outputs(2) = NaN ;
    end
end

%% Pass there only if fertile zone : 
if flags(6) || any(Graph)
    try
        if FaceEarOutputs.toCalculate(4)
            FaceEarOutputs.EarOrganisation.GPRank.gpr = round(gpr(obj),1);
            % Get the mean value of this : 
            FaceEarOutputs.EarOrganisation.GPRank.gprmean = round(gprmean(obj),1);
            FaceEarOutputs.EarOrganisation.GPRank.position = enumerateRingPosition(obj);
            FaceEarOutputs.toCalculate(4) = 0;
        end
        outputs(6) = round(FaceEarOutputs.EarOrganisation.GPRank.gpr,1);
    catch
        outputs(6)=NaN;
    end
end

if flags(7) || flags(8) || flags(9) || any(Graph)
    try
        if FaceEarOutputs.toCalculate(5)
            
            FaceEarOutputs.EarOrganisation.Ranks.Bot_ = obj.RanksCount.Bot_;
            FaceEarOutputs.EarOrganisation.Ranks.Mid_ = obj.RanksCount.Mid_;
            FaceEarOutputs.EarOrganisation.Ranks.Top_ = obj.RanksCount.Top_;
            
            FaceEarOutputs.EarOrganisation.Ranks.Bot = obj.RanksCount.Bot;
            FaceEarOutputs.EarOrganisation.Ranks.Mid = obj.RanksCount.Mid;
            FaceEarOutputs.EarOrganisation.Ranks.Top = obj.RanksCount.Top;
            
            FaceEarOutputs.EarOrganisation.DebugRanks = obj.RanksCount;
            FaceEarOutputs.toCalculate(5) = 0;
        end
        outputs(7)=round(FaceEarOutputs.EarOrganisation.Ranks.Bot_,1);
        outputs(8)=round(FaceEarOutputs.EarOrganisation.Ranks.Mid_,1);
        outputs(9)=round(FaceEarOutputs.EarOrganisation.Ranks.Top_,1);
    catch
        outputs(7)=NaN;
        outputs(8)=NaN;
        outputs(9)=NaN;
    end 
end

if (flags(10) || flags(11)) || any(Graph)
    try
        
        if FaceEarOutputs.toCalculate(6)
            FaceEarOutputs.GrainsAttributes.ringDimensions = obj.GrainsAttributes.ringDimensions ;
          
            FaceEarOutputs.GrainsAttributes.ringDimensions.Ydim_cm = FaceEarOutputs.GrainsAttributes.ringDimensions.Ydim * obj.PX2CM;
            FaceEarOutputs.GrainsAttributes.ringDimensions.sd_Ydim_cm = FaceEarOutputs.GrainsAttributes.ringDimensions.sd_Ydim * obj.PX2CM;
            FaceEarOutputs.GrainsAttributes.ringDimensions.Xdim_cm = FaceEarOutputs.GrainsAttributes.ringDimensions.Xdim * obj.PX2CM;
            FaceEarOutputs.GrainsAttributes.ringDimensions.sd_Xim_cm = FaceEarOutputs.GrainsAttributes.ringDimensions.sd_Xdim * obj.PX2CM;            
            FaceEarOutputs.GrainsAttributes.ringDimensions.position_x_cm = FaceEarOutputs.GrainsAttributes.ringDimensions.position_x * obj.PX2CM;
            FaceEarOutputs.GrainsAttributes.ringDimensions.sd_position_x_cm = FaceEarOutputs.GrainsAttributes.ringDimensions.sd_position_x * obj.PX2CM;            
            FaceEarOutputs.GrainsAttributes.ringDimensions.area_cm2 = FaceEarOutputs.GrainsAttributes.ringDimensions.area * obj.PX2CM  * obj.PX2CM;
            FaceEarOutputs.GrainsAttributes.ringDimensions.sd_area_cm2 = FaceEarOutputs.GrainsAttributes.ringDimensions.sd_area * obj.PX2CM  * obj.PX2CM;            
            FaceEarOutputs.GrainsAttributes.ringDimensions.profile_cm = FaceEarOutputs.GrainsAttributes.ringDimensions.profile * obj.PX2CM;            
            
            FaceEarOutputs.toCalculate(6) = 0;
        end
        
        if ~isempty(FaceEarOutputs.GrainsAttributes.ringDimensions) && isfield(FaceEarOutputs.GrainsAttributes.ringDimensions,'Ydim') && isfield(FaceEarOutputs.GrainsAttributes.ringDimensions,'Xdim')
            
            FaceEarOutputs.GrainsAttributes.ringDimensions.Ydim_mean = nanmean(FaceEarOutputs.GrainsAttributes.ringDimensions.Ydim);
            FaceEarOutputs.GrainsAttributes.ringDimensions.Xdim_mean = nanmean(FaceEarOutputs.GrainsAttributes.ringDimensions.Xdim);
            
            FaceEarOutputs.GrainsAttributes.ringDimensions.G_l = min(round(FaceEarOutputs.GrainsAttributes.ringDimensions.Ydim_mean,1),...
                round(FaceEarOutputs.GrainsAttributes.ringDimensions.Xdim_mean,1));
            
            FaceEarOutputs.GrainsAttributes.ringDimensions.G_L = max(round(FaceEarOutputs.GrainsAttributes.ringDimensions.Ydim_mean,1),...
                round(FaceEarOutputs.GrainsAttributes.ringDimensions.Xdim_mean,1));
            
            FaceEarOutputs.GrainsAttributes.ringDimensions.PX2CM = obj.PX2CM ;
            FaceEarOutputs.GrainsAttributes.ringDimensions.Levels = FaceEarOutputs.GrainsAttributes.ringDimensions.GrainPosition.Level ;
            
            Grainpositions = FaceEarOutputs.GrainsAttributes.ringDimensions.Grain.PositionAlongEar;
            Grainpositions_FromBaseImage = length(FaceEarOutputs.Visual.Mask)-Grainpositions;
            Grainpositions_FromBaseEar = Grainpositions_FromBaseImage - FaceEarOutputs.EarSize.EarBasePxL;
            GP_Cm = Grainpositions_FromBaseEar*FaceEarOutputs.EarSize.Length.PX2CM;
            FaceEarOutputs.GrainsAttributes.ringDimensions.GP_Cm = GP_Cm;
            
            if flags(10)
                outputs(10)=round(FaceEarOutputs.GrainsAttributes.ringDimensions.G_l*FaceEarOutputs.GrainsAttributes.ringDimensions.PX2CM,2);
            end
            
            if flags(11)
                outputs(11)=round(FaceEarOutputs.GrainsAttributes.ringDimensions.G_L*FaceEarOutputs.GrainsAttributes.ringDimensions.PX2CM,2);
            end
            
        else
            
            outputs(10) = NaN;
            outputs(11) = NaN;
            warning('probably no fertile kernels');
            
        end
    catch
        outputs(10)=NaN;
        outputs(11)=NaN;
    end


end
        
if flags(12) || any(Graph)
    try
        if FaceEarOutputs.toCalculate(7)
            FaceEarOutputs.GrainsAttributes.NbGr = obj.GrainsAttributes.NbGr ;
            FaceEarOutputs.toCalculate(7) = 0;
        end
        outputs(12)=round(FaceEarOutputs.GrainsAttributes.NbGr,0);
    catch
        outputs(12)=NaN;
    end
end

if any(Graph) || any(flags(3:9))
    try
        if FaceEarOutputs.toCalculate(8)
            FaceEarOutputs.Visual.RefinedSegmentation = obj.refinedSegmentation ;
            if ~isempty(FaceEarOutputs.GrainsAttributes.ringDimensions)
                FaceEarOutputs.Visual.VerticalDetection = obj.verticalFileDetection.IfilesColor;
            else
                FaceEarOutputs.Visual.VerticalDetection = [];
            end
            
            FaceEarOutputs.toCalculate(8) = 0;
        end
    catch
        FaceEarOutputs.Visual.VerticalDetection = [];
    end
    
end

if (flags(3) || flags(4) || flags(5) ) || any(Graph)
    
    try
        %% Calculate zones (check parameters):
        if FaceEarOutputs.toCalculate(3)
            FaceEarOutputs.EarSize.Abortion  = obj.ZoneMasks ;
            FaceEarOutputs.toCalculate(3) = 0;
            FaceEarOutputs.EarSize.Abortion.PX2CM  = obj.PX2CM ;
        end
        
        if flags(3)
            outputs(3) = max(0,round(FaceEarOutputs.EarSize.Abortion.FertileZone*FaceEarOutputs.EarSize.Abortion.PX2CM,2));
        end
        
        if flags(4)
            outputs(4) = max(0,round(FaceEarOutputs.EarSize.Abortion.BasalAbortion*FaceEarOutputs.EarSize.Abortion.PX2CM,2));
        end
        
        if flags(5)
            outputs(5) = max(0,round(FaceEarOutputs.EarSize.Abortion.ApexAbortion*FaceEarOutputs.EarSize.Abortion.PX2CM,2));
        end
    catch
        outputs(3)=NaN;
        outputs(4)=NaN;
        outputs(5)=NaN;
    end
    
end


% Catch any warning : 
[Msg , ~] = lastwarn;
if ~isempty(Msg)
    FaceEarOutputs.Warning = Msg;
end

PostCalc = sum(FaceEarOutputs.toCalculate);

% UseTempFolder = 1; 

% Populate tempfolder :
if UseTempFolder
    
    try
%         PathToCheck = fullfile(dpath, code,num2str(face),'tmp','finalSeg.png') ;
%         if exist(PathToCheck,'file') == 2
%             
%         else
            warning('off', 'Images:initSize:adjustingMag');
            populateTempFolder(obj);
%         end
        
    catch
        
    end
    
end

    
    
% Save if something has been calculated (not sure if ll the time or just when calculated : 
if (PostCalc < PreCalc)
    writepath = fullfile(obj.dirpath,obj.code,num2str(obj.numero_face));
    save(fullfile(writepath,FileToSearch),'FaceEarOutputs');
end

function [FaceEarOutputs,outputs,CurrentInstance] = EarNormalComputing(BDD_path,handles,code,face,UseTempFolder,UseColorMask,ProduceGraphs,Calibration)


% SoftwareVersion :
SoftwareVersion = [handles.CurrentSession.SoftWareVersion ' (' handles.CurrentSession.Commit ')'];
% Find ear num and get output for this one :
earnum = find(ismember(handles.EarList, code));
k = ((earnum-1)*6+face);

%1/ Define seg : 
Version_Seg = get(handles.Segmentation_Version,'String');
if strcmp(Version_Seg,'v1.0 - Empiric Segmentation')
    Segmentation = 'New';
else
    Segmentation = 'New';
end

%2/ Define graph & check flags, if todo, do all handles : 
if any(ProduceGraphs) || sum(handles.checkbox_flags)==12
   Graph = 1 ; 
   flags = ones(1,12);
else
   Graph = 0 ; 
   flags = handles.checkbox_flags;
end

%3/ Process ear :
try 
    [FaceEarOutputs,outputs] = process_ear(fullfile(BDD_path),code{1},face,flags,UseColorMask,UseTempFolder,Graph,Segmentation,Calibration);
    gprvalue = outputs(6);
catch 
    CurrentInstance = 'Problem in ear processing';
    handles.CurrentAuditLog.trace(['Processing ear' ' ' code{1}],CurrentInstance); 
    return
end

%4/ Populate temp folder :
if UseTempFolder==1
    
    try
        populateTempFolder(obj)
    catch
        CurrentInstance = 'Problem in populating temp folder';
        handles.CurrentAuditLog.trace(['Processing ear' ' ' code{1}],CurrentInstance); 
        return
    end
end

% What do we search for : 
FileToSearch = strcat('FaceEarOutputs_',Segmentation,'_',num2str(UseColorMask),'.mat');


% Process graphs : 
if any(ProduceGraphs)
    
    try
        
        % Reload outputs (to avoid passing obj to function :
        PathToCheck = fullfile(fullfile(BDD_path), code,num2str(face),FileToSearch) ;
        if exist(PathToCheck{1},'file') == 2
            load(PathToCheck{1})
        end

        % Create figures : 
        if ProduceGraphs(1)

            if exist(fullfile(strcat(BDD_path,'\',code{1},'\',num2str(face),'\EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg')),'file') ~= 2
                
                %%
                
                showAndSaveResultsImage(FaceEarOutputs,gprvalue,40,1400,'off','on','on',Segmentation,UseColorMask,SoftwareVersion); % Max 40 cm at 1400 pixels
                handles.CurrentAuditLog.trace(['Producing graphs for ear' ' ' code{1} ' ' 'EarMask = On' ],'Success');
                
            end
            
        end
        
        if ProduceGraphs(2)
            
            if exist(fullfile(strcat(BDD_path,'\',code{1},'\',num2str(face),'\EarMeasurements_EarMaskoff_',Segmentation,'_',num2str(UseColorMask),'.jpeg')),'file') ~= 2
                
                %%
                
                showAndSaveResultsImage(FaceEarOutputs,gprvalue,40,1400,'off','on','off',Segmentation,UseColorMask,SoftwareVersion); % Max 40 cm at 1400 pixels
                handles.CurrentAuditLog.trace(['Producing graphs for ear' ' ' code{1} ' ' 'EarMask = off' ],'Success');
                
            end
        end
        
    catch 
        CurrentInstance = 'Problem in saving image outputs';
        handles.CurrentAuditLog.trace(['Processing ear' ' ' code{1}],CurrentInstance); 
        return
    end
end

% Ear Done : 
handles.earsFacesDone(k,handles.SegmentationVersion,handles.CurrentColorMask)=1 ;

CurrentInstance = 'Success';
handles.CurrentAuditLog.trace(['Retrieving data for ear' ' ' code{1}],CurrentInstance); 
 
function [FaceEarOutputs,outputs,ValidEar] = EarComputing(BDD_path,EarList,Segmentation,CurrentColorMask,checkbox_flags,code,UseTempFolder,UseColorMask,ProduceGraphs,Computing,SoftwareVersion,Calibration)

outputs = zeros(6,12);
FaceEarOutputs = cell(6,1);
ValidEar=zeros(6,1);

if strcmp(Computing,'parallel')
    
    %% parallel processing starts here :
    parfor face = 1:6
        
        
        LogName = strcat(strrep(strrep(code,'-','_'),'.','_'),'_',num2str(face));
        Logpath = fullfile(BDD_path,'logs',strcat(LogName,'.log'));
        EarAuditLog = logging.getLogger(LogName,'path',Logpath);
        EarAuditLog.setLogLevel(logging.logging.TRACE);
        EarAuditLog.trace(['Ear masking process from ' code ' Success '])
        try
            % update axes image & Check if RGB exists !
            RepToGoTo = fullfile(BDD_path,'data',code,num2str(face),'RGB.png') ;
            if exist(RepToGoTo,'file')
                ValidEar(face,:) = 1;
                EarAuditLog.trace('Ear checking Success');
            end
        catch
            ValidEar(face,:) = 0;
            EarAuditLog.trace('Ear checking Fail');
        end
        
        if ValidEar(face,:)==1
            
            %3/ Process ear :
            try
                [structure ,measurements] = process_ear(fullfile(BDD_path,'data'),code,face,checkbox_flags,UseColorMask,UseTempFolder,ProduceGraphs,Segmentation,Calibration);
                FaceEarOutputs{face,:} = structure;
                grpvalue = measurements(6);
                outputs(face,:)= measurements;
                EarAuditLog.trace('Ear processing Success');
            catch
                EarAuditLog.trace('Ear processing Fail');
                ValidEar(face,:) = 0;
            end
            
%             %4/ Populate temp folder :
%             if UseTempFolder==1
%                 
%                 try
%                     populateTempFolder(obj)
%                     EarAuditLog.trace('Populating temp folder Success');
%                 catch
%                     EarAuditLog.trace('Populating temp folder Fail');
%                 end
%             end
            
            % What do we search for :
            FileToSearch = strcat('FaceEarOutputs_',Segmentation,'_',num2str(UseColorMask),'.mat');
            
            
            % Process graphs :
            if any(ProduceGraphs)
                
                try
                    
                    % Reload outputs (to avoid passing obj to function :
                    PathToCheck = fullfile(fullfile(BDD_path), code,num2str(face),FileToSearch) ;
                    if exist(PathToCheck,'file') == 2
                        FaceEarOutputs{face,:} = load(PathToCheck);
                    end
                    
                    % Create figures :
                    if ProduceGraphs(1)
                        
                        if exist(fullfile(strcat(BDD_path,'\data\',code,'\',num2str(face),'\EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg')),'file') ~= 2
                            
                            showAndSaveResultsImage(FaceEarOutputs{face,:},grpvalue,40,1400,'off','on','on',Segmentation,UseColorMask,SoftwareVersion); % Max 40 cm at 1400 pixels
                            EarAuditLog.trace('Saving image output Success');
                            
                        end
                        
                    end
                    
                    if ProduceGraphs(2)
                        
                        if exist(fullfile(strcat(BDD_path,'\data\',code,'\',num2str(face),'\EarMeasurements_EarMaskoff_',Segmentation,'_',num2str(UseColorMask),'.jpeg')),'file') ~= 2
                            
                            showAndSaveResultsImage(FaceEarOutputs{face,:},grpvalue,40,1400,'off','on','off',Segmentation,UseColorMask,SoftwareVersion); % Max 40 cm at 1400 pixels
                            
                        end
                    end
                    
                catch
                    EarAuditLog.trace('Saving image output Fail');
                end
            end
            
        end
        
        logging.clearLogger(LogName);
        
    end
    
else
    
    %% normal processing starts here :    
    for face = 1:6
        
        
        LogName = strcat(strrep(strrep(code,'-','_'),'.','_'),'_',num2str(face));
        Logpath = fullfile(BDD_path,'logs',strcat(LogName,'.log'));
        EarAuditLog = logging.getLogger(LogName,'path',Logpath);
        EarAuditLog.setLogLevel(logging.logging.TRACE);
        EarAuditLog.trace(['Ear masking process from ' code ' Success '])
        try
            % update axes image & Check if RGB exists !
            RepToGoTo = fullfile(BDD_path,'data',code,num2str(face),'RGB.png') ;
            if exist(RepToGoTo,'file')
                ValidEar(face,:) = 1;
                EarAuditLog.trace('Ear checking Success');
            end
        catch
            ValidEar(face,:) = 0;
            EarAuditLog.trace('Ear checking Fail');
        end
        
        if ValidEar(face,:)==1
            
            %3/ Process ear :
            try
                [structure ,outputs(face,:)] = process_ear(fullfile(BDD_path,'data'),code,face,checkbox_flags,UseColorMask,UseTempFolder,ProduceGraphs,Segmentation,Calibration);
                FaceEarOutputs{face,:} = structure;
                gprvalue = outputs(face,6);
                EarAuditLog.trace('Ear processing Success');
            catch
                EarAuditLog.trace('Ear processing Fail');
                ValidEar(face,:) = 0;
            end
            
%             %4/ Populate temp folder :
%             if UseTempFolder==1
%                 
%                 try
%                     populateTempFolder(obj)
%                     EarAuditLog.trace('Populating temp folder Success');
%                 catch
%                     EarAuditLog.trace('Populating temp folder Fail');
%                 end
%             end
%             
            % What do we search for :
            FileToSearch = strcat('FaceEarOutputs_',Segmentation,'_',num2str(UseColorMask),'.mat');
            
            
            % Process graphs :
            if any(ProduceGraphs)
                
                try
                    
                    % Reload outputs (to avoid passing obj to function :
                    PathToCheck = fullfile(fullfile(BDD_path),'data',code,num2str(face),FileToSearch) ;
                    if exist(PathToCheck,'file') == 2
                        FaceEarOutputs{face,:} = load(PathToCheck);
                    end
                    
                    % Create figures :
                    if ProduceGraphs(1)
                        
                        if exist(fullfile(strcat(BDD_path,'\data','\',code,'\',num2str(face),'\EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg')),'file') ~= 2
                            
                            %%
                            obj = FaceEarOutputs{face,:}.FaceEarOutputs;
                            showAndSaveResultsImage(obj,gprvalue,40,1400,'off','on','on',Segmentation,UseColorMask,SoftwareVersion); % Max 40 cm at 1400 pixels
                            EarAuditLog.trace('Saving image output Success');
                            
                        end
                        
                    end
                    
                    if ProduceGraphs(2)
                        
                        if exist(fullfile(strcat(BDD_path,'\',code{1},'\',num2str(face),'\EarMeasurements_EarMaskoff_',Segmentation,'_',num2str(UseColorMask),'.jpeg')),'file') ~= 2
                            
                            %%
                            obj = FaceEarOutputs{face,:}.FaceEarOutputs;
                            showAndSaveResultsImage(obj,gprvalue,40,1400,'off','on','off',Segmentation,UseColorMask,SoftwareVersion); % Max 40 cm at 1400 pixels
                            
                        end
                    end
                    
                catch
                    EarAuditLog.trace('Saving image output Fail');
                end
            end
            
        end
        
        logging.clearLogger(LogName);
        
    end
    
    
end

% Ear Done :
fprintf('Job Finished !');

% end functions

% ------------------------------------------------------------
% ------------------------------------------------------------

%% Begin main :

% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main (see VARARGIN)

% Set main not visible :
set(handles.main,'Visible','Off')
drawnow
movegui(gcf,'center')
guidata(hObject, handles);

% Path d'entr�e : 
handles.SessionPath = varargin{2};
handles.WindowMode = varargin{3};
% resetwaitbar(handles)
% guidata(hObject, handles);
% set(gcf,'Visible','off')

%% Initialising : 
current_process(handles,'Initialisation...')
new_handles = Stock_Positions(hObject,handles);
handles = new_handles;
guidata(hObject, handles);

% Initiate window : 
set(handles.csvname_diam,'Visible','Off')
set(handles.csvname_earfilling,'Visible','Off')
set(handles.csvname_graindim,'Visible','Off')
set(handles.pdfname_withmask,'Visible','Off')
set(handles.pdfname_nomask,'Visible','Off')

%% To switch to on ! ATTENTION
set(handles.txtbox_code,'Visible','Off');
set(handles.txtbox_specific_process,'Visible','Off');


%% Compute 'global' vars : 

% Choose default command line output for main
handles.output = hObject;
handles.BDD_path = 'No_Value';
handles.computing = 'parallel';

% Load session data and parameters : 
try
    load(fullfile(strcat(handles.SessionPath,'\Info.session')),'-mat')
    handles.CurrentSession =  CurrentSession  ; 
%     cd(handles.CurrentSession.Session_Path);
catch
    warndlg('Impossible de charger les informations de session !','Erreur')
    return
end

% Tester le chargement des donn�es de calibration : 
try 
    fid = fopen(fullfile(strcat(handles.SessionPath,'\Calibration')));
    data = fscanf(fid,'%f');
    handles.CurrentSession.Calibration.MinValue = data(1);
    handles.CurrentSession.Calibration.MaxValue = data(2);    
catch
    handles.CurrentSession.Calibration.MinValue = 0.00996;
    handles.CurrentSession.Calibration.MaxValue = 0.00998;
end

% Stock commit version : 
handles.CurrentSession.LastLoading = char(datetime('today'));
handles.CurrentSession.Commit = 'eecd91';
handles.CurrentSession.SoftWareVersion = 'v0.4';

% Set commit version in the versioning data : 
set(handles.text35,'String',[handles.CurrentSession.SoftWareVersion ' (' handles.CurrentSession.Commit ')'])

% Initialize log : 
try 
    handles.CurrentAuditLog = log4m.getLogger(strcat(handles.CurrentSession.Session_Path,'\SessionLog.txt')); 
catch
    warndlg('Impossible de charger le fichier log !','Erreur')
    return
end

% Set to all for now : 
% (TO REMOVE !!!!!!!!!)
handles.CurrentAuditLog.setLogLevel(handles.CurrentAuditLog.ALL);

% Tester si on a bien sauver un path, sinon on s'en va : 
if strcmp(handles.CurrentSession.Session_Path,'No_Value')==1
    handles.closeFigure = 1;
    close(gcbf)
    return
end

%% Switch window depending on mode and update handles, recenter everything and start to show gui : 
movegui(gcf,'center')
set_mode(handles,handles.WindowMode)
drawnow
resetwaitbar(handles);
guidata(hObject, handles);

%% Try catch to remove at final version : 
try
    % Add phymea image :
    set(handles.axis_logo,'Visible','off')
    axes(handles.axis_logo)
    matlabImage = imread(fullfile('logo_registred_alpha.png')); % A changer !
    image(matlabImage)
    clear matlabImage
    axis off
    axis image
    drawnow
catch
    
end

%% Now everything is set and axes are changes we can call visibility : 
% set(handles.main,'Visible','on')
set(gcf,'Visible','on')
guidata(hObject, handles);

% set(gcf,'Visible','on')

% Set all properties to visible or not depending :
% set(handles.uipanel_treatment,'Visible','On')
% set(handles.text_face,'Visible','On')
% set(handles.popupmenu_faces,'Visible','On')
% set(handles.listbox_ears,'Visible','On')

%% Set session name and resize depending on name size :
handles.BDD_path = handles.CurrentSession.Session_Path;
Splitted = strsplit(handles.CurrentSession.Session_Path,'\')  ;
handles.session_name = Splitted(length(Splitted)) ;
set(handles.Session_Name,'String',handles.session_name) ;
Extents = get(handles.Session_Name,'Extent') ;
Positions = get(handles.Session_Name,'Position') ;
set(handles.Session_Name,'Position',[Positions(1) Positions(2) Extents(3) Positions(4)]) ;

%% Now all set we can make everything visible : 
set_visibility(handles)

%% Check for ear masking : 
handles.data_Path = fullfile(strcat(handles.CurrentSession.Session_Path,'\data'));
earList = cellstr(ls(fullfile(strcat(handles.CurrentSession.Session_Path,'\data'))));
earList = earList(~ismember(earList,{'.','..'}));

handles.CurrentAuditLog.trace('Session opened','Success'); 
% New session or incomplete segmentation ==> Mask ears : 
if handles.CurrentSession.isMasked==0 ;
    
    handles.CurrentAuditLog.trace('Starting Ear masking process from','Success'); 
    set(handles.main, 'pointer', 'watch')
    set(handles.pushbutton_treatment,'Enable','off')
    [handles.CurrentSession.Masking.Results] = ear_masking(handles,handles.CurrentSession.Session_Path,handles.CurrentSession.Image_Path);
    handles.CurrentSession.isMasked = 1;

end
set(handles.main, 'pointer', 'arrow');
set(handles.pushbutton_treatment,'Enable','on')

% If we arrive here it means we have populated the data folder with
% masked images !

%% Save currentsession data for future openings : 
% To remove : 
CurrentSession = handles.CurrentSession; 
CurrentSession.isADMIN = 0;
save(fullfile(strcat(handles.CurrentSession.Session_Path,'\','Info.session')),'CurrentSession');
handles.CurrentAuditLog.trace(strcat(handles.CurrentSession.SessionName,'.session SAVE'),'Success');


%% Load previous outputs or produce empty output : 
handles.data_Path = fullfile(strcat(handles.BDD_path,'\data'));
earList = cellstr(ls(fullfile(strcat(handles.BDD_path,'\data'))));
earList = earList(~ismember(earList,{'.','..'}));

% If output doesn't exist create the rep : 
CheckOutput = strcat(handles.BDD_path,'\Outputs');
if exist(fullfile(CheckOutput),'dir') == 0
    mkdir(fullfile(CheckOutput))
end

CheckOutput = strcat(handles.BDD_path,'\Session.output');

% Initiate ears :
if exist(fullfile(CheckOutput),'file') == 2
    load(CheckOutput,'-mat')
    handles.Outputs = ToSave;
    % If last column is defined, ear is treated :
    % Should change to a boolean ! 
    % We shoudl do it differently... ? 
    % Normaly we charge ear data before treating so think we don't need
    % this anymore.
    handles.earsFacesDone = ~isnan(handles.Outputs.Data(:,12,1,1));
    % Reset parameters : 
    handles.CurrentColorMask = 1 ;
    handles.SegmentationVersion = 1 ;
else
    handles.Outputs.Data = NaN((length(earList))*6,13,4,2); % Ear,Var,Analysis,Seg
    handles.Outputs.Codes = earList;
    handles.Outputs.Vars = {'Face','Longueur','Largeur',...
                            'l_fertile','l_basal','l_apical','NbGpR',...
                            'NbrBot','NbrMid','NbrTop',...
                            'HauteurGrain','DiamGrain','NbGr'}; 
    handles.Outputs.ringDimensions(1:length(earList),1:4,1:2) = struct();
    handles.earsFacesDone = zeros(length(earList)*6,1,4,2);
    
    % Metadata : 
    handles.MetaData = struct();
    handles.MetaData.Versioning = NaN((length(earList))*6,3); % Hard / Soft / ??
    handles.MetaData.Analysis = NaN((length(earList))*6,4); % SessionName + Date (Hard / Soft)
    handles.MetaData.Parameters = NaN((length(earList))*6,2); % Type Analysis + Type Segmentation
    handles.MetaData.Infos = NaN(1,2); % Type Analysis + Type Segmentation
    handles.MetaData.Calibration = struct(); 
    handles.MetaData.isSet = 0;
    
    % All to do : 
    % SesionName / Creation Date
    % Version Earbox / Viersion acquisition / Calibration parameters
    % Segmentation Date / PX2CM / Analysis date / V logiciel 
    % Type analyse / Type segmentation / Remarques
    handles.CurrentColorMask = 1 ;
    handles.SegmentationVersion = 1 ;
    
end

handles.IsSetOutputPath = 0 ; 

% Save metadata : 
Versions = get(handles.Segmentation_Version,'String');
ColorMasks = get(handles.colormaskvalue,'String');
handles.ReAnalysisValue = get(handles.reanalysis,'Value');
handles.MetaData.Infos = [Versions(handles.CurrentColorMask),ColorMasks(handles.SegmentationVersion)] ; 
clear Versions ColorMasks

% Populate the listbox_ears with folders from database
handles.EarList = earList ;
set(handles.listbox_ears,'String',earList);

% When listbox are populated we can calculate ear numbers correctly : 
if ~isfield(handles,'EarCodesAndNum')
    
   handles.EarCodesAndNum = get_ear_infos(earList);
    
end

% set all flags to false : 
% Long / Larg / Lfert / Basal / Apical / Etages / Ranks bot / Ranks Mid /
% Ranks Top / Hauteur / Diam / Nbgr
% Diameter along ear / Remplissage / Grain dimensions / Ear mask / Ear no mask
handles.checkbox_flags = [0 0 0 0 0 0 0 0 0 0 0 0];
handles.file_flags = [0 0 0 0 0];

% Initiate default values for selections :
handles.selected_face = 1;
handles.selected = {} ;
handles.AllEarSelected = 0;

current_process(handles,'Pr�t pour analyse !')

% memory
% whos

% Update handles structure
guidata(hObject, handles);

%% Close main :
% --- Executes just before main is made deleted.
function main_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure

selection = questdlg('Sauver et fermer la session ?',...
    'Attention !!',...
    'Oui','Non','Oui');
switch selection,
    case 'Oui',
        delete(gcf)
        
        % Reset ADMIN data :
        handles.CurrentSession.isADMIN = 0;
        try
            CurrentSession = handles.CurrentSession ;
            save(fullfile(strcat(handles.CurrentSession.Session_Path,'\','Info.session')),'CurrentSession');
            handles.CurrentAuditLog.trace('Saving before closing','Success');
        catch
            %     handles.CurrentAuditLog.trace('Saving before closing','Fail');
        end
        
        % Close parallel pool : 
        poolobj = gcp('nocreate');
        delete(poolobj);
        
    case 'Non'
        return
end
 


delete(hObject);

% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if (isfield(handles,'closeFigure') && handles.closeFigure)
      main_CloseRequestFcn(hObject, eventdata, handles)
      return
end
 
% varargout{1} = handles.output;

% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.main);

% end main

% ------------------------------------------------------------
% ------------------------------------------------------------

% Begin MAIN BUTTONS :

% --- Executes on button press in MenuSession.
function MenuSession_Callback(hObject, eventdata, handles)

% CurrentSession = handles.CurrentSession; %#ok<NASGU>
% save(fullfile(strcat(handles.CurrentSession.Session_Path,'\','Info.session')),'CurrentSession');
% handles.CurrentAuditLog.trace(strcat(handles.CurrentSession.SessionName,'.session SAVE'),'Success');
% delete(handles.CurrentAuditLog);

close(gcbf)

% --- Executes on button press in pushbutton_treatment.
function pushbutton_treatment_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_treatment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Initialize log : 
try 
    handles.CurrentAuditLog = log4m.getLogger(strcat(handles.CurrentSession.Session_Path,'\SessionLog.txt')); 
catch
    warndlg('Impossible de charger le fichier log !','Erreur')
    return
end

% Set to all for now : 
% (TO REMOVE !!!!!!!!!)
handles.CurrentAuditLog.setLogLevel(handles.CurrentAuditLog.ALL);


handles.CurrentAuditLog.trace(strcat('Starting ear processing'),'Success');


%% Define the analysis depending on the mode chosen : 
if strcmp(handles.WindowMode,'Normal')
    
    new_handles = Global_analysis_Callback(hObject,handles);
    handles = new_handles;

end
    
    
%% Initialize gui/visual/path : 

% Initialize window : 
set(handles.button_stop,'Visible','On');
set(handles.change_mode,'Enable','Off');

handles.Execution = 1;
resetwaitbar(handles);
reset_visualizeear(handles)
Password_Callback(hObject, eventdata, handles)

Version_Seg = get(handles.Segmentation_Version,'String');
if strcmp(Version_Seg,'v1.0 - Empiric Segmentation')
    Segmentation = 'New';
else
    Segmentation = 'New';
end
         
% Handle errors (no ear or file/variale seleced : 
if isempty(handles.selected)
    mydialog('Erreur','Veuillez s�lectionner un �pi !')
    return
end
if sum(handles.checkbox_flags)==0 && sum(handles.file_flags)==0
    mydialog('Erreur','Veuillez s�lectionner une variable ou un fichier de sortie !')
    return
end

%% Initiate validity check : 
isValidEar = 0;
isBadEar = 0;

% Set outputPath in try catch ?? 
handles.IsSetOutputPath = 0 ;
guidata(hObject,handles)
OutputPath = 'none'; 
try
    OutputPath = define_output_path(handles);
catch
end


% Leave if path wasn't defined correctly : 
if strcmp(OutputPath,'none')
    mydialog('Erreur','Veuillez choisir un dossier pour continuer')
    return
end

% Check if output empty and deal with it : 
ListFiles = cellstr(ls(fullfile(OutputPath)));
ListFiles = ListFiles(~ismember(ListFiles,{'.','..'}));
% Answer = 'Oui';
if ~isempty(ListFiles)
    Answer = questdlg(['Des fichiers existe d�j� dans ce dossier. S''il s''agit de sorties EARBOX'   sprintf('\n')  'en cliquant sur ''oui'' elles seront remplac�es, voulez-vous continuer ?'], 'Attention! ', 'Oui', 'Non','Non');
    if strcmp(Answer,'Non')
        return
    end
end     


% Stock it and set IsSetOutputPath to 1 : 
handles.OutputPath = OutputPath;
handles.IsSetOutputPath = 1;

%% If everything is set, run the treatment & outputs : 
if ~isempty(handles.selected)
     
    % Set pointer to watching :
    set(gcf,'pointer','watch');
    SwitchVisibility_OnProcess(handles,'on');
    
    %% Initialize variables for files if needed :
    
    % Check seleted ears & flags :
    FlagsToUSe = handles.file_flags;
    
    % Initialize files :
    FilesStruct = initialialize_files(handles,handles.OutputPath,FlagsToUSe);
    handles.CurrentAuditLog.trace('Initializing files','Success');
    
    % For main csv initializing +  columns - ALL THE TIME :
    VarsNames = handles.Outputs.Vars(2:13);
    MainCsvName = get(handles.csvname_main,'String');
    PathToMainCsv = fullfile(OutputPath,MainCsvName);
    fileID = fopen(PathToMainCsv,'wt') ;
    fprintf(fileID,'%s','Code');
    % Nom des vaiables du CSV : fair des ajouts en fonction : 
    fprintf(fileID,';%s','N_Epi','Rep','Face',VarsNames{handles.checkbox_flags==1},'Comment','Date_Acquisition','Version_SoftWare','px_2_cm','Calibration','Code_Acquisition','Earbox_Session');
    fprintf(fileID,'\n');
    fclose(fileID);
    
    %% For analysis summary :
    
    % TO MOVE SOMEWHERE ELSE : 
    StartTime = datetime('now');
    Versions = get(handles.Segmentation_Version,'String');
    Version = Versions{handles.SegmentationVersion};
    Colormasks = get(handles.colormaskvalue,'String');
    Colormask = Colormasks{handles.CurrentColorMask};
    handles.Outputs.VarDescription = {'= ear length in cm',...
        '= ear max diameter in cm',...
        '= ear fertile zone length in cm',...
        '= ear basal abortion length in cm',...
        '= ear apical abortion length in cm',...
        '= number of grain per ranks',...
        '= number of ranks in basal zone (1st third)',...
        '= number of ranks in middle zone (2nd third)',...
        '= number of ranks in apical zone (3rd third)',...
        '= ear height in cm',...
        '= ear diameter in cm',...
        '= number of grain per ear estimated from ear side information'};
    handles.Outputs.FilesNames = {get(handles.csvname_diam,'String'),...
            get(handles.csvname_earfilling,'String'),...
            get(handles.csvname_graindim,'String'),...
            get(handles.pdfname_withmask,'String')};
    handles.Outputs.FilesDescription = ...
        {' CSV file with ear diameter (cm) along ear length every 0.1 cm for all ear sides',...
        ' CSV file with grain to ear filling ratio (%) along ear length every 0.1 cm for all ear sides',...
        ' CSV file with grain mean dimensions (cm) and mean position (grain per rank) along ear length for all ear sides',...
        ' PDF file summarizing all calculated variables of ear (one page per ear)'};
    
    % Now write the beginning of analysis summary file : 
    PathToSummary = fullfile(OutputPath,['Summary_of_analysis_'  handles.CurrentSession.LastLoading   '.txt']);
    fileID = fopen(PathToSummary,'wt') ;
    % Analysis & session info :
    fprintf(fileID,'%s',['## File created automaticaly by Zea Analyser - Phymea Systems:']);
    fprintf(fileID,'%s',[' ','software analysis for maize ear segmentation and analysis.']);
    fprintf(fileID,'\n');    
    fprintf(fileID,'%s',['## This file presents the outputs of the last analysis performed with the software.']);
    fprintf(fileID,'\n');    
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['# Analysis parameters :']);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['Session name :',' ',handles.CurrentSession.SessionName]);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['Session path :',' ',handles.CurrentSession.Session_Path]);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['Output path :',' ',handles.OutputPath]);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['Number of ears to analyse :',' ',num2str(length(handles.selected))]);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['Segmentation algorithm :',' ',Version]);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['Colormask :',' ',Colormask]);
    fprintf(fileID,'\n');    
    fprintf(fileID,'%s',['Starting time of analysis :',' ']);
    fprintf(fileID,'%s',StartTime); % datetime cant be concatenated with a string
    fprintf(fileID,'\n');    
    fprintf(fileID,'%s',['Software version of analysis :',' ',handles.CurrentSession.SoftWareVersion]);    
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['Git commit version :',' ',handles.CurrentSession.Commit]);    
    fprintf(fileID,'\n');    
    % Variables : 
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['# Output variables in the main csv :',' ',MainCsvName]);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['CSV file summarizing all measurements per ear and side']);
    fprintf(fileID,'\n');
    if any(handles.checkbox_flags)
        for i = 1:length(handles.checkbox_flags)
            if handles.checkbox_flags(i)
                fprintf(fileID,'%s',['-',handles.Outputs.Vars{i+1},' ',handles.Outputs.VarDescription{i}]);
                fprintf(fileID,'\n');
            end
        end
    else
        fprintf(fileID,'%s',['none']);
        fprintf(fileID,'\n');
    end
    fprintf(fileID,'%s',['-','Comment',' ','= Analysis comentary / warnings / errors']);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['-','Date_Acquisition',' ','= Photo acquisition date']);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['-','Version_SoftWare',' ','= Version of the software for this analysis (versioning + git commit)']);
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['-','px_2_cm',' ','= Multiplier to convert pixel to cm, result from camera calibration']);
    fprintf(fileID,'\n');
    % Other files : 
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['# Other output files :',' ']);
    fprintf(fileID,'\n');
    % All different files if needed :
    if any(handles.file_flags)
        for i =1:length(handles.file_flags)
            if handles.file_flags(i)
                fprintf(fileID,'%s',['-',handles.Outputs.FilesNames{i},':',' ',handles.Outputs.FilesDescription{i} ]);
                fprintf(fileID,'\n');
            end
        end
    else
        fprintf(fileID,'%s',['none']);
        fprintf(fileID,'\n');
    end     
    fprintf(fileID,'\n');
    fprintf(fileID,'%s',['# Analysis :',' ']);
    fprintf(fileID,'\n');    
    fclose(fileID);

    handles.CurrentAuditLog.trace('Writing summary file header','Success');
        
    % END TO MOVE SOMEWHERE ELSE 
    
    %% Now the real fun begins : 
    
    code = cellstr(handles.selected);

    
    % Check for graphs :
    ProduceGraphs = [handles.file_flags(4)  handles.file_flags(5)] ;
    
    % Check if admin :
    if handles.CurrentSession.isADMIN
        % Get temp folder :
        prompt = {'Use a temp folder ? (0/1)'};
        UseTempFolder = inputdlg(prompt);
        UseTempFolder = UseTempFolder{1};
    else
        UseTempFolder = 0 ;
    end
    
    % Get colormask :
    if get(handles.colormaskvalue,'Value') == 1
        UseColorMask = true;
    else
        UseColorMask = false;
    end
    
    handles.CurrentAuditLog.trace('Initialising analysis parameters','Success');
    
    % Get version and colormask num :
    %handles.SegmentationVersion
    %handles.CurrentColorMask
    
    % Initialising data for advance show :
    ToDo = length(code)*6;
    Done = 0;
    update_show_run(handles,'Traitement...',Done,ToDo)
    % Initiate memory diagnosis :
    if handles.CurrentSession.isADMIN
        memory
        Mem = struct();
        Mem.MatlabUsed = zeros(1,6*length(code));
        Mem.PhysicalMemoryAvailable = zeros(1,6*length(code));
        Mem.VirtualAddressAvailable = zeros(1,6*length(code));
        Mem.VirtualAddressAvailable = zeros(1,6*length(code));
        Mem.MemAvailableAllArrays = zeros(1,6*length(code));
    end

    % Stays parallel all the time else its hardcore long
    Computing = handles.computing;
    SoftwareVersion = [handles.CurrentSession.SoftWareVersion '_' handles.CurrentSession.Commit];
    % Handling pdfs : 
    if any(FlagsToUSe(4:5))
        
        PdfFolderMask = fullfile(strcat(handles.OutputPath, '\PDFs'));
        if (exist(PdfFolderMask,'file') == 0), mkdir(PdfFolderMask); end
        
        filePattern = fullfile(PdfFolderMask, '*.pdf'); % Change to whatever pattern you need.
        theFiles = dir(filePattern);
        for k = 1 : length(theFiles)
            baseFileName = theFiles(k).name;
            fullFileName = fullfile(PdfFolderMask, baseFileName);
            fprintf(1, 'Now deleting %s\n', fullFileName);
            delete(fullFileName);
        end
        
        handles.CurrentAuditLog.trace('Deleting previous pdfs','Success');

    end
            
    AnalysisResults = zeros(1,numel(code)*6);
    
    %% Initiate loop along codes :
    for ear = 1:length(code)
        
        % Info for csv : 
        code = cellstr(handles.selected{ear});
        [ code_epi , ear_position_on_cam ] = separate_earcode( handles.selected{ear} );
        idx = find(strcmp(handles.EarCodesAndNum.Sorted_earlist, handles.selected{ear}));
        num_epi = handles.EarCodesAndNum.Num(idx);
                
        % Update ear code : 
        update_specific_process(handles,strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' -' ' ' num2str(ear) '/' num2str(length(handles.selected))]));

        %% Computing infos :
        
        BDD_path = handles.BDD_path ;
        EarList = handles.EarList;
        
        CurrentColorMask = handles.CurrentColorMask;
        checkbox_flags = handles.checkbox_flags;
        
        Calibration = handles.CurrentSession.Calibration;
        
        %% Get infos if needed for reanalysis :
        ToReanalyse = handles.ReAnalysisValue;
        
        if ToReanalyse
            
            handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Cleaning ear folder']),'Success');
            for face = 1:6
                % For data : 
                try
                    FileToSearch = strcat('FaceEarOutputs_',Segmentation,'_',num2str(UseColorMask),'.mat');
                    PathToCheck = fullfile(BDD_path, 'data',code,num2str(face),FileToSearch) ;
                    
                    if exist(PathToCheck{1},'file')==2
                        fprintf(1, 'Now deleting %s\n', PathToCheck{1});
                        delete(PathToCheck{1});
                    end
                    handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Cleaning ear data']),'Success');
                catch
                    handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Cleaning ear data']),'Fail');
                end
                % For image : 
                try
                    FileToSearch = strcat('EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg');
                    PathToCheck = fullfile(BDD_path, 'data',code,num2str(face),FileToSearch) ;
                    if exist(PathToCheck{1},'file')==2
                        fprintf(1, 'Now deleting %s\n', PathToCheck{1});
                        delete(PathToCheck{1});
                    end
                    handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Cleaning ear image']),'Success');
                catch
                    handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Cleaning ear image']),'Fail');
                end                
            end
            
        end

        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - initialising ear']),'Success');

        %% THE ACTUAL EAR COMPUTING LINE :
        [FaceEarOutputs,outputs,ValidEar] = EarComputing(BDD_path,EarList,Segmentation,CurrentColorMask,checkbox_flags, code{1},UseTempFolder,UseColorMask,ProduceGraphs,Computing,SoftwareVersion,Calibration);

        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - computing ear']),'Success');
           
        % Validity check : 
        if sum(ValidEar)>0
            isValidEar = isValidEar +1 ;
            toto = 1;
        else 
            isBadEar = isBadEar +1 ;
            toto = 0;

        end
        
        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - validity check :',num2str(toto)]),'Success');
            
        %% Global file computation (ALL THE TIME) :
        try
            
            fileID = fopen(PathToMainCsv,'a') ;
            
            for face = 1:6
                
                % Subset the right column + correct inf:
                ToWrite = [outputs(face,[find(handles.checkbox_flags)])];
                ToWrite(ToWrite<0)=0;
                ToWrite(~isfinite(ToWrite))=NaN;
                
                % Change code and rep : 
                New_Code = code_epi;
                try
                    Rep = numel(strfind(code_epi,'x1'));
                    RepNumber = Rep+1;
                    if RepNumber>1 && length(code_epi)>2
                        New_Code = code_epi(1:end-(2*Rep));
                    end
                    RepToWrite = num2str(RepNumber);
                catch
                    RepToWrite = 'No_Data';
                    New_Code = code_epi;
                end                                
                
                % Code et face :
                fprintf(fileID,'%s%s',New_Code,';') ;
                fprintf(fileID,'%d%s',num_epi) ;
                fprintf(fileID,';%s',RepToWrite);
                fprintf(fileID,';%s',num2str(face));
                
                % Switch to NA when needed : 
                for val = 1:length(ToWrite)
                    
                    if isnan(ToWrite(val)) || all(ToWrite==0.00)
                        
                        fprintf(fileID,';%s','NA');
                        
                    else
                        
                        fprintf(fileID,';%2.2f',ToWrite(val));
                        
                    end
                    
                end
                
                % Write the comment (get the FaceEarOutputs in the right form) : 
                if strcmp(Computing,'classic')
                    try
                        obj =FaceEarOutputs{face}.FaceEarOutputs;
                    catch
                        obj = FaceEarOutputs{face};
                    end
                else
                    obj = FaceEarOutputs{face};
                    
                end
                
                if isfield(obj,'Warning')
                    if ~isempty(obj.Warning)
                        newStr = strrep(obj.Warning,' ','_');
                        fprintf(fileID,';%s',newStr);
                    else
                        fprintf(fileID,';%s','No');
                    end
                else
                        fprintf(fileID,';%s','No');
                end
                
                % Write the exif info (datetime): 
                try 
                    FileName = fullfile(BDD_path,'data',code,num2str(face),'Image.Metadata');
                    load(FileName{1},'-mat');
                    Date = ImInfo.ExifInfo.DateTime;
                    fprintf(fileID,';%s',strrep(Date,' ','-'));
                    clear ImInfo
                catch 
                    fprintf(fileID,';%s','No_Data');
                end
                
                % Softwarr version info : 
                newStr = strrep(SoftwareVersion,' ','_');
                fprintf(fileID,';%s',newStr);
                
                % Ratio pixel2cm from calibration : 
                try
                    px2cm = obj.PX2CM;
                    fprintf(fileID,';%s',num2str(px2cm));
                catch
                    fprintf(fileID,';%s','No_Calibration_Data');
                end

                fprintf(fileID,';%s','No_Calibration_Data');
                
                % Ear name from acquisition : 
                fprintf(fileID,';%s',handles.selected{ear}); 
                
                % Session_Name : 
                fprintf(fileID,';%s',handles.CurrentSession.SessionName); 
                
                
                % Nouveau nombres de rangs a tester : 
                %fprintf(fileID,';%2.2f',obj.EarOrganisation.DebugRanks.Mid); 
                %fprintf(fileID,';%2.2f',obj.EarOrganisation.DebugRanks.mid_method2); 
                %fprintf(fileID,';%2.2f',obj.EarOrganisation.DebugRanks.mid_method3); 
                fprintf(fileID,'\n');
                
                % Clear objects : 
                clear obj
                
            end
            
            fclose(fileID);
            
            handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Writing main data in ', PathToMainCsv]),'Success');
            
        catch
            handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Writing main data in ', PathToMainCsv]),'Fail');
        end
        

        %% Catch warnings and put them in the summary file : 
        SummaryfileID = fopen(PathToSummary,'a') ;

        for face = 1:6
            % Get data :
            if strcmp(Computing,'classic')
                try
                    obj =FaceEarOutputs{face}.FaceEarOutputs;
                catch
                    obj = FaceEarOutputs{face};
                end
            else
                obj = FaceEarOutputs{face};
                
            end
            
            try
                
                if isfield(obj,'Warning')
                    if ~isempty(obj.Warning)
                        fprintf(fileID,'%s',['- code',' ',handles.selected{ear},' ','face',' ',num2str(face),' ',obj.Warning]);
                        fprintf(fileID,'\n');
                        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Writing warning data :', obj.Warning]),'Success');
                    end
                end
                
            catch
                handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Writing warning data']),'Fail');

            end
            
            
        end
        
        fclose(SummaryfileID);
        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Writing summary data']),'Success');
        
        
%         if strcmp(code{1},'Morph_WD1_H01_L12_d')
%             fprintf('Hello')
%         end
        
        %% Store handles data : 
        %Store in handles data : Outputs.Data( Ear,Var,Analysis,Seg )
        Code = handles.selected{ear};
        MyString = strfind(handles.Outputs.Codes, Code);
        numcode = find(not(cellfun('isempty',MyString)));
        ToCat = (1:6)';
        ToWrite = [ ToCat  outputs];
        %handles.Outputs.Data(((numcode-1)*6+1):((numcode-1)*6+6),1:13,UseColorMask+1,1)= ToWrite;
%         handles.Outputs.Data(((numcode-1)*6+1):((numcode-1)*6+6),1:13,UseColorMask+1,1)= ToWrite;
        
        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Storing outputs in handles']),'Success');
        
        %% CSV detailed file if needed :
        FlagsToUSe = handles.file_flags;
        
        if any(FlagsToUSe(1:3))
            %% Write files :
            for face = 1 : 6
                
                if strcmp(Computing,'classic')
                    
                    try
                        obj =FaceEarOutputs{face}.FaceEarOutputs;
                    catch
                        obj = FaceEarOutputs{face};
                    end
                    
                else 
                    obj = FaceEarOutputs{face};
                    
                end
                
                %% 1) Diameter along length (0.1cm):
                
                if FlagsToUSe(1)
                    
                    try
                        
                        % handles.checkbox_flags =[1 1 0 0 0 0 0 0 0 0 0 0] ;
                        clear PositionToWrite DiameterInPxL DiameterInCm PositionInCm DiameterToWrite
                        % CEST DE LA MERDE, PAS DANS LE BON SENS :
                        DiameterInPxL = fliplr(obj.EarSize.Diam.RadiusProfile(obj.EarSize.EarBasePxL:obj.EarSize.EarApexPxL)*2);
                        DiameterInCm = DiameterInPxL*obj.EarSize.Diam.PX2CM;
                        PositionInCm = (1:length(DiameterInCm))/length(DiameterInCm)*obj.EarSize.Length.Cm;
                        
                        % Summarize by cm :
                        k=1 ;
                        for i = 0:0.1:max(PositionInCm)-0.1
                            
                            PositionToWrite(k) = i ;
                            
                            ID = find(PositionInCm < i+0.1 & PositionInCm > i) ;
                            if ~isempty(ID)
                                DiameterToWrite(k) = mean(DiameterInCm(ID));
                                k = k+1;
                            end
                        end
                        
                        % Write file :
                        csvname = get(handles.csvname_diam,'String');
                        PathToGo = fullfile(handles.OutputPath,csvname);
                        fileID = fopen(PathToGo,'a');
                        
                        for line  = 1 : length(PositionToWrite)
                            
                            fprintf(fileID,'%s%s',code_epi,';') ;
                            fprintf(fileID,'%d%s',num_epi,';') ;
                            
                            fprintf(fileID,'%d%s',face) ;
                            fprintf(fileID,';%2.2f',round(PositionToWrite(line),2));
                            fprintf(fileID,';%2.2f',round(DiameterToWrite(line),2));
                            fprintf(fileID,'\n');
                            
                        end
                        
                        fclose(fileID);
                        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - Writing diameter data']),'Success');
                    catch
                        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - Writing diameter data']),'Fail');
%                         fprintf(SummaryfileID,['Writing Diameter data in',' ',code_epi,' ','side',' ',num2str(face),',',' ','fail']);
%                         fprintf(SummaryfileID,'\n');
                    end
                    
                end
                
                %% 2) Ear filling along length (0.1cm):
                if FlagsToUSe(2)
                    
                    %handles.checkbox_flags =[1 0 1 1 1 0 0 0 0 0 0 0] ;
                    try
                        % Find vector from base to apex and flip it to
                        % start ear base + get position : 
                        clear PositionToWrite RatioToWrite EarToGrainRatio PositionInCm
                        
                        EarToGrainRatio = fliplr(obj.EarSize.Abortion.ear_to_grain_ratio(obj.EarSize.EarBasePxL:obj.EarSize.EarApexPxL));
                        PositionInCm = (1:length(EarToGrainRatio))/length(EarToGrainRatio)*obj.EarSize.Length.Cm;
                        
                        % Summarize by 10th cm :
                        k=1 ;
                        for i = 0:0.1:max(PositionInCm)-0.1
                            PositionToWrite(k) = i ;
                            ID = find(PositionInCm < i+0.1 & PositionInCm > i) ;
                            if ~isempty(ID)
                                RatioToWrite(k) = mean(EarToGrainRatio(ID));
                                k = k+1;
                            end
                        end
                        
                        % Write file :
                        csvname = get(handles.csvname_earfilling,'String');
                        PathToGo = fullfile(handles.OutputPath,csvname);
                        fileID = fopen(PathToGo,'a');
                        
                        for line  = 1 : length(PositionInCm)
                            
                            fprintf(fileID,'%s%s',code_epi,';') ;
                            fprintf(fileID,'%d%s',num_epi,';') ;
                            
                            fprintf(fileID,'%d%s',face) ;
                            fprintf(fileID,';%2.2f',round(PositionInCm(line),2));
                            fprintf(fileID,';%2.2f',round(EarToGrainRatio(line),2)*100);
                            fprintf(fileID,'\n');
                            
                        end
                        
                        fclose(fileID);
                        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - Writing grain filling ratio data']),'Success');

                    catch
                        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - Writing grain filling ratio data']),'Fail');
%                         fprintf(SummaryfileID,['Probably no fertile kernel - Writing grain filling ratio data in',' ',code_epi,' ','side',' ',num2str(face),',',' ','fail']);
%                         fprintf(SummaryfileID,'\n');
                    end
                    
                end
                
                %% 3) Grain dimensions with position (0.5cm) :
                if FlagsToUSe(3)
                    
                    % POSITION NOT ON THE RIGHT SIDE OF THE EAR ? 
                    % ==> Ok corrected

                    type = 'byposition';
                    
                    
                    try
                        
                        
                        if strcmp(type, 'bygrain')==1
                            
                            clear Xdim sd_Xdim Ydim sd_Ydim position_x sd_position_x area_cm2 sd_area_cm2 Position Level
                            DataPerGrain = obj.GrainsAttributes.ringDimensions.Grain;

                            %% Variables :
                            Position_y_pxl = DataPerGrain.PositionAlongDiameter;
                            EarBasePxl = find(sum(obj.Visual.Mask),1,'last');
                            Position_x_pxl = EarBasePxl - DataPerGrain.PositionAlongEar; % pxl from ear base pxl CONVERTED into image pixel
                            Position_x_cm = DataPerGrain.PositionAlongEar * obj.PX2CM ; % position in cm from earbase
                            YDim = DataPerGrain.YDim* obj.PX2CM;
                            Xdim = DataPerGrain.Xdim* obj.PX2CM;
                            Level = DataPerGrain.Pos ;
                            % Threshold = DataPerGrain.Threshold ;
                            
                            Area = DataPerGrain.Projected_Area * obj.PX2CM * obj.PX2CM;
                            PX2CM = obj.PX2CM;
                            
                            % Write file :
                            csvname = get(handles.csvname_graindim,'String');
                            PathToGo = fullfile(handles.OutputPath,csvname);
                            fileID = fopen(PathToGo,'a');
                            
                            % Loop over grains :
                            for grain = 1 : length(Position_x_pxl)
                                
                                fprintf(fileID,'%s%s',code_epi,';') ;
                                fprintf(fileID,'%d%s',num_epi,';') ;
                                fprintf(fileID,'%d%s',face) ;
                                
                                try
                                    
                                    
                                    %%%%%%%%%%%%%%%%%%%%%%%%%
                                    %%% Per grain :
                                    fprintf(fileID,';%4.0f',grain);
                                    fprintf(fileID,';%4.0f',Position_x_pxl(grain));
                                    fprintf(fileID,';%4.0f',Position_x_cm(grain));
                                    fprintf(fileID,';%4.0f',Position_y_pxl(grain));
                                    % Grain Width :
                                    if isnan(YDim(grain))
                                        fprintf(fileID,';%s','NA');
                                    else
                                        fprintf(fileID,';%1.2f',YDim(grain));
                                    end
                                    % Grain Height :
                                    if isnan(Xdim(grain))
                                        fprintf(fileID,';%s','NA');
                                    else
                                        fprintf(fileID,';%1.2f',Xdim(grain));
                                    end
                                    % Threshold value :
                                    %                                 fprintf(fileID,';%1.3f',Threshold(grain));
                                    fprintf(fileID,';%2.0f',Level(grain));
                                    fprintf(fileID,';%1.2f',Area(grain));
                                    fprintf(fileID,';%1.4f',PX2CM);
                                    fprintf(fileID,';%4.0f',EarBasePxl);
                                    %%%%%%%%%%%%%%%%%%%%%%%%
                                    
                                catch
                                    
                                    handles.CurrentAuditLog.trace('Writing grain dimensions',strcat(['Problem at position' ' ' num2str(Level(line)) ', skipping']));
                                
                                end
                                
                                fprintf(fileID,'\n');
                                
                            end
                            
                            fclose(fileID);
                            
                        end
                        
                        if strcmp(type, 'byposition')==1
                            
                            Ngrain = obj.GrainsAttributes.ringDimensions.N_grain;
                            YDim = obj.GrainsAttributes.ringDimensions.Ydim_cm ;
                            sd_Ydim = obj.GrainsAttributes.ringDimensions.sd_Ydim_cm ;
                            XDim = obj.GrainsAttributes.ringDimensions.Xdim_cm ;
                            sd_Xdim = obj.GrainsAttributes.ringDimensions.sd_Xim_cm ;
                            position_x = obj.GrainsAttributes.ringDimensions.position_x_cm ;
                            sd_position_x = obj.GrainsAttributes.ringDimensions.sd_position_x_cm ;
                            area_cm2 = obj.GrainsAttributes.ringDimensions.area_cm2 ;
                            sd_area_cm2 = obj.GrainsAttributes.ringDimensions.sd_area_cm2 ;
                            position_level = obj.GrainsAttributes.ringDimensions.pos ;
                            profile = obj.GrainsAttributes.ringDimensions.profile_cm ;
                            PX2CM = obj.PX2CM;
                            EarBasePxl = find(sum(obj.Visual.Mask),1,'last');
                            
                            % Write file :
                            csvname = get(handles.csvname_graindim,'String');
                            PathToGo = fullfile(handles.OutputPath,csvname);
                            fileID = fopen(PathToGo,'a');
                            
                            % Loop over grains :
                            for line  = 1 : length(position_level)
                                
                                fprintf(fileID,'%s%s',code_epi,';') ;
                                fprintf(fileID,'%d%s',num_epi,';') ;
                                fprintf(fileID,'%d%s',face) ;
                                
                                try
                                    
                                    % Per position :
                                    fprintf(fileID,';%2.0f',position_level(line));
                                    fprintf(fileID,';%2.2f',position_x(line));
                                    fprintf(fileID,';%2.2f',sd_position_x(line));
                                    fprintf(fileID,';%2.2f',profile(line));
                                    fprintf(fileID,';%2.2f',Ngrain(line));
                                    fprintf(fileID,';%2.2f',YDim(line));
                                    fprintf(fileID,';%2.2f',sd_Ydim(line));
                                    fprintf(fileID,';%2.2f',XDim(line));
                                    fprintf(fileID,';%2.2f',sd_Xdim(line));
                                    fprintf(fileID,';%2.2f',area_cm2(line));
                                    fprintf(fileID,';%2.2f',sd_area_cm2(line));
                                    fprintf(fileID,';%s',num2str(PX2CM));
                                    fprintf(fileID,';%4.0f',EarBasePxl);
                                    
                                catch
                                    handles.CurrentAuditLog.trace('Writing grain dimensions',strcat(['Problem at position' ' ' num2str(Level(line)) ', skipping']));
                                end
                                
                                fprintf(fileID,'\n');
                                
                                
                            end
                            
                            fclose(fileID);
                            
                        end
                        
                        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - Writing grain dimensions data']),'Success');

                        
                    catch
                        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - Writing grain dimensions data']),'Fail');
%                         fprintf(SummaryfileID,['Probably no fertile kernel - Writing grain dimensions data in',' ',code_epi,' ','side',' ',num2str(face),',',' ','fail']);
%                         fprintf(SummaryfileID,'\n');                    
                    end
                    
                end
                
            end
        end

        
        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Writing files']),'Success');

                
        %% Write pdf if needed :
        %% ADD PDF !
        % Create folders :
        if any(FlagsToUSe(4:5))
            
            if FlagsToUSe(4)
                
                PdfFolderMask = fullfile(strcat(handles.OutputPath, '\PDFs'));
                if (exist(PdfFolderMask,'file') == 0), mkdir(PdfFolderMask); end
                
            end
            
            if FlagsToUSe(5)
                
                PdfFolderNoMask = fullfile(strcat(handles.OutputPath, '\PDFs\','NoEarMask'));
                if (exist(PdfFolderNoMask,'file') == 0), mkdir(PdfFolderNoMask); end
                
            end
            
            handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Initialize pdf']),'Success');
            
            % Step 1 : Define filename and format normal A4 format :
            Filename = strcat(code_epi,'_Ear',num2str(num_epi));
            Filenames{ear} = strcat(Filename,'.pdf');
            ScreenSize = get(0,'ScreenSize');
            A4FigureLength = ScreenSize(4);
            A4FigureWidth = 0.7070 * A4FigureLength;
            % Check if need to 'rewrite' pdf :
            WhereToExport = strcat(PdfFolderMask,'\',Filenames{ear});
            FullFileNames{ear} = WhereToExport;
            
            if ~exist(FullFileNames{ear},'file')
                
                % Step 2 : Create individual pdfs :
                
                % Main pdf page :
                fig = figure('name',code{1},'Position',[0 0 A4FigureWidth A4FigureLength],'Visible','off'); % to change
                hold on
                
                annotation(fig,'textbox',[0.01 0.91 0.1 0.1],'Interpreter','none',...
                    'String',strcat('Code :',' ',code{1}),...
                    'color', [0.5 0.5 0.5],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
                
                annotation(fig,'textbox',[0.01 0.88 0.1 0.1],'Interpreter','none',...
                    'String',strcat('Ear N� :',' ',num2str(num_epi)),...
                    'color', [0.5 0.5 0.5],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
                
                % Produce images on pdf :
                for face = 1:6
                    
                    % define scale for visibility :
                    Scaling = 0.93;
                    
                    % Get back to fig :
                    set(0,'CurrentFigure',fig);
                    
                      PathToImage = strcat(handles.BDD_path,'\data\',code,'\',num2str(face),'\EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg');
                    % Check existence of output jpeg :
                    if exist(fullfile(PathToImage{1}),'file') == 2
                        
                        try
                             
                            % Read image if exist :
                            ImageToShow = imread(fullfile(PathToImage{1}));
                            [rows, columns, numberOfColorChannels] = size(ImageToShow);
                            FigureSize = get(fig,'Position');
                             
                            % Initialize axes of subplot :
                            ax = subplot('Position',[0 Scaling-((face/6)*Scaling) 1 1/6*Scaling],'visible','off');
                          
                            image(ax,ImageToShow)
%                             imshow(imresize(ImageToShow,[(FigureSize(4)/6)*Scaling NaN]),'InitialMagnification','fit')
                            set(ax, 'box', 'on', 'Visible', 'on','color',[0.5 0.5 0.5], 'xtick', [], 'ytick', [])
                            handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - Writing image in pdf']),'Success');
                        catch
                            fprintf(SummaryfileID,['Error in image - Writing pdf image for',' ',code_epi,' ','side,' num2str(face),' ','fail']);
                            handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi), ' - face : ',num2str(face),' - Loop info - IWriting image in pdf']),'Fail');
                            fprintf(SummaryfileID,'\n');
                            continue
                        end
                        
                    else
                        continue
                        
                    end
                    
                    % Set handles :
                    clear ImageToShow FigureSize Scaling
                    
                end
                
                %% Final pdf :
                
                clear face A4FigureWidth A4FigureLength
                
                Filename = strcat(code{1},'_Ear',num2str(num_epi));
                
                Filenames{ear} = strcat(Filename,'.pdf');
                
%                 print(fig,fullfile(WhereToExport),'-pdf','-Bestfit')
                
                export_fig(fig,fullfile(WhereToExport),'-pdf','-c[0,0,0,0]','-q300','-m2')
                                
                close(fig)
                clear fig
                clear Filename
            end
            
            
        end
        
        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Writing pdf']),'Success');

        %% Ok all sides done (treatment / files / images, we can go on :
        Done = Done +6;
        update_show_run(handles,'Traitement...',Done,ToDo);
        
        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - update visuals']),'Success');
        
        % Check memory per ear face :
        %             Password_Callback(hObject, eventdata, handles);
        if handles.CurrentSession.isADMIN
            [user,sys] = memory;
            Mem.MatlabUsed(ear) = user.MemUsedMATLAB/1000000;
            Mem.PhysicalMemoryAvailable(ear) = sys.PhysicalMemory.Available/1000000 ;
            Mem.VirtualAddressAvailable(ear) = sys.VirtualAddressSpace.Available/1000000 ;
            Mem.MemAvailableAllArrays(ear) = user.MemAvailableAllArrays/1000000 ;
            clear user sys
        end
        
        % Stop this face if needed :
        guiHandles = guidata(hObject);

        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Storing guiHandles']),'Success');

        if ~isempty(guiHandles) && isfield(guiHandles,'Execution') && guiHandles.Execution == 0
            
            current_process(handles,'Saving GUI data... !');
            %% Save outputs (you never know) - even if stopped :
            ToSave = handles.Outputs; %#ok<NASGU>
            save(fullfile(strcat(handles.BDD_path,'\Outputs\Session.output')),'ToSave')
            clear ToSave
            % Re-initialize handles :
            guidata(hObject,guiHandles);
            set(handles.button_stop,'Visible','Off')
            current_process(handles,'Arr�t� !');
            if strcmp(handles.WindowMode,'Expert')
                set(handles.popupmenu_faces,'Visible','On');
            end
            set(handles.txtbox_code,'Visible','Off');
            set(handles.txtbox_specific_process,'Visible','Off');
            
            % Change pointer :
            set(handles.main, 'pointer', 'arrow')
            
            % Reset figure :
            drawnow;
            
        end
        
        % Allow other interruption to fire & reset axes :
        pause(0.03);
        
        % Update handles :
        guidata(hObject,handles)

        handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Updating guidata']),'Success');
        
        % Stop if needed - out of ear :
        if ~isempty(guiHandles) && isfield(guiHandles,'Execution') && guiHandles.Execution == 0
            
            SummaryfileID = fopen(PathToSummary,'a') ;

            current_process(handles,'Saving GUI data... !');
            %% Save outputs (you never know) - even if stopped :
            ToSave = handles.Outputs; %#ok<NASGU>
            save(fullfile(strcat(handles.BDD_path,'\Session.output')),'ToSave')
            clear ToSave
            
            % Re-initialize handles :
            guidata(hObject,guiHandles);
            set(handles.button_stop,'Visible','Off')
%             current_process(handles,strcat(['Stopped :' ' ' code{1}]));
            fprintf(SummaryfileID,['Stopped at' ' ' code{1}]);
            fprintf(SummaryfileID,'\n');
            if strcmp(handles.WindowMode,'Expert')
                set(handles.popupmenu_faces,'Visible','On');
            end
            set(handles.txtbox_code,'Visible','Off');
            set(handles.txtbox_specific_process,'Visible','Off');
            
            SummaryfileID = fclose('all') ;

            % Reset pointer :
            set(handles.main, 'pointer', 'arrow')
            
            % Reset figure :
            drawnow;
            % Leave loop : 
            break;
            
        end

        % Same as above, allow everything to set up correctly
        pause(0.03);

    end
    
    handles.CurrentAuditLog.trace(strcat(['Code : ' ' ' code{1},' - ear : ', num2str(num_epi),' - Loop info - Storing guiHandles']),'Success');
        
    %% Save final pdf if needed :
    if any(FlagsToUSe(4:5))
        
        % Compute first page pdf :
        FirstpageName = get(handles.pdfname_withmask,'String');
        
        % Now put all pdfs together :
        PdfName = get(handles.pdfname_withmask,'String');
        PdfFolder = fullfile(strcat(handles.OutputPath),'PDFs');
        PdFToWrite = fullfile(strcat(handles.OutputPath,'\',PdfName));
        
        %         PdfList = cellstr(ls(fullfile(PdfFolder)));
        %         PdfList=PdfList(~ismember(PdfList,{'.','..'}));
        %         if (exist(PdfFolder,'file') == 0), mkdir(PdfFolder); end
        
        PdfList = cellstr(ls(fullfile(PdfFolder)));
        PdfList=PdfList(~ismember(PdfList,{'.','..'}));
        PdfList= fullfile(PdfFolder,PdfList);
        current_process(handles,'Concatenating pdf...');
%         append_pdfs(PdFToWrite,PdfList{:})
        
        append_pdfs(PdFToWrite,FullFileNames{:})
        
    end
    
    
    % Save if end, else initialize variable & update handles : 
    if guiHandles.Execution 
        % Export du main csv :
        
        % Reset Outputpath before : 
        
        current_process(handles,'Saving GUI data... !');
        % Save outputs (you never know) :
        ToSave = handles.Outputs; %#ok<NASGU>
        save(fullfile(strcat(handles.BDD_path,'\Session.output')),'ToSave')
        clear ToSave
            
        % Update visuals :
        current_process(handles,'Travail termin� !');
        set(handles.main, 'pointer', 'arrow')
        set(handles.button_stop,'Visible','Off');
        drawnow;
        if handles.CurrentSession.isADMIN
            handles.MemoryUse = Mem ;
            guidata(hObject,handles)
        end
        
        % Reset image bar :
        if strcmp(handles.WindowMode,'Expert')
            set(handles.popupmenu_faces,'Visible','On');
        end
        
        set(handles.txtbox_code,'Visible','Off');
        set(handles.txtbox_specific_process,'Visible','Off');
        StatusToWrite = 'Job finished in :';
        handles.CurrentAuditLog.trace(strcat([' Loop info - Execution to continue']),'Success');

    else
        guiHandles.Execution = 1;
        guidata(hObject,handles)
        StatusToWrite = 'Job stopped by user after :';
        current_process(handles,['Execution arr�t�e �',' ',code{1}]);
        handles.CurrentAuditLog.trace(strcat([' Loop info - Execution stopped']),'Success');

    end
    
    % Reupdate and clear finaly : 
    drawnow
    guidata(hObject,handles)
    pause(0.01);
    
    % Clear everything : 
    clear Done ToDo ValidEar RepToGoTo ear face UseTempFolder UseColorMask ProduceGraphs code
    
    %% Finish summary : 
    SummaryfileID = fopen(PathToSummary,'a') ;
    fprintf(SummaryfileID,'\n');    
    fprintf(SummaryfileID,'%s',['Number of ears correctly analysed :',' ',num2str(isValidEar)]);
    fprintf(SummaryfileID,'\n');
    fprintf(SummaryfileID,'%s',['Number of ears failed to analysed :',' ',num2str(isBadEar)]);
    fprintf(SummaryfileID,'\n');
    if strcmp(StatusToWrite,'Job stopped by user after :')
        fprintf(SummaryfileID,'%s',['Number of ears not analysed :',' ',num2str(length(handles.selected) - isValidEar - isBadEar)]);
        fprintf(SummaryfileID,'\n');
    end
    EndTime = datetime('now');
    Time = EndTime - StartTime;
    [h,m,s] = hms(Time);
    fprintf(SummaryfileID,'%s',['Ending time of analysis :',' ']);
    fprintf(SummaryfileID,'%s',EndTime); % datetime cant be concatenated with a string
    fprintf(SummaryfileID,'\n');    
    fprintf(SummaryfileID,[StatusToWrite ' ']);
    fprintf(SummaryfileID,[num2str(h),' ','h',' ',num2str(m),' ','min', ' ',num2str(round(s,0)), ' ' ,'sec']);
    fprintf(SummaryfileID,'\n');
    
    handles.CurrentAuditLog.trace(strcat([' Loop final info - Writing final info in summary']),'Success');

    fclose(SummaryfileID);
    
end

%% Reset set output path and window mode : 
handles.IsSetOutputPath = 0 ;
set(handles.change_mode,'Enable','On');
SwitchVisibility_OnProcess(handles,'off')

winopen(fullfile(OutputPath));

handles.CurrentAuditLog.trace(strcat([' Loop final info - All done']),'Success');

guidata(hObject,handles)

% --- Executes on button press in Global_analysis.
function new_handles = Global_analysis_Callback(hObject, handles)
% hObject    handle to Global_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Define entries to all : 

% All ears : 
% set(handles.checkbox_allears,'Value',1);
% handles = checkbox_allears_Callback(handles.checkbox_allears, [], handles);
% handles.selected
% drawnow
contents = cellstr(get(handles.listbox_ears,'String'));
handles.selected = {};
% Change cellstr to str :
for i = 1:numel(contents)
    handles.selected{i} = contents{i};
end
    

% All variables : 
set(handles.calculate_all,'Value',1);
handles = calculate_all_Callback(handles.calculate_all, [], handles);
handles.checkbox_flags;

% All files : 
set(handles.export_all,'Value',1);
handles = export_all_Callback(handles.export_all, [], handles);
handles.file_flags;

new_handles = handles ;
guidata(hObject,handles)

% --- Executes on button press in button_stop.
function button_stop_Callback(hObject, eventdata, handles) %#ok<*INUSL>
% hObject    handle to button_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Execution = 0;

guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% CHECKBOXES : 
%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in checkbox_longueur.
function checkbox_longueur_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_longueur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(1) = get(hObject,'Value');
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_longueur

% --- Executes on button press in checkbox_largeur.
function checkbox_largeur_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to checkbox_largeur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(2) = get(hObject,'Value');
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_largeur

% --- Executes on button press in checkbox_Lfert.
function checkbox_Lfert_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_Lfert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(3) = get(hObject,'Value');
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_Lfert

% --- Executes on button press in checkbox_AbortionBase.
function checkbox_AbortionBase_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_AbortionBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(4) = get(hObject,'Value');
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_AbortionBase

% --- Executes on button press in checkbox_AbortionAp.
function checkbox_AbortionAp_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_AbortionAp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(5) = get(hObject,'Value');
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_AbortionAp

% --- Executes on button press in checkbox_etages.
function checkbox_etages_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_etages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(6) = get(hObject,'Value');
guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_etages

% --- Executes on button press in checkbox_rangs_B.
function checkbox_rangs_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_rangs_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(7) = get(hObject,'Value');
handles.checkbox_flags(8) = get(hObject,'Value');
handles.checkbox_flags(9) = get(hObject,'Value');

guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_rangs_B

% --- Executes on button press in checkbox_grainsize.
function checkbox_grainsize_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_grainsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(10) = get(hObject,'Value');
handles.checkbox_flags(11) = get(hObject,'Value');

guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_grainsize

% --- Executes on button press in checkbox_nbGr.
function checkbox_nbGr_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_nbGr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags(12) = get(hObject,'Value');

guidata(hObject,handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_nbGr

% --- Executes on button press in calculate_all.
function newhandles = calculate_all_Callback(hObject, eventdata, handles)
% hObject    handle to calculate_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
AllEarVarSelected = get(hObject,'Value');

if AllEarVarSelected == 1
    
    % Calculate everything & disable checkboxes : 
    handles.checkbox_flags = [1 1 1 1 1 1 1 1 1 1 1 1];
    set(handles.checkbox_nbGr,'Enable','off')
    set(handles.checkbox_grainsize,'Enable','off')
    set(handles.checkbox_etages,'Enable','off')
    set(handles.checkbox_AbortionAp,'Enable','off')
    set(handles.checkbox_AbortionBase,'Enable','off')
    set(handles.checkbox_Lfert,'Enable','off')
    set(handles.checkbox_rangs,'Enable','off')
    set(handles.checkbox_largeur,'Enable','off')
    set(handles.checkbox_longueur,'Enable','off')
    set(handles.checkbox_nbGr,'Enable','off')

else
    
    % Enabling checkboxes & get flags values : 
    set(handles.checkbox_nbGr,'Enable','on')
    set(handles.checkbox_grainsize,'Enable','on')
    set(handles.checkbox_etages,'Enable','on')
    set(handles.checkbox_rangs,'Enable','on')
    set(handles.checkbox_AbortionAp,'Enable','on')
    set(handles.checkbox_AbortionBase,'Enable','on')
    set(handles.checkbox_Lfert,'Enable','on')
    set(handles.checkbox_largeur,'Enable','on')
    set(handles.checkbox_longueur,'Enable','on')
    set(handles.checkbox_nbGr,'Enable','on')  
    
    handles.checkbox_flags = [get(handles.checkbox_longueur,'Value') ...
                              get(handles.checkbox_largeur,'Value') ...
                              get(handles.checkbox_Lfert,'Value') ...
                              get(handles.checkbox_AbortionBase,'Value') ...
                              get(handles.checkbox_AbortionAp,'Value') ...
                              get(handles.checkbox_etages,'Value') ...
                              get(handles.checkbox_rangs,'Value') ...
                              get(handles.checkbox_rangs,'Value') ...
                              get(handles.checkbox_rangs,'Value') ...
                              get(handles.checkbox_grainsize,'Value') ...
                              get(handles.checkbox_grainsize,'Value') ...
                              get(handles.checkbox_nbGr,'Value') ];

end

newhandles = handles;

guidata(hObject, handles);
drawnow

% --- Executes on button press in export_all.
function newhandles = export_all_Callback(hObject, eventdata, handles)
% hObject    handle to calculate_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
AllFilesSelected = get(hObject,'Value');

if AllFilesSelected == 1
    
    % Calculate everything & disable checkboxes : 
    handles.file_flags = [1 1 1 1 0] ;
    set(handles.file_DiameterAlongLength,'Enable','off')
    set(handles.file_FillAlongEarLength,'Enable','off')
    set(handles.file_grainsizealongear,'Enable','off')
    set(handles.image_mask,'Enable','off')
%     set(handles.image_nomask,'Enable','off')
    
    % Set visible file names : 
    set(handles.csvname_diam,'Visible','on')
    set(handles.csvname_earfilling,'Visible','on')
    set(handles.csvname_graindim,'Visible','on')
    set(handles.pdfname_withmask,'Visible','on')
%     set(handles.pdfname_nomask,'Visible','on')

else
    
    % Enabling checkboxes & get flags values : 
    set(handles.file_DiameterAlongLength,'Enable','on')
    set(handles.file_FillAlongEarLength,'Enable','on')
    set(handles.file_grainsizealongear,'Enable','on')
    set(handles.image_mask,'Enable','on')
%     set(handles.image_nomask,'Enable','on')
    
    % Set file flags : 
    handles.file_flags = [get(handles.file_DiameterAlongLength,'Value') ...
        get(handles.file_FillAlongEarLength,'Value') ...
        get(handles.file_grainsizealongear,'Value') ...
        get(handles.image_mask,'Value') ...
        get(handles.image_nomask,'Value') ];
    
    
    %% To replace : 
    % Set visibility : 
    if handles.file_flags(1)
        set(handles.csvname_diam,'Visible','on')
    else
        set(handles.csvname_diam,'Visible','off') 
    end
    
    if handles.file_flags(2)
        set(handles.csvname_earfilling,'Visible','on')
    else
        set(handles.csvname_earfilling,'Visible','off') 
    end
    
    if handles.file_flags(3)
        set(handles.csvname_graindim,'Visible','on')
    else
        set(handles.csvname_graindim,'Visible','off') 
    end
    
    if handles.file_flags(4)
        set(handles.pdfname_withmask,'Visible','on')
    else
        set(handles.pdfname_withmask,'Visible','off') 
    end
    
%     if handles.file_flags(5)
% %         set(handles.pdfname_nomask,'Visible','on')
%         
%     else
% %         set(handles.pdfname_nomask,'Visible','off') 
%     end
    


end

newhandles = handles; 

guidata(hObject, handles);

% --- Executes on button press in checkbox_allears.
function newhandles = checkbox_allears_Callback(hObject, eventdata, handles)

if handles.AllEarSelected == 1
    handles.AllEarSelected = 0;
    sizeOfListBox = numel(get(handles.listbox_ears, 'String'));
    set(handles.listbox_ears,'value',repelem(2,sizeOfListBox));
    set(handles.listbox_ears,'Enable','On');
    set(handles.listbox_ears,'BackGroundColor','Black')

    % selected : 
    handles.selected = {};
    selectedears = 1 ; 
else
    handles.AllEarSelected = 1;
    sizeOfListBox = numel(get(handles.listbox_ears, 'String'));
    set(handles.listbox_ears,'value',repelem(1,sizeOfListBox)); 
    set(handles.listbox_ears,'Enable','Off');
    set(handles.listbox_ears,'BackGroundColor',[0;170/255;0])
    
    % Make the selected ears accordingly : 
    selectedears = sizeOfListBox ; 
    contents = cellstr(get(handles.listbox_ears,'String'));
    handles.selected = {};
    idx = get(handles.listbox_ears,'Value');
    % Change cellstr to str : 
    for i = 1:numel(idx)
        handles.selected{i} = contents{i};
    end

end

% Make the choosing face possible or not : 
if selectedears == 1
    set(handles.popupmenu_faces,'Enable','On')
else 
    set(handles.popupmenu_faces,'Enable','Off')
end

newhandles = handles;

guidata(hObject, handles);
drawnow

% --- Executes on button press in checkbox_computing.
function checkbox_computing_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_computing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_computing
if get(hObject,'Value')==1
    
    computing = 'parallel';
else
    
    computing = 'classic';
end

handles.computing = computing ; 

guidata(hObject,handles);

% end checkboxes

% ------------------------------------------------------------
% ------------------------------------------------------------

% Begin Others :

function Session_Name_Callback(hObject, eventdata, handles)
% hObject    handle to Session_Name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Session_Name as text
%        str2double(get(hObject,'String')) returns contents of Session_Name as a double
set(hObject,'String',handles.session_name)

guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function Session_Name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Session_Name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in listbox_ears.
function listbox_ears_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_ears (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%To put in the segmentation choice :  
Version_Seg = get(handles.Segmentation_Version,'String');
if strcmp(Version_Seg,'v1.0 - Empiric Segmentation')
    Segmentation = 'New';
else
    Segmentation = 'New';
end
% Get colormask :
if get(handles.colormaskvalue,'Value') == 1
    UseColorMask = true;
else
    UseColorMask = false;
end
    

contents = cellstr(get(hObject,'String'));
handles.selected = {};
idx = get(hObject,'Value');

% Make the choosing face possible or not : 
if length(idx) == 1
    set(handles.popupmenu_faces,'Enable','On')
else 
    set(handles.popupmenu_faces,'Enable','Off')
end

% Change cellstr to str : 
for i = 1:numel(idx)
    handles.selected{i} = contents{idx(i)};
end

if ~isempty(handles.selected)
    
    if ~isempty(handles.selected(1))
        RepToGoTo = strcat(handles.data_Path,'\',handles.selected{1},'\',int2str(handles.selected_face),'\','RGB.png');
        if exist(RepToGoTo,'file')
            
%             set(handles.Axes_CurrentEar,'Visible','On');
            axes(handles.Axes_CurrentEar)
            matlabImage = imread(fullfile(RepToGoTo)); % A changer !
            image(matlabImage)
            axis off
            axis image
            
            clear matlabImage
        end
                
    end
    
    % Test wether there is smth to show 
    % make it a function ! 
    if length(handles.selected) > 1 
        
        reset_visualizeear(handles)
        set(handles.Visualiser_Resultats,'Visible','Off')

    end
    
    if ~isempty(handles.selected(1)) 

        RepToGoTo = strcat(handles.data_Path,'\',handles.selected{1},'\',int2str(handles.selected_face),'\','EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg');

        if exist(RepToGoTo,'file')==2

            set(handles.Visualiser_Resultats,'Visible','On')
            handles.RepToHereToViualize = RepToGoTo; 

        else
            set(handles.Visualiser_Resultats,'Visible','Off')
            handles.RepToHereToViualize = 'None';         

        end
        
    end
end

guidata(hObject,handles)
% Hints: contents = cellstr(get(hObject,'String')) returns listbox_ears contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_ears

% --- Executes during object creation, after setting all properties.
function listbox_ears_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_ears (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in listbox ears : change visibility of
% faces / change shown ear. 
function popupmenu_faces_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_faces (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%To put in the segmentation choice :  
Version_Seg = get(handles.Segmentation_Version,'String');
if strcmp(Version_Seg,'v1.0 - Empiric Segmentation')
    Segmentation = 'New';
else
    Segmentation = 'New';
end
% Get colormask :
if get(handles.colormaskvalue,'Value') == 1
    UseColorMask = true;
else
    UseColorMask = false;
end

handles.selected_face = get(hObject,'Value');

if ~isempty(handles.selected)

    if ~isempty(handles.selected(1))
        
        RepToGoTo = strcat(handles.data_Path,'\',handles.selected{1},'\',int2str(handles.selected_face),'\','RGB.png');
        if exist(RepToGoTo,'file')
%             set(handles.Axes_CurrentEar,'Visible','On');
            axes(handles.Axes_CurrentEar)
            matlabImage = imread(fullfile(RepToGoTo)); % A changer !
            image(matlabImage)
            axis off
            axis image
            
            clear matlabImage
        end
                

    end

    % Test wether there is smth to show 
    % make it a function ! 
    
    RepToGoTo = strcat(handles.data_Path,'\',handles.selected{1},'\',int2str(handles.selected_face),'\','EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg');
    
    if exist(RepToGoTo,'file')
    
        set(handles.Visualiser_Resultats,'Visible','On')
        handles.RepToHereToViualize = RepToGoTo; 
    else
        handles.RepToHereToViualize = 'None';
        set(handles.Visualiser_Resultats,'Visible','Off')
    end
    
    
end


guidata(hObject,handles)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_faces contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_faces

% --- Executes during object creation, after setting all properties.
function popupmenu_faces_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_faces (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% end others

% ------------------------------------------------------------
% ------------------------------------------------------------

% Begin Debug :

% --- Executes on button press in DEBUG_keyboard.
function DEBUG_keyboard_Callback(hObject, eventdata, handles)
% hObject    handle to DEBUG_keyboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
keyboard;

% --- Executes on button press in DEBUG_handles.
function DEBUG_handles_Callback(hObject, eventdata, handles)
% hObject    handle to DEBUG_handles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles %#ok<NOPRT>

% --- Executes on button press in DEBUG_checkflags.
function DEBUG_checkflags_Callback(hObject, eventdata, handles)
% hObject    handle to DEBUG_checkflags (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.checkbox_flags

% --- Executes on button press in Visualiser_Resultats.
function Visualiser_Resultats_Callback(hObject, eventdata, handles)
% hObject    handle to Visualiser_Resultats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.selected)
    [codes,nears] = separate_earcode(handles.selected{1} ); % filename parser
    
    string_name = strcat([codes '_Epi' num2str(nears) '_face' num2str(handles.selected_face)]);
    % Add phymea image :
    FigResults = figure('Name',string_name,'Visible','on');
    try
        
        matlabImage = imread(fullfile(handles.RepToHereToViualize)); % A changer !
        image(matlabImage)
        axis off
        axis image
        drawnow
        truesize(FigResults)
        
    catch
        
    end
    
    
    clear matlabImage
end
%%%%%%%%%%%%%%%%%%%%%%%%
%% WaitBar & String : %%
%%%%%%%%%%%%%%%%%%%%%%%%

function resetwaitbar(handles)

set(handles.axes_processing,'Xtick',[],'Ytick',[],'Xlim',[0 1],'Ylim',[0 1],'box','on','Visible','On')

axes(handles.axes_processing);
rectangle('Position',[0,0,1,1],'FaceColor','black','Parent',handles.axes_processing);
drawnow

function reset_visualizeear(handles)

set(handles.Axes_CurrentEar,'Xtick',[],'Ytick',[],'Xlim',[0 1],'Ylim',[0 1],'box','off')

axes(handles.Axes_CurrentEar);
rectangle('Position',[0,0,1,1],'FaceColor','black','EdgeColor','black','Parent',handles.Axes_CurrentEar);
set(handles.Axes_CurrentEar,'Visible','Off');

drawnow

function updatewaitbar(handles,value)

% Value should be between 0 and 1 ! 
axes(handles.axes_processing);
value = min(max(value, 0),1);
set(handles.axes_processing,'Xtick',[],'Ytick',[],'Xlim',[0 1],'Ylim',[0 1],'box','on','Visible','On')
rectangle('Position',[0,0,value,1],'FaceColor','b','Parent',handles.axes_processing);
% Enregistrer le retour de ce truc la et voir si je peux le clear derriere%

drawnow

function current_process(handles,string)

set(handles.Process_txtbox,'String',string)
drawnow

function current_specific_process(handles,string)

set(handles.txtbox_specific_process,'Visible','on')
set(handles.txtbox_specific_process,'String',string)

drawnow

function update_specific_process(handles,task)

current_specific_process(handles,task);

drawnow

function update_show_run(handles,task,value,NumSteps)

ValueToWrite = num2str(round(value/NumSteps*100,2));
stringToWrite = strcat(task,' ',ValueToWrite,'%');
updatewaitbar(handles,round(value/NumSteps,2));
current_process(handles,stringToWrite);
drawnow

%%%%%%%%%%%%%%%%%%%
%% Ear masking : %%
%%%%%%%%%%%%%%%%%%%

function [Results] = ear_masking(handles,BDD_path,photodir)

% Reset the processing axes : 
current_process(handles,'Lancement d�coupage...');
updatewaitbar(handles,0);

workdir = BDD_path ;

% Trace masking : 
handles.CurrentAuditLog.trace(['Launching ear masking process from' ' ' workdir],'Success'); 

% check if directory still exists : 
if ~exist(photodir, 'dir')
    handles.CurrentAuditLog.trace(['Ear masking process stopped' ' ' workdir ' ' 'unreachable'],'Fail'); 
    return
end
    
% Get list of codes (filenames) : 
dpath = readDirectory(workdir,photodir);
fnames = ls([workdir '/image_lists']);
fnames_cells = cellstr(fnames);
fnames=fnames_cells(~ismember(fnames_cells,{'.','..'}));

if exist(fullfile(workdir, 'codelist'),'file')
    earsDone = fileread(fullfile(workdir, 'codelist'));
    handles.CurrentAuditLog.trace('Reading codelist','Success'); 
else
    fid = fopen(fullfile(workdir, 'codelist'),'w');
    handles.CurrentAuditLog.trace('Writing codelist','Success'); 
    fclose(fid);
    earsDone = fileread(fullfile(workdir, 'codelist'));
    handles.CurrentAuditLog.trace('Reading codelist','Success'); 
end

% Variables to keep earsdone and ears treated per plot :
Results = struct();
Results.ImageNames = fnames;
Results.Codes_Done = zeros(1,numel(fnames));
Results.Image(1:numel(fnames)) = struct();
NumSteps = numel(fnames);
update_show_run(handles,'D�coupage des �pis... ',0,NumSteps)

% To do for each file : 
for ii = 1:numel(fnames)
   
    % Separate code and assume 3 ears :
    [codes,nears] = separate_codes(strtrim(fnames{ii})); % filename parser
    handles.CurrentAuditLog.trace(['Separating codes for' ' ' fnames{ii}],'Success'); 

    % Get exif data for specific file : 
    
    
    % If already masked, continue to next ear :
    if ~isempty(earsDone)
        if strfind(earsDone,strjoin(codes(:),'\n'))
            continue
        end
    end
    

    % masking for all ear faces :
    badcodefound = false;
    for face = 1:6
        
        % Try masking first and stock metadata :
        try
            if regexp(strtrim(fnames{ii}),'\d{1}U@*')
                phototype = 'U';
                [Old,New,ROIs,positions,TLcorners,valid,nameatpos,ImInfo] = masknpos_ears(fullfile(dpath,['I' num2str(face) strtrim(fnames{ii}) '.jpeg']),codes,nears,phototype); % image masking
                
                MetaData = ImInfo;
            else
                phototype = 'M';
                [Old,New,ROIs,positions,TLcorners,valid,nameatpos,ImInfo] = masknpos_ears(fullfile(dpath,['I' num2str(face) 'xM@' strtrim(fnames{ii}) '.jpeg']),codes,nears,phototype); % image masking
                MetaData = ImInfo;
            end
            handles.CurrentAuditLog.trace(['Separating ear on image' ' ' fnames{ii} ' face' ' ' num2str(face)],'Success');
        catch
            fprintf('Problem with earmasking %s , skipped.\n', fnames{ii});
        end
                
        
        %Rewrite ear codes depending on positions and nears :
        nears_corrected = numel(positions);
        Results.Image(ii).Nears(face) = nears_corrected;

%         Make the big folders for each ear when needed depending on ear
%         numbers :
        try
            k=1;
            for ear = 1:nears_corrected
                position = positions(ear);
                if strcmp(phototype,'M')
                    [~,~,messid] = mkdir(fullfile(workdir, 'data' ,codes{k}, num2str(face)));
                else
                    [~,~,messid] = mkdir(fullfile(workdir, 'data' ,codes{position}, num2str(face)));
                end
                k=k+1; 
                % If rep already exists, new code / rep with a x1 ... ?
                % Until infinity ! ==> Not anymore, i'm not sure we need it
                % in the new version ? 
                if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
                    handles.CurrentAuditLog.trace(['Creating image folder ' ' ' fnames{ii} ' face' ' ' num2str(face)],'Fail');
                    old_code = codes{ear};
                    new_code = codes{ear};
%                     new_code = new_code(1:end);
                    new_code = strcat(new_code,'x1');
                    codes{ear} = new_code;
                    % Do same for nameatpos : 
                    for name= 1:numel(nameatpos)
                        if strcmp(nameatpos{name},old_code)
                           nameatpos{name}={codes{ear}};
                        end
                    end
                    
%                     nameatpos{ear}={new_code};
                    mkdir(fullfile(workdir, 'data' ,new_code, num2str(face)));
                end
                handles.CurrentAuditLog.trace(['Creating image folder ' ' ' fnames{ii} ' face' ' ' num2str(face)],'Success');
                
            end
        catch
            fprintf('Problem with number of ear correspondance for %s, side %s skipped.\n', fnames{ii}, num2str(face));
            continue
        end
        
        % Write masked images in folders :
        % There is a redo between 'codes' and nameatpos !
        Result = 0 ; 
        
        if all(valid)
            
            Result = writeEarImages(workdir,dpath,strtrim(fnames{ii}),face,nameatpos,ROIs,positions,TLcorners,ImInfo);
            handles.CurrentAuditLog.trace(['Writing ear images' ' ' fnames{ii} ' face' ' ' num2str(face)],'Success');
            
        else
            badcodefound=true;
            % Add something to stock it ! 
        end

        % Increment Wait Bar (we dont care if 1 or 2 or 3 ears, depends only on fnames and faces : 
        step = (ii-1) + (face/6);
        update_show_run(handles,'Decoupage des epis... ' ,step,NumSteps);

    end
    
    Results.Image(ii).nEars = mean(Results.Image(ii).Nears(:));

    if ~badcodefound
        fid = fopen(fullfile(workdir, 'codelist'),'a');
        fprintf(fid,'%s\n', codes{:});
        fclose(fid);
    end

    Results.Codes_Done(ii) = 1;
    
    % Update in handles (& Maybe save outputs to be sure EarsDone is taken into acount ) : 
    handles.CurrentSession.Masking.Results = Results ; 
    % Once updated save it for future use : 
    CurrentSession = handles.CurrentSession;
    CurrentSession.isADMIN = 0;
    save(fullfile(strcat(handles.CurrentSession.Session_Path,'\','Info.session')),'CurrentSession');
    handles.CurrentAuditLog.trace(strcat(handles.CurrentSession.SessionName,'.session SAVE'),'Success');
    
end

update_show_run(handles,'D�coupage termin�, vous pouvez lancer une analyse !',1,1);
handles.CurrentAuditLog.trace('Masking task','Success')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Listening and managing : %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function main_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to main (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

 keyPressed = eventdata.Key;
 if strcmp(keyPressed,'P')
         prompt = {'Password ? (0/1)'};
    UseTempFolder = inputdlg(prompt);
    UseTempFolder = UseTempFolder{1};
 end
 
guidata(hObject, handles);

function Password_Callback(hObject, eventdata, handles)

if strcmp(get(hObject,'String'),'Phymea18')
    handles.CurrentSession.isADMIN = 1;
    handles.CurrentAuditLog.setLogLevel(handles.CurrentAuditLog.ALL);
else
    handles.CurrentSession.isADMIN = 0;
end

guidata(hObject, handles);

function Password_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function send_an_email_ButtonDownFcn(hObject, eventdata, handles)

% --- Executes on button press in Open_logfile.
function Open_logfile_Callback(hObject, eventdata, handles)
% hObject    handle to Open_logfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    PathToFile = fullfile(handles.BDD_path,'logs',strcat(handles.selected{1},'_',num2str(handles.selected_face),'.log'));
    
    if exist(PathToFile,'file')
        
        open(PathToFile);
        
    end
    
catch
    
end


%%%%%%%%%%%%%%%%%%%%%%%%
%% All output files : %%
%%%%%%%%%%%%%%%%%%%%%%%%

%% File choice : 
function file_DiameterAlongLength_Callback(hObject, eventdata, handles)
% hObject    handle to file_DiameterAlongLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.file_flags(1)==0
handles.file_flags(1) = 1;
set(handles.csvname_diam,'Visible','On')
else
handles.file_flags(1) =0;
set(handles.csvname_diam,'Visible','Off')
end

                    % handles.checkbox_flags =[1 1 0 0 0 0 0 0 0 0 0 0] ;
if any(handles.checkbox_flags([1 2])==0)
    handles.checkbox_flags(1) = 1;
    handles.checkbox_flags(2) = 1;
end
                    
% Hint: get(hObject,'Value') returns toggle state of file_DiameterAlongLength
guidata(hObject, handles);

function file_FillAlongEarLength_Callback(hObject, eventdata, handles)
% hObject    handle to file_FillAlongEarLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.file_flags(2)==0
handles.file_flags(2) = 1;
set(handles.csvname_earfilling,'Visible','On')
else
handles.file_flags(2) =0;
set(handles.csvname_earfilling,'Visible','Off')
end

%handles.checkbox_flags =[1 0 1 1 1 0 0 0 0 0 0 0] ;
if any(handles.checkbox_flags([1 3 4 5])==0)
    handles.checkbox_flags(1) = 1;
    handles.checkbox_flags(3) = 1;
    handles.checkbox_flags(4) = 1;
    handles.checkbox_flags(5) = 1;
end
                    
% Hint: get(hObject,'Value') returns toggle state of file_DiameterAlongLength
guidata(hObject, handles);

function file_grainsizealongear_Callback(hObject, eventdata, handles)
% hObject    handle to file_grainsizealongear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.file_flags(3)==0
handles.file_flags(3) = 1;
set(handles.csvname_graindim,'Visible','On')
else
handles.file_flags(3) =0;
set(handles.csvname_graindim,'Visible','Off')
end


% handles.checkbox_flags =[1 0 0 0 0 0 0 0 0 1 1 0] ;
if any(handles.checkbox_flags([1 10 11])==0)
    handles.checkbox_flags(1) = 1;
    handles.checkbox_flags(10) = 1;
    handles.checkbox_flags(11) = 1;    
end

% Hint: get(hObject,'Value') returns toggle state of file_DiameterAlongLength
guidata(hObject, handles);

function image_mask_Callback(hObject, eventdata, handles)
% hObject    handle to pdfname_withmask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pdfname_withmask as text
%        str2double(get(hObject,'String')) returns contents of pdfname_withmask as a double
if handles.file_flags(4)==0
handles.file_flags(4) = 1;
set(handles.pdfname_withmask,'Visible','On')
else
handles.file_flags(4) =0;
set(handles.pdfname_withmask,'Visible','Off')
end

% Hint: get(hObject,'Value') returns toggle state of file_DiameterAlongLength
guidata(hObject, handles);

function image_nomask_Callback(hObject, eventdata, handles)
% hObject    handle to pdfname_nomask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pdfname_withmask as text
%        str2double(get(hObject,'String')) returns contents of pdfname_withmask as a double
if handles.file_flags(5)==0
handles.file_flags(5) = 1;
set(handles.pdfname_nomask,'Visible','On')
else
handles.file_flags(5) =0;
set(handles.pdfname_nomask,'Visible','Off')
end

% Hint: get(hObject,'Value') returns toggle state of file_DiameterAlongLength
guidata(hObject, handles);

%% File names :  

% Callbacks : 
function csvname_diam_Callback(hObject, eventdata, handles)

handles.NameOfDiamCsv = get(handles.csvname_diam,'String');

guidata(hObject, handles);

function csvname_earfilling_Callback(hObject, eventdata, handles)

handles.NameOfEarFillCsv = get(handles.csvname_earfilling,'String');

guidata(hObject, handles);

function csvname_graindim_Callback(hObject, eventdata, handles)

handles.NameOfGrainDimCsv = get(handles.csvname_graindim,'String');

guidata(hObject, handles);

function pdfname_withmask_Callback(hObject, eventdata, handles)

handles.NameOfMaskPdf = get(handles.pdfname_withmask,'String');

guidata(hObject, handles);

function pdfname_nomask_Callback(hObject, eventdata, handles)

handles.NameOfNoMaskPdf = get(handles.pdfname_nomask,'String');

guidata(hObject, handles);

% Create fun : 
function csvname_diam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csvname_diam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function csvname_earfilling_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csvname_earfilling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function csvname_graindim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csvname_graindim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pdfname_withmask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pdfname_withmask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pdfname_nomask_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to pdfname_nomask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Output = initialialize_files(handles,Path,FlagsToUSe)

Output=struct();

%% EarDiameter : 
if FlagsToUSe(1)
    
    csvname = get(handles.csvname_diam,'String');
    Output.Path.fullDiamfilePath = fullfile(Path,csvname);
    FileId = fopen(Output.Path.fullDiamfilePath,'w');
    fprintf(FileId,'%s','Code');
    fprintf(FileId,';%s','N_Epi','Face','Position_cm','Diametre_cm');
    fprintf(FileId,'\n');
    fclose(FileId);
    
end

%% Ear filling  : 
if FlagsToUSe(2)
    
    csvname = get(handles.csvname_earfilling,'String');
    Output.Path.fullFillfilePath = fullfile(Path,csvname);
    FileId = fopen(Output.Path.fullFillfilePath,'w');
    fprintf(FileId,'%s','Code');
    fprintf(FileId,';%s','N_Epi','Face','Position_cm','Remplissage');
    fprintf(FileId,'\n');
    fclose(FileId);   
    
end

%% Grain dim : 
if FlagsToUSe(3)
    
    Type = 'byposition';
                        
    csvname = get(handles.csvname_graindim,'String');
    Output.Path.fullGrainDimfilePath = fullfile(Path,csvname);
    FileId = fopen(Output.Path.fullGrainDimfilePath,'w');
    fprintf(FileId,'%s','Code');
    
    if strcmp(Type,'bygrain')
        fprintf(FileId,';%s','N_Epi','Face','Grain','Position_x_pxl','Position_x_cm','Position_y_pxl','Grain_Width_cm','Grain_Height_cm','Cohort','Area_cm','PX2CM','EarBasePxl');
    end
    
    if strcmp(Type,'byposition')
        fprintf(FileId,';%s','N_Epi','Face','Level','PositionFromEarBase_cm','SD_PositionFromEarBase_cm','Ear_diameter_cm','Ngrain','Mean_Width_cm','SD_Width_cm','Mean_Height_cm','SD_Height_cm','Mean_Surface_cm','SD_Surface_cm','PX2CM','EarBasePxl');
    end
    
%     fprintf(FileId,';%s','N_Epi','Face','Etage moyen','Diametre moyen (cm)','Largeur moyen (cm)');
%     fprintf(FileId,';%s','N_Epi','Face','Grain','Position_x_pxl','Position_x_cm','Position_y_pxl','Grain_Width_cm','Grain_Height_cm','Threshold_Value','Area_cm','PX2CM','EarBasePxl');

    fprintf(FileId,'\n');
    fclose(FileId);   
    
end

%% Pdf Mask : 
if FlagsToUSe(4)
    

end

%% Pdf Mask : 
if FlagsToUSe(5)
    
end

function create_allfiles_Callback(hObject, eventdata, handles)
%% Button to create discretisation files : 

% Check seleted ears & flags : 
FlagsToUSe = handles.file_flags; 

if isempty(handles.selected)
    mydialog('Erreur','Veuillez s�lectionner un �pi !')
    return
end
if sum(FlagsToUSe)==0
%     mydialog('Erreur','Veuillez s�lectionner un fichier de sortie !')
    return
end


% Define paths & reset images : 
if ~handles.IsSetOutputPath
    OutputPath = define_output_path(handles);
    handles.IsSetOutputPath = 1;
    handles.OutputPath = OutputPath;
    guidata(hObject,handles);
end
resetwaitbar(handles)
reset_visualizeear(handles)

BDD_path = handles.SessionPath;
current_process(handles,'Initialisation...');
ProduceGraphs = false ; % They are normally produced beforehand or we'll deal with it after

if handles.CurrentSession.isADMIN == 1
    % Get temp folder :
    prompt = {'Use a temp folder ? (0/1)'};
    UseTempFolder = inputdlg(prompt);
    UseTempFolder = UseTempFolder{1};
else
    UseTempFolder = false ;
end

% Get colormask :
if get(handles.colormaskvalue,'Value') == 1
    UseColorMask = true;
else
    UseColorMask = false;
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% First for normal files : 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FilesStruct = initialialize_files(handles,handles.OutputPath,FlagsToUSe);
handles.CurrentAuditLog.trace('Initializing files','Success'); 


if ~isempty(handles.selected)
    
    resetwaitbar(handles)
    set(gcf,'pointer','watch')
    ToDo = length(handles.selected)*6*sum(FlagsToUSe);
    Done = 0;
    update_show_run(handles,'Export...',Done,ToDo)
    drawnow
    
    for ear = 1: length(handles.selected)
        
        code = cellstr(handles.selected{ear});
        
        [ code_epi , num_epi ] = separate_earcode( handles.selected{ear} );
  
        for face = 1 : 6
            
            %% 1) Diameter along length : 
            if FlagsToUSe(1)
                
                handles.checkbox_flags =[1 1 0 0 0 0 0 0 0 0 0 0] ;
                
                [FaceEarOutputs,~,~] = EarNormalComputing(fullfile(handles.BDD_path,'data'),handles,code,face,UseTempFolder,UseColorMask,ProduceGraphs);
                DiameterInPxL = FaceEarOutputs.EarSize.Diam.RadiusProfile(FaceEarOutputs.EarSize.EarBasePxL:FaceEarOutputs.EarSize.EarApexPxL);
                DiameterInCm = DiameterInPxL*FaceEarOutputs.EarSize.Diam.PX2CM; 
                PositionInCm = (1:length(DiameterInCm))/length(DiameterInCm)*FaceEarOutputs.EarSize.Length.Cm;
                
                % Summarize by cm : 
                k=1 ; 
                for i = 0:0.1:max(PositionInCm)-0.1
                    
                    PositionToWrite(k) = i ;
                    
                    ID = find(PositionInCm < i+0.1 & PositionInCm > i) ;
                    if ~isempty(ID)
                        DiameterToWrite(k) = mean(DiameterInCm(ID));
                        k = k+1;
                    end
                end
                
                % Write file :
                csvname = get(handles.csvname_diam,'String');
                PathToGo = fullfile(handles.OutputPath,csvname);
                fileID = fopen(PathToGo,'a');
                
                for line  = 1 : length(PositionToWrite)
                    
                    fprintf(fileID,'%s%s',code_epi,';') ;
                    fprintf(fileID,'%d%s',num_epi,';') ;
                    
                    fprintf(fileID,'%d%s',face) ;
                    fprintf(fileID,';%2.2f',round(PositionToWrite(line),2));
                    fprintf(fileID,';%2.2f',round(DiameterToWrite(line),2));
                    fprintf(fileID,'\n');
                    
                end
                
                fclose(fileID);
                
                Done = Done +1;
                update_show_run(handles,'Export des csv...',Done,ToDo)
            end

            %% 2) Ear filling along length : 
            if FlagsToUSe(2)
                
                handles.checkbox_flags =[1 0 1 1 1 0 0 0 0 0 0 0] ;
                
                [FaceEarOutputs,~,~] = EarNormalComputing(fullfile(handles.BDD_path,'data'),handles,code,face,UseTempFolder,UseColorMask,ProduceGraphs);
                
                EarToGrainRatio = FaceEarOutputs.EarSize.Abortion.ear_to_grain_ratio(FaceEarOutputs.EarSize.EarBasePxL:FaceEarOutputs.EarSize.EarApexPxL);
                PositionInCm = (1:length(EarToGrainRatio))/length(EarToGrainRatio)*FaceEarOutputs.EarSize.Length.Cm;
                
                % Summarize by cm : 
                k=1 ; 
                for i = 0:0.1:max(PositionInCm)-0.1
                    
                    PositionToWrite(k) = i ;
                    
                    ID = find(PositionInCm < i+0.1 & PositionInCm > i) ;
                    if ~isempty(ID)
                        RatioToWrite(k) = mean(EarToGrainRatio(ID));
                        k = k+1;
                    end
                end
                
                % Write file :
                csvname = get(handles.csvname_earfilling,'String');
                PathToGo = fullfile(handles.OutputPath,csvname);
                fileID = fopen(PathToGo,'a');
                
                for line  = 1 : length(PositionInCm)
                    
                    fprintf(fileID,'%s%s',code_epi,';') ;
                    fprintf(fileID,'%d%s',num_epi,';') ;
                    
                    fprintf(fileID,'%d%s',face) ;
                    fprintf(fileID,';%2.2f',round(PositionInCm(line),2));
                    fprintf(fileID,';%2.2f',round(EarToGrainRatio(line),2)*100);
                    fprintf(fileID,'\n');
                    
                end
                
                fclose(fileID);
                
                Done = Done +1;
                update_show_run(handles,'Export des csv...',Done,ToDo)
            end            
            
            %% 3) Grain dimensions with position (5cm) :
            if FlagsToUSe(3)
                
                % POSITION NOT ON THE RIGHT SIDE OF THE EAR ? %
                %fprintf(FileId,';%s','N_Epi','Face','Grain','Position (cm)','Diametre (cm)','Largeur (cm)');
                handles.checkbox_flags =[1 0 0 0 0 0 0 0 0 1 1 0] ;
                
                [FaceEarOutputs,~,~] = EarNormalComputing(fullfile(handles.BDD_path,'data'),handles,code,face,UseTempFolder,UseColorMask,ProduceGraphs);
                
                Xdim = FaceEarOutputs.GrainsAttributes.ringDimensions.GrainPosition.Xdim * FaceEarOutputs.EarSize.Length.PX2CM;
                Ydim = FaceEarOutputs.GrainsAttributes.ringDimensions.GrainPosition.Ydim * FaceEarOutputs.EarSize.Length.PX2CM;
                Position = FaceEarOutputs.GrainsAttributes.ringDimensions.GrainPosition.pos;
                Level = FaceEarOutputs.GrainsAttributes.ringDimensions.Levels ;                 
                % Write file :
                csvname = get(handles.csvname_graindim,'String');
                PathToGo = fullfile(handles.OutputPath,csvname);
                fileID = fopen(PathToGo,'a');
                
                for line  = 1 : min(length(Position),length(Level))
                                       
                    fprintf(fileID,'%s%s',code_epi,';') ;
                    fprintf(fileID,'%d%s',num_epi,';') ;
                    
                    fprintf(fileID,'%d%s',face) ;
                    
                    try 
                        fprintf(fileID,';%2.2f',Position(line));
                        fprintf(fileID,';%2.2f',round(Level(line),2));                    
                        fprintf(fileID,';%2.2f',round(Xdim(line),2));
                        fprintf(fileID,';%2.2f',round(Ydim(line),2));
                    catch
                        handles.CurrentAuditLog.trace('Writing grain dimensions',strcat(['Problem at position' ' ' num2str(Position(line)) 'cm, skipping']));
                    end
                    fprintf(fileID,'\n');
                    
                    
                end
                
                fclose(fileID);
                
                Done = Done +1;
                update_show_run(handles,'Export des csv...',Done,ToDo)
            end            
            
        end
        
    end
    handles.CurrentAuditLog.trace('Writing csv files','Success');

    clear code code_epi num_epi
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% PDF outputs of images : 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Get segmentation version : 
    % TO REMOVE FROM HERE !
    Version_Seg = get(handles.Segmentation_Version,'String');
    if strcmp(Version_Seg,'v1.0 - Empiric Segmentation')
        Segmentation = 'New';
    else
        Segmentation = 'New';
    end

    if any(FlagsToUSe(4:5))
        
        % Create folders :
        if FlagsToUSe(4)
            
            PdfFolderMask = fullfile(strcat(handles.OutputPath, '\PDFs'));
            if (exist(PdfFolderMask,'file') == 0), mkdir(PdfFolderMask); end
            
        end
        
        if FlagsToUSe(5)
            
            PdfFolderNoMask = fullfile(strcat(handles.OutputPath, '\PDFs\','NoEarMask'));
            if (exist(PdfFolderNoMask,'file') == 0), mkdir(PdfFolderNoMask); end
            
        end
       
        if ~isempty(handles.selected)
            
            resetwaitbar(handles)
            set(gcf,'pointer','watch')
            ToDo = length(handles.selected)*6*2;
            Done = 0;
            set(handles.Axes_CurrentEar,'Visible','Off');
            set(handles.popupmenu_faces,'Visible','Off');
            drawnow
            
            for ear = 1: length(handles.selected)
                
                code = cellstr(handles.selected{ear});
                
                [ code_epi , num_epi ] = separate_earcode( handles.selected{ear} );
                
                Filename = strcat(code_epi,'_Ear',num2str(num_epi));
                Filenames{ear} = strcat(Filename,'.pdf');
    
                % Make the normal A4 format :
                A4FigureLength = 1000;
                A4FigureWidth = 0.7070 * A4FigureLength;
                
                %% Step 1 : check data images 
                
                % First check if images are here, and produce if needed :
                for face = 1:6
                                        
                    % Set handles :
                    update_show_run(handles,'Export PDF, etape 1/2...',Done,ToDo)
                    Done = Done + 1 ; 
                    set(handles.Axes_CurrentEar,'Visible','Off');
                    set(handles.popupmenu_faces,'Visible','Off');
                    set(handles.txtbox_code,'Visible','on');
                    set(handles.txtbox_specific_process,'Visible','on');
                    set(handles.txtbox_code,'String',['Code : ' ' ' code{1}])
                    set(handles.txtbox_specific_process,'String',['Face : ' ' ' num2str(face)])
                    drawnow 
                    
%                     if any(FlagsToUSe(4:5))
%                         
%                         handles.checkbox_flags =[1 1 1 1 1 1 1 1 1 1 1 1] ;
%                         
%                         [~,~,~] = EarNormalComputing(fullfile(handles.BDD_path,'data'),handles,code,face,UseTempFolder,UseColorMask,FlagsToUSe(4:5));
%                         
%                     end
                    
                end
    
                %% Step 2 : Create pdf : 
                
                % Main pdf page :
                fig = figure('name',code{1},'Position',[0 0 A4FigureWidth A4FigureLength],'Visible','off'); % to change 
                hold on
                
                annotation(fig,'textbox',[0.01 0.90 0.1 0.1],'Interpreter','none',...
                    'String',strcat('Code :',' ',code{1}),...
                    'color', [0.5 0.5 0.5],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',13);
                
                annotation(fig,'textbox',[0.01 0.87 0.1 0.1],'Interpreter','none',...
                    'String',strcat('Ear N� :',' ',num2str(num_epi)),...
                    'color', [0.5 0.5 0.5],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',13);
        

                
                % Produce images on pdf :
                for face = 1:6
                    
                    % Update handles : 
                    Scaling = 0.92;
                    set(handles.popupmenu_faces,'Visible','Off');
                    set(handles.txtbox_code,'Visible','on');
                    set(handles.txtbox_specific_process,'Visible','on');
                    set(handles.txtbox_code,'String',['Code : ' ' ' code{1}])
                    set(handles.txtbox_specific_process,'String',['Face : ' ' ' num2str(face)])
                    update_show_run(handles,'Export PDF, etape 2/2...',Done,ToDo)
                    drawnow
                    
                    % Get back to fig : 
                    set(0,'CurrentFigure',fig); 
                    % Initialize axes of subplot :
                    ax = subplot('Position',[0 Scaling-((face/6)*Scaling) 1 1/6*Scaling]);
                    
                    PathToImage = strcat(handles.BDD_path,'\data\',code,'\',num2str(face),'\EarMeasurements_EarMaskon_',Segmentation,'_',num2str(UseColorMask),'.jpeg');
                    % Check existence of output png :
                    if exist(fullfile(PathToImage{1}),'file') == 2
                        
                        try
                            % Read image if exist :
                            ImageToShow = imread(fullfile(PathToImage{1}));
                            [rows, columns, numberOfColorChannels] = size(ImageToShow);
                            FigureSize = get(fig,'Position');
                            
                            imshow(imresize(ImageToShow,[(FigureSize(4)/6)*Scaling FigureSize(3)*Scaling]),'InitialMagnification','fit')
                            set(ax, 'box', 'on', 'Visible', 'on','color',[0.5 0.5 0.5], 'xtick', [], 'ytick', [])
                            handles.CurrentAuditLog.trace(strcat('Writing image in pdf for ear',code{1}),'Success');
                            Done = Done + 1 ;                   

                        catch
                            Done = Done + 1 ;                   
                            continue
                        end
                        
                    else
                        Done = Done + 1 ;
                        continue
                        
                    end
                
                    % Set handles :
                    clear ImageToShow FigureSize Scaling
                    
                end
                                
                %% Final pdf : 
                
                clear face A4FigureWidth A4FigureLength
                
                Filename = strcat(code{1},'_Ear',num2str(num_epi));
                
                Filenames{ear} = strcat(Filename,'.pdf');
                
                WhereToExport = strcat(PdfFolderMask,'\',Filenames{ear});
                export_fig(fullfile(WhereToExport),'-pdf','-c[0,0,0,0]')
                
                FullFileNames{ear} = WhereToExport;
                
                close(fig)
                clear fig
                
                update_show_run(handles,strcat(['Export pdf' ' ' ear '...']),Done,ToDo)
                
                clear Filename

            end
            
            clear code
            
        end
        
        %% Now put all pdfs together : 
        PdfName = get(handles.pdfname_withmask,'String');
        PdfFolder = fullfile(strcat(handles.OutputPath));
        PdFToWrite = fullfile(strcat(PdfFolder,'\',PdfName));
%         PdfList = cellstr(ls(fullfile(PdfFolder)));
%         PdfList=PdfList(~ismember(PdfList,{'.','..'}));
%         if (exist(PdfFolder,'file') == 0), mkdir(PdfFolder); end
        
        % TO REMOVE ABSOLUTELY !
        current_process(handles,'Finalisation...');
%         cd(PdfFolder)
        append_pdfs(PdFToWrite,FullFileNames{:})
        
        resetwaitbar(handles)

    end
    clear FlagsToUSe
    
    % Re-initialize handles :
    if strcmp(handles.WindowMode,'Expert')
        set(handles.popupmenu_faces,'Visible','On');
    end
    set(handles.txtbox_code,'Visible','Off');
    set(handles.txtbox_specific_process,'Visible','Off');
                
                
    current_process(handles,'Termin� !');
    set(handles.main, 'pointer', 'arrow')
    drawnow;
    
end

% Reset outputpath : 
handles.IsSetOutputPath = 0 ;
guidata(hObject,handles);

function write_eardistributionfile()






guidata(hObject,handles);

function write_csv(data,fullpath)

FileId = fopen(fullpath,'a');
fprintf(FileId,'%s','Code');
fprintf(FileId,';%s','N_Epi','Face','Position (cm)','Largeur (cm)');
fprintf(FileId,'\n');
fclose(FileId);
    
function csvname_main_Callback(hObject, eventdata, handles)

function csvname_main_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csvname_main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Output Image : 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ResultsImage = showAndSaveResultsImage(obj,gpr,EarLengthHalfImage,FigLength,Visibility,Save,EarMask,Segmentation,UseColorMask,SoftwareVersion) % 35cm

%% ToRead : 

%     FaceEarOutputs.Visual.Mask = obj.mask;
%     FaceEarOutputs.Visual.RGBImage = obj.RGBImage;
%     FaceEarOutputs.Visual.RefinedSegmentation = obj.refinedSegmentation ;
%     FaceEarOutputs.Visual.VerticalDetection = obj.verticalFileDetection.IFilesColor;
% Obj is a FaceEarOutputs struct ! 
    
% Image name :

ImageName = strcat('EarMeasurements_EarMask',EarMask,'_',Segmentation,'_',num2str(UseColorMask));

%%% Image is less than a 6th of A4 (if wants to be printed correctly)
%%% But proportions of the ear object (length/diam) in the
%%% image have to be kept for visualisation
%%% EarMaxLength determines the Ear length in cm that does 3/4 of the
%%% image length. All ears are scaled according to this value

% Set figure sizes at A4 :
FigureWidth = FigLength * 0.95 * (1/6);
FigureLength = FigLength * 0.7070 ;


PX2CM = obj.EarSize.Length.PX2CM;



% Get image size / object proportion:
ImSize = size(obj.Visual.Mask);
%             ImRatio = (ImSize(2)/ImSize(1));
EarSize = obj.EarSize.Length.Pxl*PX2CM ;
EarDiam = obj.EarSize.Diam.Pxl*PX2CM ;
ObjRatio = ImSize(2)/ ImSize(1);

% Set Image size and scaling factor of ear in image :
Scaling = EarSize/EarLengthHalfImage ;
gcaLength = FigureLength * 0.75 * (Scaling)  ;
gcaWidth = gcaLength / ObjRatio  ;

RGB = obj.Visual.RGBImage ;
Lfertile = num2str(round(obj.EarSize.Abortion.FertileZone*PX2CM,1));
Lapex = num2str(round(obj.EarSize.Abortion.ApexAbortion*PX2CM,1));
Lbase = num2str(round(obj.EarSize.Abortion.BasalAbortion*PX2CM,1));

%-------------------------------------------------------------------------%

ResultsImage = figure('Name','ResultsImage'); ...
    
set(ResultsImage,'Visible','off','InvertHardcopy','off');

hold on

set(gcf,'units','pixels','position',[50,50,FigureLength,FigureWidth],'Color',[0 0 0])

set(gca,'units','pixels',...
    'position',[(FigureLength/2)-(gcaLength/2),(FigureWidth/2)-(gcaWidth/2),gcaLength,gcaWidth],...
    'Visible','on',...
    'XLim',[0 ImSize(2)*Scaling],...
    'YLim',[0 ImSize(1)*Scaling])

% Setup  :
Xmin = 0.015 ;
Xmax = 0.76 ;
PhymeaColor = [0 0.66 0] ;

CurrentAxes = gca ;
CurrentFigure = gcf ;


% Mask :
imshow(imresize(RGB, Scaling),'Parent', gca)

%-------------------------------------------------------------------------%

% Fertile Zone + Used and unused Grains :

if strcmp(EarMask,'on')
    

    if isfield(obj.Visual,'RefinedSegmentation')
        
        SegmentedImageToShow = imerode(obj.Visual.RefinedSegmentation,strel('disk',5));
        RedSegmentation = ind2rgb(SegmentedImageToShow,[0,0,0;254,0,0]);
        him = imshow(imresize(RedSegmentation, Scaling),'Parent', gca);
        him.AlphaData = 0.3;
        
        if sum(obj.Visual.RefinedSegmentation(:)) ~= 0;
            
            SegmentedImageToShow = imerode(obj.Visual.VerticalDetection,strel('disk',5));
            GreenSegmentation = ind2rgb(SegmentedImageToShow,[0,0,0;0,254,254]);
            her = imshow(imresize(GreenSegmentation, Scaling),'Parent', gca);
            her.AlphaData = 0.6;
            
            
        end
    end
    
    

    
end

% Draw the outline of the object :
Stats = regionprops(imresize(obj.Visual.Mask, Scaling),'Boundingbox');

rectangle('Position', Stats.BoundingBox,'Parent',gca,'EdgeColor',[0,1,0]);

% Ear Length and zones :
annotation(gcf,'textbox',...
    [(CurrentAxes.Position(1)/CurrentFigure.Position(3)) 0.88 0.1 0.1],...
    'String','Ear dimensions :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);

annotation(gcf,'textbox',...
    [0.46 0.77 0.1 0.1],...
    'String',strcat('L_{ear}= ',num2str(round(EarSize,1)),'cm '),...
    'color', PhymeaColor,'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);


%-------------------------------------------------------------------------%

% Three zones along the ear  :


% Verifier si on parle bien du bon endroit sur l'�pi : 
ApexEpi = (1-(find(sum(obj.Visual.Mask),1,'last')/length(obj.Visual.Mask)))*Scaling  ;
BaseEpi = (find(sum(obj.Visual.Mask),1,'first')/length(obj.Visual.Mask))*Scaling ;
Base = (obj.EarSize.Abortion.BasalAbortion/length(obj.Visual.Mask))*Scaling*0.75 ;
Apical =  (obj.EarSize.Abortion.ApexAbortion/length(obj.Visual.Mask))*Scaling*0.75;


Xlength = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi...
    (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi] ;
Ylength = [ (CurrentAxes.Position(2)+CurrentAxes.Position(4))/CurrentFigure.Position(4)...
    (CurrentAxes.Position(2)+CurrentAxes.Position(4))/CurrentFigure.Position(4)] ;

% Small bars for cutting the rectangle (Abortion) :
YsmallBars = [(CurrentAxes.Position(2)+CurrentAxes.Position(4))/CurrentFigure.Position(4)...
    CurrentAxes.Position(2)/CurrentFigure.Position(4)] ;

annotation(gcf,'doublearrow',Xlength,[0.7 0.7],'color', PhymeaColor,'HeadStyle','hypocycloid');

if isnan(Base) || isnan(Apical)
    
    % Lines
    X = [0.5 0.5];
    annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');
    
    % Text :
    annotation(gcf,'textbox',[.45 .15 .1 .1],'String','No fertile zone','color', [1 0 0 ],...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none');
    annotation(gcf,'textbox',[.3 .15 .1 .1],...
        'String',strcat('L_{apex}= ',num2str(round(EarSize/2,1)),'cm'),'color', PhymeaColor,...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    annotation(gcf,'textbox',[.6 .15 .1 .1],...
        'String',strcat('L_{base}= ',num2str(round(EarSize/2,1)),'cm'),'color', PhymeaColor,...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    
    
else
    
    % Lines
    X = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical...
        (CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical] ;
    annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');
    
    X = [(CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base...
        (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base] ;
    annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');
    
    
    % Text :
    annotation(gcf,'textbox',[.45 .1 .1 .1],'String',...
        strcat('L_{fertile}',{' '},'=',{' '},Lfertile,'cm'),...
        'color', PhymeaColor,'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    annotation(gcf,'textbox',[.3 .1 .1 .1],...
        'String',strcat('L_{apex}',{' '},'=',{' '},Lapex,'cm'),'color', PhymeaColor,...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','EdgeColor','none','FontSize',12);
    annotation(gcf,'textbox',[.6 .1 .1 .1],...
        'String',strcat('L_{base}',{' '},'=',{' '},Lbase,'cm'),'color', PhymeaColor,...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','EdgeColor','none','FontSize',12);
    
end

% Annotate diameter :
HalfDiameter = (obj.EarSize.Diam.Pxl/ImSize(1))* (gcaWidth/FigureWidth) /2 ;
Xdiam = [0.5+(gcaLength/(2*FigureLength)) 0.5+(gcaLength/(2*FigureLength))  ] ;
Ydiam = [ 0.5-HalfDiameter 0.5+HalfDiameter   ] ;
annotation(gcf,'doublearrow',Xdiam,Ydiam,'color', PhymeaColor,'HeadStyle','hypocycloid');
annotation(gcf,'textbox',[0.5+(gcaLength/(2*FigureLength)) 0.46 .1 .1],...
    'String',strcat('D_{max}',{' '},'=',{' '},num2str(round(EarDiam,1)),'cm'),...
    'color', PhymeaColor,'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);

%-------------------------------------------------------------------------%
% Grain size :

annotation(gcf,'rectangle',[Xmin+0.005 0.05 0.2 0.3],'color', [0 0.66 0],'FaceColor', [0.5 0.5 0.5],'FaceAlpha',0.3 )
annotation(gcf,'textbox',[Xmin 0.35 0.1 0.1],...
    'String','Average ear grain dimensions :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',11);

annotation(gcf,'rectangle',[Xmax+0.005 0.05 0.2 0.3],'color', [0 0.66 0],'FaceColor', [0.5 0.5 0.5],'FaceAlpha',0.3)
annotation(gcf,'textbox',[Xmax 0.35 0.1 0.1],...
    'String','Ear grain organisation :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',11);

% Orientation :
if isnan(Base) || isnan(Apical) || isempty(obj.GrainsAttributes.ringDimensions) || ~isfield(obj.GrainsAttributes.ringDimensions,'Ydim') || ~isfield(obj.GrainsAttributes.ringDimensions,'Xdim')  
    
    annotation(gcf,'textbox',[0.025 0.175 0.1 0.1],...
        'String','Probably no kernel','color', [1 0 0],...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    annotation(gcf,'textbox',[Xmax+0.01 0.175 0.1 0.1],...
        'String','Probably no kernel','color', [1 0 0],...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    
else
    
    Largeur=round(obj.GrainsAttributes.ringDimensions.G_l*obj.GrainsAttributes.ringDimensions.PX2CM,2); 
    Longueur=round(obj.GrainsAttributes.ringDimensions.G_L*obj.GrainsAttributes.ringDimensions.PX2CM,2);
    NbRanks = num2str(round(obj.EarOrganisation.Ranks.Mid_,1));
    
    % Choose between new and ols calculation ? 
    NbGpR = num2str(round(gpr,1)); % New calculation ? 
    
    % Values :
    annotation(gcf,'textbox',[Xmin+0.005 0.23 0.1 0.1],...
        'String',strcat('Grain_{length}= ',num2str(round(Largeur,2)),'cm'),'color', [0 0.66 0],...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    annotation(gcf,'textbox',[Xmin+0.005 0.11 0.1 0.1],...
        'String',strcat('Grain_{width}',{' '},'=',{' '},num2str(round(Longueur,2)),'cm'),'color', [0 0.66 0],...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    
    annotation(gcf,'textbox',[Xmax+0.005 0.07 0.1 0.1],...
        'String',strcat('Grain number',{' '},'=',{' '},num2str(round(obj.GrainsAttributes.NbGr,0))),...
        'color', [0 0.66 0],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    annotation(gcf,'textbox',[Xmax+0.005 0.17 0.1 0.1],...
        'String',strcat('Ranks in mid zone',{' '},'=',{' '},NbRanks),'color', [0 0.66 0],...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    annotation(gcf,'textbox',[Xmax+0.005 0.26 0.1 0.1],...
        'String',strcat('Grains per rank',{' '},'=',{' '},NbGpR),'color', [0 0.66 0],...
        'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',12);
    
end


%-------------------------------------------------------------------------%
% Date and Time / Ear / Face :

Code = obj.code;
Num_Face = num2str(obj.face);
t = datetime('now');

% Ear details :
annotation(gcf,'textbox',[Xmin 0.98-0.07 0.1 0.1],...
    'String',strcat('Ear code :',{' '},Code),...
    'color', [1 1 1],'FitBoxToText','on','EdgeColor','none','color', [0.6 0.6 0.6],'Interpreter', 'none','FontSize',10);
annotation(gcf,'textbox',[Xmin 0.98-0.15 0.1 0.1],...
    'String',strcat('Face ',{' '},Num_Face),...
    'color', [1 1 1],'FitBoxToText','on','EdgeColor','none','color', [0.6 0.6 0.6],'Interpreter', 'none','FontSize',10);

% Image details :
annotation(gcf,'textbox',[Xmax-0.085 0.98-0.07 0.1 0.1],...
    'String',strcat('Time of analysis :',{' '},char(t)),'color', [0.6 0.6 0.6],'FitBoxToText','on','EdgeColor','none','Interpreter', 'none','FontSize',12);
annotation(gcf,'textbox',[Xmax-0.085 0.98-0.15 0.1 0.1],...
    'String',['Zea Analyser ' SoftwareVersion],'color', [0.6 0.6 0.6],'FitBoxToText','on','EdgeColor','none','Interpreter', 'none','FontSize',12);

% Ear preview :
% set(ResultsImage,'Visible','on');
Thumbnail = 0.225 ;
if strcmp(EarMask,'on')
    
    Length_icon = Thumbnail*CurrentFigure.Position(3);
    Width_icon = Length_icon /  ObjRatio;
    axes2 = axes('Parent',gcf,'OuterPosition',[0 0.85-Width_icon/CurrentFigure.Position(4) Length_icon/CurrentFigure.Position(3) Width_icon/CurrentFigure.Position(4)]);
    imshow(imresize(RGB, Scaling),'Parent', axes2)
    
end


hold off


if strcmp(Save,'on')
    img = getframe(ResultsImage);
%     imwrite(img.cdata, [strcat(fullfile(obj.dpath,obj.code,num2str(obj.face)),'\',ImageName,'.png')]);
    imwrite(img.cdata,[strcat(fullfile(obj.dpath,obj.code,num2str(obj.face)),'\',ImageName,'.jpeg')],'jpeg','Quality',100);
end

close(ResultsImage)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Color mask and segmentation : 

% --- Executes on selection change in colormaskvalue.
function colormaskvalue_Callback(hObject, eventdata, handles)
% hObject    handle to colormaskvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.CurrentColorMask = hObject.Value;
% Hints: contents = cellstr(get(hObject,'String')) returns colormaskvalue contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colormaskvalue
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function colormaskvalue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to colormaskvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in Segmentation_Version.
function Segmentation_Version_Callback(hObject, eventdata, handles)
% hObject    handle to Segmentation_Version (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.SegmentationVersion = hObject.Value;
guidata(hObject,handles);

% Hints: contents = cellstr(get(hObject,'String')) returns Segmentation_Version contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Segmentation_Version

% --- Executes during object creation, after setting all properties.
function Segmentation_Version_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segmentation_Version (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in reanalysis.
function reanalysis_Callback(hObject, eventdata, handles)
% hObject    handle to reanalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if hObject.Value==1;
    Answer = questdlg(['L''utilisation de cette option enta�ne la r�analyse des donn�es de cette session pour les param�tres d''analyse actuels'   sprintf('\n')  'Si vous cliquez sur oui, l''analyse peut prendre beaucoup de temps.'   sprintf('\n')  'Voulez-vous valider votre choix ?'], 'Attention! ', 'Oui', 'Non','Non');
    if strcmp(Answer,'Non')
        set(handles.reanalysis,'Value',0);
        guidata(hObject,handles);
        return
    end
end    

% Hint: get(hObject,'Value') returns toggle state of reanalysis
handles.ReAnalysisValue = hObject.Value;
guidata(hObject,handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EAR SEARCHING AND TREATING CODES AND NUMBERS : 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in Search_Ear.
function Search_Ear_Callback(hObject, eventdata, handles)
% hObject    handle to Search_Ear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompt = {'Entrer le code ou l''expression r�guli�re (ex : WD) recherch�  :'};
dlgtitle = 'Recherche de code';
dims = [1 35];
definput = {'Code'};
answer = inputdlg(prompt,dlgtitle,dims,definput);
listboxelements = get(handles.listbox_ears,'String');

%% Handles password : 
if ~isempty(answer)
    
    if strcmp(answer,'I-Am-Phymea')
        handles.CurrentSession.isADMIN = 1;
        handles.CurrentAuditLog.setLogLevel(handles.CurrentAuditLog.ALL);
        set(handles.Open_logfile,'Visible','on');
        guidata(hObject,handles);
        
    else
%         handles.CurrentSession.isADMIN = 0;
    end
    
    % Qui est selectionn� :
    SelectedIDs = [];
    for i = 1:length(listboxelements)
        
        [startIndex] = regexp(listboxelements{i},answer);
        
        if ~isempty(startIndex{1})
            SelectedIDs = [SelectedIDs i];
        end
        
    end
    
    
    if ~isempty(SelectedIDs)
        
        SelectedStrings= cell(1,length(SelectedIDs));
        for i = 1: length(SelectedIDs)
            SelectedStrings{i} = listboxelements{i};
            
        end
        
        handles.selected = SelectedStrings ;
        guidata(hObject,handles);
        
        set(handles.listbox_ears,'Value',[SelectedIDs])
    end
    
end

function EarCodesAndNum = get_ear_infos(Earlist)


Sorted_earlist = sort(Earlist);
EarCodesAndNum = struct();
EarCodesAndNum.Codes = cell(1,length(Sorted_earlist));
EarCodesAndNum.Num = zeros(1,length(Sorted_earlist));
EarCodesAndNum.Sorted_earlist = Sorted_earlist;

% For now position is empty :
EarCodesAndNum.Position = cell(1,length(Sorted_earlist));

earnum = 1;
for ear = 1:length(Sorted_earlist)
    SplittedCode = strsplit(Sorted_earlist{ear},'.');
    EarCodesAndNum.Codes{ear}=SplittedCode{1};
    if ear == 1
        EarCodesAndNum.Num(ear)=earnum;
    else
        if length(SplittedCode)==1
            EarCodesAndNum.Num(ear)=1;
        elseif strcmp(EarCodesAndNum.Codes{ear},EarCodesAndNum.Codes{ear-1})
            earnum = earnum + 1;
        else
            earnum=1;
        end
        EarCodesAndNum.Num(ear)=earnum;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Dealing with changing modes (Expert / Normal in the GUI :
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newhandles = Stock_Positions(hObject,handles)

%% Bottom left : 
handles.main_InitialPosition = get(handles.main,'Position');
handles.axis_logo_InitialPosition = get(handles.axis_logo,'Position');
handles.text32_InitialPosition = get(handles.text32,'Position');
handles.text35_InitialPosition = get(handles.text35,'Position');
handles.text36_InitialPosition = get(handles.text36,'Position');
handles.text37_InitialPosition = get(handles.text37,'Position');
handles.txtbox_code_InitialPosition = get(handles.txtbox_code,'Position');
handles.txtbox_specific_process_InitialPosition = get(handles.txtbox_specific_process,'Position');
handles.axes_processing_InitialPosition = get(handles.axes_processing,'Position');
handles.pushbutton_treatment_InitialPosition = get(handles.pushbutton_treatment,'Position');
handles.button_stop_InitialPosition = get(handles.button_stop,'Position');
handles.Process_txtbox_InitialPosition = get(handles.Process_txtbox,'Position');

%% top-right :
handles.text29_InitialPosition = get(handles.text29,'Position');
handles.Segmentation_Version_InitialPosition = get(handles.Segmentation_Version,'Position');
handles.colormaskvalue_InitialPosition = get(handles.colormaskvalue,'Position');
handles.change_mode_InitialPosition = get(handles.change_mode,'Position');
handles.axes_processing_InitialPosition = get(handles.axes_processing,'Position');
handles.txtbox_specific_process_InitialPosition = get(handles.txtbox_specific_process,'Position');
handles.txtbox_code_InitialPosition = get(handles.txtbox_code,'Position');

%% Session info : 
handles.Session_Name_InitialPosition = get(handles.Session_Name,'Position');
handles.text3_InitialPosition = get(handles.text3,'Position');
handles.pushbutton_treatment_InitialPosition = get(handles.pushbutton_treatment,'Position');
handles.button_stop_InitialPosition = get(handles.button_stop,'Position');

newhandles = handles;

guidata(hObject, handles);

% --- Executes on button press in change_mode.
function change_mode_Callback(hObject, eventdata, handles)

% Call oject movement : 
WindowMode = handles.WindowMode;
set(handles.main,'Visible','Off')
guidata(hObject, handles);


% Change Mode for next : 
if strcmp(WindowMode,'Normal')   
    handles.WindowMode = 'Expert';
    
    % Center Gui in window :
    set_mode(handles,'Expert');

else
    handles.WindowMode = 'Normal';
    
    % Center Gui in window :
    set_mode(handles,'Normal');

end

guidata(hObject, handles);

function set_mode(handles,WindowMode)

% Take out figure of screen : 

% Move handles depending on WindowMode : 
if strcmp(WindowMode,'Normal')

    % Take out figure of screen :
    set(handles.main,'Visible','Off')
    drawnow
    
    Width = 110;
    Height = 22;
    
    % Set position : 
    MainPosition = get(handles.main,'Position');
    Deltax = MainPosition(3)-Width;
    Deltay = MainPosition(4)-Height; 
    MainPosition(3) = Width; 
    MainPosition(4) = Height;
    set(handles.main,'Position',MainPosition);
    
    % Set visibility:
    set(handles.uipanel_treatment,'Visible','Off')
    set(handles.uipanel9,'Visible','Off')
    set(handles.uipanel10,'Visible','Off')
    set(handles.change_mode,'String','Mode Expert')
    set(handles.popupmenu_faces,'Visible','Off')
    set(handles.checkbox_computing,'Visible','Off')
    set(handles.reanalysis,'Visible','Off')
    
    % Treatment button : 
    PositionToSet = handles.pushbutton_treatment_InitialPosition;
    PositionToSet(1) = 3.5;
    PositionToSet(2) = 10;    
    set(handles.pushbutton_treatment,'Position',PositionToSet);

    % Text box processing : 
    PositionToSet = handles.Process_txtbox_InitialPosition;
    PositionToSet(1) = 44.5;
    PositionToSet(2) = 10;
    set(handles.Process_txtbox,'Position',PositionToSet);

    % Button Stop : 
    PositionToSet = handles.button_stop_InitialPosition;
    PositionToSet(1) = 95.5;
    PositionToSet(2) = 10;
    set(handles.button_stop,'Position',PositionToSet);

    % Change mode button : 
%     PositionToSet = handles.change_mode_InitialPosition;
%     PositionToSet(1) = 86;
%     PositionToSet(2) = 29;
%     set(handles.change_mode,'Position',PositionToSet);
    
    % axes_processing : 
    PositionToSet = handles.axes_processing_InitialPosition;
    PositionToSet(1) = 3.5;
    PositionToSet(2) = 12.5;
    set(handles.axes_processing,'Position',PositionToSet);
    
    % txtbox_specific_process :
    PositionToSet = handles.txtbox_specific_process_InitialPosition;
    PositionToSet(1) = 3.5;
    PositionToSet(2) = 14;
    set(handles.txtbox_specific_process,'Position',PositionToSet);
    set(handles.txtbox_specific_process,'String',' ');
    
    % Text_box code :
    PositionToSet = handles.txtbox_code_InitialPosition;
    PositionToSet(1) = 3.5;
    PositionToSet(2) = 16;
    set(handles.txtbox_code,'Position',PositionToSet);
    set(handles.txtbox_code,'String',' ');
    
    % Session_Name :
    PositionToSet = handles.Session_Name_InitialPosition;
    PositionToSet(2) = 19.5;
    set(handles.Session_Name,'Position',PositionToSet);
    
    % Analyse label :
    PositionToSet = handles.text3_InitialPosition;
    PositionToSet(2) = 19.5;
    set(handles.text3,'Position',PositionToSet);
    
    % All infos for analysis : 
    PositionToSet = handles.text29_InitialPosition;
    PositionToSet(1) = 3.5;   
    PositionToSet(2) = 17;
    set(handles.text29,'Position',PositionToSet);    

    % Segmentation version : 
    PositionToSet = handles.Segmentation_Version_InitialPosition;
    PositionToSet(1) = 27;   
    PositionToSet(2) = 17.25;
    set(handles.Segmentation_Version,'Position',PositionToSet);
    
    % ColorMaskValue : 
    PositionToSet = handles.colormaskvalue_InitialPosition;
    PositionToSet(1) = 66.5;   
    PositionToSet(2) = 17.25;
    set(handles.colormaskvalue,'Position',PositionToSet);    
    
    % Center Gui in window :
    movegui(handles.main,'center');
    
    % Take out figure of screen :
    reset_visualizeear(handles)

    % Take figure on screen :
    set(handles.main,'Visible','On')
    
else 
    
    % Take out figure of screen :
    set(handles.main,'Visible','Off')
    drawnow
    
    Width = 177;
    Height = 44;
    
    % Set position : 
    MainPosition = get(handles.main,'Position');
    Deltax = MainPosition(3)-Width;
    Deltay = MainPosition(4)-Height; 
    MainPosition(3) = Width; 
    MainPosition(4) = Height;
    set(handles.main,'Position',MainPosition);
    
    
    % Set visibility:
    set(handles.uipanel_treatment,'Visible','On')
    set(handles.uipanel9,'Visible','On')
    set(handles.uipanel10,'Visible','On')
    set(handles.change_mode,'String','Mode Normal')
    set(handles.popupmenu_faces,'Visible','On')
    set(handles.checkbox_computing,'Visible','On')
    set(handles.reanalysis,'Visible','On')

    %% Set position for bottom-left :
    set(handles.axis_logo,'Position',handles.axis_logo_InitialPosition);
    set(handles.text32,'Position',handles.text32_InitialPosition);
    set(handles.text35,'Position',handles.text35_InitialPosition);
    set(handles.text36,'Position',handles.text36_InitialPosition);
    set(handles.text37,'Position',handles.text37_InitialPosition);

    %% Set position for analysis infos : 
    set(handles.change_mode,'Position',handles.change_mode_InitialPosition);
    set(handles.colormaskvalue,'Position',handles.colormaskvalue_InitialPosition);
    set(handles.Segmentation_Version,'Position',handles.Segmentation_Version_InitialPosition);
    set(handles.text29,'Position',handles.text29_InitialPosition);

    %% Set positions for process activity : 
    set(handles.axes_processing,'Position',handles.axes_processing_InitialPosition);
    set(handles.txtbox_specific_process,'Position',handles.txtbox_specific_process_InitialPosition);
    set(handles.txtbox_code,'Position',handles.txtbox_code_InitialPosition);
    set(handles.pushbutton_treatment,'Position',handles.pushbutton_treatment_InitialPosition);
    set(handles.button_stop,'Position',handles.button_stop_InitialPosition);
    set(handles.Process_txtbox,'Position',handles.Process_txtbox_InitialPosition);

    %% Set positions for session name : 
    set(handles.text3,'Position',handles.text3_InitialPosition);
    set(handles.Session_Name,'Position',handles.Session_Name_InitialPosition);
    
    % Center Gui in window :
    movegui(handles.main,'center');
    
    % Take figure on screen :
    set(handles.main,'Visible','On')

end

function set_visibility(handles)

set(handles.change_mode,'Visible','On')
set(handles.colormaskvalue,'Visible','On')
set(handles.Segmentation_Version,'Visible','On')
set(handles.text29,'Visible','On')

function SwitchVisibility_OnProcess(handles,state)

if strcmp(state,'on')
    
    set(handles.Segmentation_Version,'Enable','off')
    set(handles.colormaskvalue,'Enable','off')
    set(handles.reanalysis,'Enable','off')
    set(handles.checkbox_computing,'Enable','off')
    set(handles.calculate_all,'Enable','off')
    set(handles.checkbox_allears,'Enable','off')
    set(handles.export_all,'Enable','off')
    set(handles.change_mode,'Enable','off')
    set(handles.Visualiser_Resultats,'Enable','off')
    set(handles.pushbutton_treatment,'Enable','off')
    set(handles.Search_Ear,'Enable','off')
    set(handles.popupmenu_faces,'Enable','off')
    
elseif strcmp(state,'off')
    
    set(handles.Segmentation_Version,'Enable','on')
    set(handles.colormaskvalue,'Enable','on')
    set(handles.reanalysis,'Enable','on')
    set(handles.checkbox_computing,'Enable','on')
    set(handles.calculate_all,'Enable','on')
    set(handles.checkbox_allears,'Enable','on')
    set(handles.export_all,'Enable','on')
    set(handles.change_mode,'Enable','on')
    set(handles.Visualiser_Resultats,'Enable','on')
    set(handles.pushbutton_treatment,'Enable','on')
    set(handles.Search_Ear,'Enable','on')
    set(handles.popupmenu_faces,'Enable','on')    
    
end







