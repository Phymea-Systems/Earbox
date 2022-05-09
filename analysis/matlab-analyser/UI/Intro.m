function varargout = Intro(varargin)
% INTRO MATLAB code for Intro.fig
%      INTRO, by itself, creates a new INTRO or raises the existing
%      singleton*.
%
%      H = INTRO returns the handle to a new INTRO or the handle to
%      the existing singleton*.
%
%      INTRO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INTRO.M with the given input arguments.
%
%      INTRO('Property','Value',...) creates a new INTRO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Intro_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Intro_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Intro

% Last Modified by GUIDE v2.5 06-Aug-2019 12:25:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Intro_OpeningFcn, ...
                   'gui_OutputFcn',  @Intro_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Intro is made visible.
function Intro_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Intro (see VARARGIN)

% Choose default command line output for Intro
% set(handles.sessions,'WindowButtonMotionFcn',@MoveCallback)

% Get all initial positions : 
handles.output = hObject;
movegui('center');
% handles.InitialCenteredPosition = get(handles.sessions,'Position');
% And for all objects : 
% handles.InitialPositionLogo = get(handles.axis_logo,'Position');
% handles.InitialPositionName = get(handles.name,'Position');
% handles.InitialPositionVersion = get(handles.version,'Position');
% handles.InitialPositionCreate_session = get(handles.Create_session,'Position');
% handles.InitialPositionopen_session = get(handles.Open_session,'Position');
% handles.InitialPositionManage_sessions = get(handles.Manage_sessions,'Position');
% handles.InitialPositiontext_bug = get(handles.text_bug,'Position');
% handles.InitialPositiontext_website = get(handles.text_website,'Position');
handles.ROOT = 'D:\Phymea\EarBox'; 

%% Try catch to remove later :
try
    % Add phymea image :
    set(handles.axis_logo,'Visible','off')
    axes(handles.axis_logo)
    matlabImage = imread(fullfile('logo_registred_alpha.png')); % A changer !
    image(matlabImage)
    axis off
    axis image
    drawnow
catch
end


% Session stuff : 
handles.isSessionSet = 0;
handles.WindowState = 'Initial';
handles.isWindowSet = 0; 

% Check session log (or create if needed) : 
resetwaitbar_intro(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Intro wait for user response (see UIRESUME)
% uiwait(handles.sessions);

% --- Outputs from this function are returned to the command line.
function varargout = Intro_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in Create_session.
function Create_session_Callback(hObject, eventdata, handles)
% hObject    handle to Create_session (see GCBO)

handles.Session_Path = '' ; 
handles.EarBox_Images_Path = '' ;  

% Set handle enable :
set(handles.Create_session,'enable','off','BackGroundColor',[0.15 0.15 0.15])
% set(handles.Manage_sessions,'enable','on','BackGroundColor',[0 0 0])
set(handles.Open_session,'enable','on','BackGroundColor',[0 0 0])
    
% Build the page : 
set(handles.group_creer,'Visible','On')
set(handles.group_charger,'Visible','Off')
handles.isWindowSet = 1;
handles.WindowState ='Create';

guidata(hObject, handles);

% --- Executes on button press in Open_session.
function Open_session_Callback(hObject, eventdata, handles)
% hObject    handle to Open_session (see GCBO)

set(handles.Open_session,'enable','off','BackGroundColor',[0.15 0.15 0.15])
% set(handles.Manage_sessions,'enable','on','BackGroundColor',[0 0 0])
set(handles.Create_session,'enable','on','BackGroundColor',[0 0 0])

 
% Build the page : 
set(handles.group_creer,'Visible','Off')
set(handles.group_charger,'Visible','On')
handles.isWindowSet = 1;
handles.WindowState ='Open';


guidata(hObject, handles);

% --- Executes on button press in Manage_sessions.
% function Manage_sessions_Callback(hObject, eventdata, handles)
% % hObject    handle to Manage_sessions (see GCBO)
% 
% % set(handles.Manage_sessions,'enable','off','BackGroundColor',[0.15 0.15 0.15])
% set(handles.Open_session,'enable','on','BackGroundColor',[0 0 0])
% set(handles.Create_session,'enable','on','BackGroundColor',[0 0 0])
% 
% % Build the page : 

% Mouse controls : 
function MoveCallback(source, event)
          % Get the current position of your mouse pointer
          
          up.x = 50;
          up.y = 150;
          up.width = 100;
          up.height = 200;
          
          p = get(f,'CurrentPoint');
          % Check if the mouse is currently over the UIPANEL
          if  (p(1) > up.x) && (p(1) < up.x + up.width) ...
                  && (p(2) > up.y) && (p(2) < up.y + up.height)
              % If so change the pointer
              set(f,'Pointer','arrow')
          else
              % Otherwise set/keep the default arrow pointer
              set(f,'Pointer','custom')
          end

%%%%%%%%%%%%%%%%%%%%%%%%%

% Buttons : 
% Create session buttons : 
function pathButtonPushedPathRoot(hObject,eventdata,handles)

 Session_Path = 0 ; 
 while Session_Path == 0 
 
     Session_Path = uigetdir(pwd,'Choisissez un dossier :');
 
     if Session_Path == 0
         warndlg('Nom de dossier invalide','Erreur')
         Session_Path = 'C:\'; 
     end
     
 end
 
set(handles.edit_sessionPath,'String',Session_Path)

guidata(hObject, handles);

function pathButtonPushedPathEarImages(hObject,eventdata,handles)

 EarBox_Images_Path = 0 ; 
 FolderName = 'Nouvelle_Session' ;
 while EarBox_Images_Path == 0 
 
     EarBox_Images_Path = uigetdir(pwd,'Choisissez un dossier :');

     
     %% Check if there is the right file defining an Earbox session :
     if (EarBox_Images_Path~=0)

         FileList = ls(fullfile(EarBox_Images_Path));
         FileList= cellstr(FileList);
         FileList = FileList(~ismember(FileList,{'.','..'}));
         NotSet = 0;
         handles.GlobalParameters = [];
         handles.GlobalParametersValue = [];
         
         if exist(fullfile(EarBox_Images_Path,'session_para'),'file')==2
             
             try
                 %                  Names = strsplit(EarBox_Images_Path,'\');
                 %                  FolderName = Names{end};
                 fid=fopen(fullfile(EarBox_Images_Path,'session_para'),'r');
                 tline = fgetl(fid);
                 l = 1;
                 while ischar(tline)
                     SplittedLine = strsplit(tline,'=');
                     if length(SplittedLine) ==2
                         handles.GlobalParameters{l} = SplittedLine{1};
                         handles.GlobalParametersValue{l} = SplittedLine{2};
                     end
                     tline = fgetl(fid);
                     l = l+1;
                 end
                 fclose(fid);
                 
                 FolderName = handles.GlobalParametersValue{find(strcmp('Session_Name',handles.GlobalParameters))};
                 
             catch
                 NotSet = 1;
             end
             
         end
         
         if NotSet
             
             try 
                 
                 ExifInfo = imfinfo(fullfile(EarBox_Images_Path,FileList{1})); 
                 StrSplitted = strsplit(ExifInfo.ExifThumbnail.Artist,'_');
                 LengthOfDate = length(StrSplitted{1});
                 SessionName = ExifInfo.ExifThumbnail.Artist(LengthOfDate+2:end);
                 FolderName = SessionName;
                 
                 handles.GlobalParametersValue = FolderName;
                 handles.GlobalParameters = 'Session_Name';
                 
             catch 
                 
                 EarBox_Images_Path = 0;

             end
                                  
         end
         
     end
     
     %% If anything goes wrong it's not a correct session :
     if EarBox_Images_Path == 0
         
         warndlg('Nom de dossier invalide','Erreur')
         EarBox_Images_Path = '';
         FolderName = '-- Choisissez un répertoire --';
         handles.GlobalParametersValue = FolderName;
         handles.GlobalParameters = 'Session_Name';
                 
     end
     
 end

set(handles.edit_ImagesBox,'String',EarBox_Images_Path)
set(handles.edit_sessionName,'String',FolderName)


guidata(hObject, handles);

function pathButtonPushedBegin_Creation(hObject,eventdata,handles)

    SessionName = get(handles.edit_sessionName,'String'); 
    BDDPath = get(handles.edit_sessionPath,'String'); 
    Images = get(handles.edit_ImagesBox,'String');  
    
    if isempty(SessionName) || strcmp(SessionName,'-- Choisissez un répertoire --')
        warndlg('Veuillez choisir un répertoire de photos Earbox pour récupérer importer la session associée !','Erreur')
        return
    end

    % Check for special characters in a string : 
    is_special = false( size( SessionName ) );
    is_special( regexp( SessionName, '^\w' ) ) 
    isOk = isempty( regexp( SessionName, '[^A-Za-z0-9_]', 'start' ));
    if ~isOk
        warndlg({'Mauvais nom de session, les caractères autorisés sont :',' a-z  A-Z  0-9 ou _- (pas d''espace)'},'Erreur')
        return
    end
    
    % CD to BDDPath : 
    try 
        exist(BDDPath,'dir');
    catch 
        warndlg('Nom de répertoire d''acceuil invalide !','Erreur')
        return
    end
    
    %% First check size of folder : 
    
%     SizeOfFolder_InGo = DirSize(Images)/1000000000;
%     FreeSpace_InGo = java.io.File(BDDPath).getFreeSpace()/1000000000;
%     
%     if FreeSpace_InGo < SizeOfFolder_InGo*1.2
%         mydialog_intro('Erreur',['La taille du dossier d''acceuil est trop petite, veuillez libérer de l''espace. La taille minimum requise est de  : ' round(num2str(SizeOfFolder_InGo*1.2),2) 'Go'])
%         return
%     end
    
    % Start logs & set to ALL infos : 

    
    % Test/create the repertory : 
    try 
        [~,~,messid] = mkdir(fullfile(strcat(BDDPath,'\',SessionName)));
    catch 
        warndlg('Nom de session invalide !','Erreur')
        return
    end

    if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
        warndlg('Le dossier de session existe déjà !','Erreur')
        return
    end
    
    % Create folders arborescence in repertory : 
    Session_Path = fullfile(strcat(BDDPath,'\',SessionName));
    ListOfDirs = dir(Session_Path) ;
    handles.CurrentAuditLog = log4m.getLogger(strcat(Session_Path,'\SessionLog.txt'));
    handles.CurrentAuditLog.setLogLevel(handles.CurrentAuditLog.ALL)
    
    FolderNames = ListOfDirs(vertcat(ListOfDirs.isdir)).name;
    if ~ismember('data',FolderNames)
        
        %% Création du dossier data : 
        try 
            mkdir(Session_Path,'data')
            handles.CurrentAuditLog.trace('Dossier data créé','Succès')
        catch 
            handles.CurrentAuditLog.trace('Dossier data créé','Echec')
        end
        
        %% Creation du fichier d'option : 
%         try 
%             createOptionFile(Session_Path)
%             handles.CurrentAuditLog.trace('Options initiées','Succès')
%         catch     
%             handles.CurrentAuditLog.trace('Options initiées','Echec')
%         end
        
    end

    %% Creation du dossier output : 
    if ~ismember('outputs',FolderNames)
        try
            mkdir(Session_Path,'outputs')
            handles.CurrentAuditLog.trace('Dossier de sortie créé','Succès')
        catch
            handles.CurrentAuditLog.trace('Dossier de sortie créé','Echec')
            
        end
        
    end
    
    %% Creation du dossier d'images Earbox : 
    if ~ismember('Earbox_Images',FolderNames)
        try
            mkdir(Session_Path,'Earbox_Images')
            handles.CurrentAuditLog.trace('Dossier d''images de sorties','Succès')
        catch
            handles.CurrentAuditLog.trace('Dossier d''images de sorties','Echec')
            
        end
        
    end

    %% Creation du dossier d'images Earbox :
    if ~ismember('logs',FolderNames)
        try
            mkdir(Session_Path,'logs')
            handles.CurrentAuditLog.trace('Dossier de logs','Succès')
        catch
            handles.CurrentAuditLog.trace('Dossier de logs','Echec')
            
        end
        
    end
        
    
    %% 
    % Add session to log of all sessions : 
    % TODO ! 
    
    % Get the list of images from Earbox 
    % Construct session structure :  
    CurrentSession = struct();
    CurrentSession.Session_Path = Session_Path;
    CurrentSession.Image_Path = Images ; 
    CurrentSession.TimeOfCreation = now ;
    CurrentSession.SessionName = SessionName ;
    CurrentSession.GlobalParameters=handles.GlobalParameters ;
    CurrentSession.GlobalParametersValue=handles.GlobalParameters ;
    
    % Define user and computer : 
    try
        CurrentSession.Creator.User = getenv('username');
        CurrentSession.Creator.Computer = getenv('computername');
    catch
        CurrentSession.Creator.User = 'No_Data';
        CurrentSession.Creator.Computer = 'No_Data';
        handles.CurrentAuditLog.trace('Problem in definition of computer and user','Echec');
    end
    
    CurrentSession.isMasked = 0;
    CurrentSession.isADMIN = 0;
%     CurrentSession.SoftWareVersion = 'v0.3';
    
    % Write session creation log : 
    handles.CurrentAuditLog.trace('Création session','Succès');
    
    % Stock info about session for subsequent loading : 
    save(fullfile(strcat(Session_Path,'\','Info.session')),'CurrentSession');
    handles.CurrentAuditLog.trace(strcat(SessionName,'.session SAVE'),'Succès');
    
    
    %% Begin data import : 
    current_process_intro(handles,'Lancement du transfert des fichiers...')
    set(handles.sessions, 'pointer', 'watch')

    % Initialize loop : 
    ImageList = cellstr(ls(fullfile(CurrentSession.Image_Path)));
    ImageList = ImageList(~ismember(ImageList,{'.','..'}));
    CopiedFile = zeros(1, length(ImageList));
    CurrentSession.FileList = ImageList;
    CurrentSession.CopiedFile = CopiedFile;
    for image =1:length(ImageList)
        
        % Copy paste files from source to destination : 
        FullPathSource = fullfile(CurrentSession.Image_Path,ImageList{image});
        FullPathSourceDestination = fullfile(CurrentSession.Session_Path,'Earbox_Images');
        try
            
            copyfile(FullPathSource,FullPathSourceDestination)
            CurrentSession.CopiedFile(image) = 1;
            
        catch
            
            handles.CurrentAuditLog.trace(strcat(FullPathSource,'.copy'),'Echec');
            
        end
        
        % Update every 20 pictures :
        if rem(image,12) == 0
            Ratio = image/length(ImageList);
            current_process_intro(handles,strcat(['Transfert des images...' ' ' num2str(round(Ratio*100,2)) '%']))
            updatewaitbar_intro(handles,Ratio)
        end
        
        
    end
    
    % Finish the process : 
    set(handles.sessions, 'pointer', 'arrow')
    updatewaitbar_intro(handles,1)
    
    % Handle copy problems : 
    CurrentSession.CopyErrors = sum(~CurrentSession.CopiedFile);
    if CurrentSession.CopyErrors > 0
        Answer = questdlg(['L''importation des données est terminée. Le processus s''est déroulé avec' ' ' num2str(CurrentSession.CopyErrors) ' erreurs.  Voulez-vous ouvrir une session d''analyse correspondant à ces photos ?'], 'Importation terminée ! ', 'Oui', 'Non','Non');
    else
        Answer = questdlg(['L''importation des données est terminée. Le processus s''est déroulé avec succès. Les images du dossier d''origine: ' CurrentSession.Image_Path ' peuvent être effacées sans risque.  Voulez-vous ouvrir une session d''analyse correspondant à ces photos ?'], 'Importation terminée ! ', 'Oui', 'Non','Non');
    end
    
    % Stock info about session for subsequent loading :
    % Updae image path : 
    CurrentSession.Image_Path = fullfile(CurrentSession.Session_Path,'Earbox_Images');
    save(fullfile(strcat(Session_Path,'\','Info.session')),'CurrentSession');
    handles.CurrentAuditLog.trace(strcat(SessionName,'.session SAVE'),'Succès');
    current_process_intro(handles,strcat(['Transfert des images... 100%']))
    
    % Open session depending on answer : 
    if strcmp(Answer,'Oui')
        fh = findobj('tag', 'main');
        if isempty(fh)
            current_process_intro(handles,strcat([' ']))
            resetwaitbar_intro(handles)
            main('my_gui',CurrentSession.Session_Path,'Normal');
        else
            delete(handles.CurrentAuditLog);
            current_process_intro(handles,strcat([' ']))
            resetwaitbar_intro(handles)
            main('my_gui',Session_Path,'Normal');
            return
        end
        delete(handles.CurrentAuditLog);
    end

    
    % Reinitialize everything : 


guidata(hObject, handles);

function ReadSessions(hObject,eventdata, handles)
% Read : 
BDDPath = get(handles.edit_choosesession,'String'); 
Splitted = strsplit(BDDPath,'\')  ;
SessionName = Splitted(length(Splitted)); 
Session_Path = BDDPath; 

% CD to BDDPath :
try
    cd(BDDPath)
catch
    warndlg('Nom de répertoire d''acceuil invalide !','Erreur')
    return
end

% Test du nom de session : 
if isempty(SessionName)
    warndlg('Nom de session non reconnue !','Erreur')
    return
end

% Tester le chargement du fichier log : 
try 
    handles.CurrentAuditLog = log4m.getLogger(strcat(Session_Path,'\SessionLog.txt')); 
catch
    warndlg('Impossible de charger le fichier log !','Erreur')
    return
end

% Tester le chargement des infos de sessions : 
try 
    load('Info.session','-mat')
catch
    warndlg('Impossible de charger les informations de session !','Erreur')
    return
end

% Delete log : 
handles.CurrentAuditLog.trace(strcat('Chargement session',' ',CurrentSession.SessionName),'Succès'); 
delete(handles.CurrentAuditLog);

fh = findobj('tag', 'main'); 
if isempty(fh)
    main('my_gui',CurrentSession.Session_Path,'Normal');
else
    warndlg('Une session est déjà ouverte, veuillez la fermer avant d''en ouvrir une nouvelle. ','Erreur')
    return
end

guidata(hObject, handles);

% Choose session buttons : 
function buttonChooseSession_Callback(hObject, eventdata, handles)
% hObject    handle to buttonChooseSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 Session_Path = 0 ; 
 while Session_Path == 0 
 
     Session_Path = uigetdir(pwd,'Choisissez un dossier :');
 
     if Session_Path == 0
         warndlg('Nom de dossier invalide','Erreur')
         Session_Path = 'C:\'; 
     else
         try
             load(fullfile(strcat(Session_Path,'\Info.session')),'-mat')
             handles.CurrentSession =  CurrentSession  ;
             FolderName = handles.CurrentSession.SessionName;
             set(handles.edit10,'String',FolderName)
         catch
             warndlg('Impossible de charger les informations de session !','Erreur')
             return
         end
     end
     
 end
handles.Session_Path = Session_Path; 
set(handles.edit_choosesession,'String',Session_Path)


guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%
%% WaitBar & String : %%
%%%%%%%%%%%%%%%%%%%%%%%%

function resetwaitbar_intro(handles)

set(handles.axes_process,'Xtick',[],'Ytick',[],'Xlim',[0 1],'Ylim',[0 1],'box','on','Visible','On')

axes(handles.axes_process);
rectangle('Position',[0,0,1,1],'FaceColor','black','Parent',handles.axes_process);
drawnow

function updatewaitbar_intro(handles,value)

% Value should be between 0 and 1 ! 
axes(handles.axes_process);
value = min(max(value, 0),1);
set(handles.axes_process,'Xtick',[],'Ytick',[],'Xlim',[0 1],'Ylim',[0 1],'box','on','Visible','On')
rectangle('Position',[0,0,value,1],'FaceColor','b','Parent',handles.axes_process);

drawnow

function current_process_intro(handles,string)

set(handles.process_text,'String',string)
drawnow

function update_show_run_intro(handles,task,value,NumSteps)

ValueToWrite = num2str(round(value/NumSteps*100,0));
stringToWrite = strcat(task,' ',ValueToWrite,'%');
updatewaitbar_intro(handles,round(value/NumSteps,2));
current_process_intro(handles,stringToWrite);
drawnow

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Miscellaneous ! 
%%%%%%%%%%%%%%%%%%%%%%%%%


function mydialog_intro(Name,String)

d = dialog('Position',[300 300 250 150],'Name',Name');
txt = uicontrol('Parent',d,'Style','text','Position',[20 80 210 40],'String',String);
btn = uicontrol('Parent',d,'Position',[85 20 70 25],'String','Close','Callback','delete(gcf)');

waitfor(d)

function free = getFreeSpace(path)

if nargin < 1 || isempty(path)
    path= '.';
end

free = java.io.File(path).getFreeSpace();

function edit_sessionPath_Callback(hObject, eventdata, handles)
% hObject    handle to edit_sessionPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_sessionPath as text
%        str2double(get(hObject,'String')) returns contents of edit_sessionPath as a double

% --- Executes during object creation, after setting all properties.
function edit_sessionPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_sessionPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_ImagesBox_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ImagesBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ImagesBox as text
%        str2double(get(hObject,'String')) returns contents of edit_ImagesBox as a double

% --- Executes during object creation, after setting all properties.
function edit_ImagesBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ImagesBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_sessionName_Callback(hObject, eventdata, handles)
% hObject    handle to edit_sessionName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_sessionName as text
%        str2double(get(hObject,'String')) returns contents of edit_sessionName as a double

% --- Executes during object creation, after setting all properties.
function edit_sessionName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_sessionName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_choosesession_Callback(hObject, eventdata, handles)
% hObject    handle to edit_choosesession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_choosesession as text
% str2double(get(hObject,'String')) returns contents of edit_choosesession as a double

% --- Executes during object creation, after setting all properties.
function edit_choosesession_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_choosesession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% POUBELLE  %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in reset_window.

%%%%%%%%%%%%%%%%%%%%%%%%%%

function updateWindow(hObject,handles,String,Value)

if strcmp(String,'Grow')==1

    % Change all positions around the figure :
    if handles.isWindowSet == 0 
        ChangeVerticalPos(hObject,handles,Value)
        Position = handles.InitialCenteredPosition;
        PositionNow = get(handles.sessions,'Position');
        PositionNow(4) = Position(4)+Value;
        PositionNow(2) = PositionNow(2)-Value;
        set(handles.sessions,'Position',PositionNow)
        findfigs

        handles.isWindowSet = 1;
    end
end
if strcmp(String,'Reset')==1
    ResetVerticalPos(hObject,handles)
    handles.isWindowSet = 0;
end




guidata(hObject, handles);

function ChangeVerticalPos(hObject,handles,Value)
    
set(handles.name,'Position',[handles.InitialPositionName(1),...
                                  handles.InitialPositionName(2)+Value,...
                                  handles.InitialPositionName(3),...
                                  handles.InitialPositionName(4)]);
set(handles.axis_logo,'Position',[handles.InitialPositionLogo(1),...
                                  handles.InitialPositionLogo(2)+Value,...
                                  handles.InitialPositionLogo(3),...
                                  handles.InitialPositionLogo(4)]);
set(handles.version,'Position',[handles.InitialPositionVersion(1),...
                                  handles.InitialPositionVersion(2)+Value,...
                                  handles.InitialPositionVersion(3),...
                                  handles.InitialPositionVersion(4)]);
set(handles.Create_session,'Position',[handles.InitialPositionCreate_session(1),...
                                  handles.InitialPositionCreate_session(2)+Value,...
                                  handles.InitialPositionCreate_session(3),...
                                  handles.InitialPositionCreate_session(4)]);
set(handles.Open_session,'Position',[handles.InitialPositionopen_session(1),...
                                  handles.InitialPositionopen_session(2)+Value,...
                                  handles.InitialPositionopen_session(3),...
                                  handles.InitialPositionopen_session(4)]);
% set(handles.Manage_sessions,'Position',[handles.InitialPositionManage_sessions(1),...
%                                   handles.InitialPositionManage_sessions(2)+Value,...
%                                   handles.InitialPositionManage_sessions(3),...
%                                   handles.InitialPositionManage_sessions(4)]); 
                              
guidata(hObject, handles);

function ResetVerticalPos(hObject,handles)
    
if strcmp(handles.WindowState,'Create');
    
    delete(handles.txtbox_sessionName)
    delete(handles.txtbox_sessionPath)
    delete(handles.txtbox_ImagesBox)
    delete(handles.edit_sessionName)
    delete(handles.edit_sessionPath)
    delete(handles.edit_ImagesBox)
    delete(handles.ButtonPathRoot)
    delete(handles.ButtonPathEarImages)
    delete(handles.Begin_Creation)

end

set(handles.axis_logo,'Position',handles.InitialPositionLogo);
set(handles.name,'Position',handles.InitialPositionName);
set(handles.version,'Position',handles.InitialPositionVersion);
set(handles.Create_session,'Position',handles.InitialPositionCreate_session);
set(handles.Open_session,'Position',handles.InitialPositionopen_session);
% set(handles.Manage_sessions,'Position',handles.InitialPositionManage_sessions);
set(handles.text_bug,'Position',handles.InitialPositiontext_bug);
set(handles.text_website,'Position',handles.InitialPositiontext_website);





guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on mouse press over figure background.
function sessions_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to sessions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2

% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%% CLOSING GUI : %%%%%%%%%%%%%

% --- Executes when user attempts to close sessions.
function sessions_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to sessions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

   selection = questdlg('Fermer le programme ?',...
                        'Fermeture',...
                        'Oui','Non','Oui');
   switch selection,
      case 'Oui',
         delete(gcf)
      case 'Non'
         return 
   end
   
   % Close parallel pool :
   poolobj = gcp('nocreate');
   delete(poolobj);
        
   
% Hint: delete(hObject) closes the figure
delete(hObject);

function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
