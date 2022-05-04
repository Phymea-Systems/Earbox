

%% 1/ Last Calculation of variables outputs :


workspace = 'E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\data\Caractérisation manuelle compléte' ;
cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0')

% Get all the ear codes in the folder : 
dpath = strcat(workspace,'\data');
earList = cellstr(ls(fullfile(strcat(workspace,'\data'))));
earList=earList(~ismember(earList,{'.','..'}));
earsFacesDone = zeros(size(earList)*6);

Outputs.Data = nan((length(earList))*6,15);
Outputs.Codes = earList;
Outputs.Vars = {'Face','Longueur','Largeur','NbrBot_New','NbrMid_New','NbrTop_New','NbrBot_Old','NbrMid_Old','NbrTop_Old',... % 1-9
                'NbGpRmax','l_fertile','l_apical','l_basal','NbGpR',... % 10-14
                'NbGpR_New_Bot','NbGpR_New_Mid','NbGpR_New_Top',... % 15-17
                'NbGpR_New_BotMax','NbGpR_New_MidMax','NbGpR_New_TopMax',... % 18-20
                'SurfGrains','SurfEar','GrainRatio','MeanGrainSurf','NbGr'}; % 19-23
Outputs.ringDimensions = {};

% Calculate ears : 

tmwMultiWaitbar('Analysing images and saving data :',0);
% Loop over codes : 
for ear  = 15 : length(earList)
    
    % Loop over face : 
    for face = 1:6
        
        k = ((ear-1)*6+face) ;
        
        code = earList{ear};
        
        obj = FaceEarClass(dpath, code,face);

        Outputs.Data(k,1)=face;
        Outputs.Data(k,2)=obj.horzAxisLength*obj.PX2CM;
        Outputs.Data(k,3)=obj.earMaxDiameter*obj.PX2CM;
        Outputs.Data(k,4)=obj.RanksCount.Bot;
        Outputs.Data(k,5)=obj.RanksCount.Mid;
        Outputs.Data(k,6)=obj.RanksCount.Top;
        Outputs.Data(k,7)=obj.ringCount.ringCountAvgBot;
        Outputs.Data(k,8)=obj.ringCount.ringCountAvgMid;
        Outputs.Data(k,9)=obj.ringCount.ringCountAvgTop;
        
        % Calculate nbrGpR : 
        sortedFileLength = obj.horzFilesProps.sortedFileLength;
        NbGpR = mean(sortedFileLength(~(abs(sortedFileLength(1)-sortedFileLength)>0.5*std(sortedFileLength))));
        Outputs.Data(k,10)=NbGpR;
        
        % Calculate zones : 
        [A,F,B] = obj.fertileZoneMaskDimensions(0.5,0.5);
        
        % If non kernel fertile :
        if any([isnan(A) isnan(F) isnan(B)])
            F = 0;
            A = (obj.horzAxisLength*obj.PX2CM)/2;
            B = (obj.horzAxisLength*obj.PX2CM)/2;
        end
            
        l_fertile = F;
        Outputs.Data(k,11)=l_fertile*obj.PX2CM;
        l_apical = A;
        Outputs.Data(k,12)=l_apical*obj.PX2CM;
        l_basal = B;
        Outputs.Data(k,13)=l_basal*obj.PX2CM;
        Outputs.Data(k,14)=gpr(obj);
        
        Outputs.Data(k,15)=obj.GrainPerRanksCount.Bot;
        Outputs.Data(k,16)=obj.GrainPerRanksCount.Mid;
        Outputs.Data(k,17)=obj.GrainPerRanksCount.Top;
        
        Outputs.Data(k,18)=obj.GrainPerRanksCount.MaxBot;
        Outputs.Data(k,19)=obj.GrainPerRanksCount.MaxMid;
        Outputs.Data(k,20)=obj.GrainPerRanksCount.MaxTop;        
        
        Outputs.Data(k,21) = obj.GrainsAttributes.SurfGrains ;
        Outputs.Data(k,22) = obj.GrainsAttributes.SurfEar;
        Outputs.Data(k,23) = obj.GrainsAttributes.MeanGrainSurf ;
        Outputs.Data(k,24) = obj.GrainsAttributes.NbGr;
        

        Outputs.ringDimensions{k} = obj.GrainsAttributes.ringDimensions ;
        
        showAndSaveResultsImage(obj,40,FigureLength,'on','on'); % (obj, MaxSize of ear, FigureLength wanted, Visibility of figure, Saving)
        save('OutputsStructure.mat','Outputs')
    
        tmwMultiWaitbar('Analysing images and saving data', k / (length(earList)*6) )
        earsFacesDone(ear)=1 ;    
        
    end
    
    save('OutputsStructure.mat','Outputs')

    
end

tmwMultiWaitbar('Analysing images and saving data','close');

%%% Intégrations dans le code : 

% Sortie de la surface du masque épi
% Sortie de la surfacer du masque des grains finaux
% Quelle image sortir ?
% Images issues de la discussion avec romain : positionnement de traits de
% longueur fertile, basale et apicale 

%% 2/ Outputfile  : 

%%%%%%%  Outfile : %%%%%

cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\data\Test')
fileID = fopen('Output_Meabox.csv','wt') ; 
fprintf(fileID,'%s','Code');
fprintf(fileID,';%s','N_Epi',Outputs.Vars{:});
fprintf(fileID,'\n');
code_epi = 1;

for code =1: length(Outputs.Codes)
       
    for face = 1:6
        
    
        Code = Outputs.Codes{code};
        cut1 = strsplit(Code,'.');
        cut2 = strsplit(char(cut1(2)),'U');
        code_epi = (str2num(char(cut2(1)))-1)*3+str2num(char(cut2(2)));
        
        % Code et face : 
        fprintf(fileID,'%s%s',char(cut1(1)),';') ;
        fprintf(fileID,'%01.0f%s',uint8(code_epi),';') ;        
        fprintf(fileID,'%d%s',face) ;   
        fprintf(fileID,';%2.3f',Outputs.Data(((code-1)*6+face),2:20));
        fprintf(fileID,'\n');
        
    end
    
    
end

fclose(fileID);


%% 3/ Test tailles de grains : 

code = 'MAU17-PG_10_WD2_390_2_21.1U1' ; 
code = 'MAU17-PG_7_WD1_243_3_12.3U2';
face = 4 ;

workspace = 'E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\data\Caractérisation manuelle compléte' ;
% Get all the ear codes in the folder : 
dpath = strcat(workspace,'\data');
cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0')

obj = FaceEarClass(dpath, code,face) ; 
%Test = obj.GrainsAttributes;
%[A,F,B] = obj.fertileZoneMaskDimensions(0.5,0.5);


% % Les trois : 
% figure(1)
% 
% subplot(3,1,1)       % add first plot in 2 x 1 grid
% plot(obj.ringDimensions.pos,obj.ringDimensions.Ydim*obj.PX2CM)
% set(gca, 'XDir','reverse')
% ylabel({'diametre','de grain','(cm)'}) % y-axis label
% 
% subplot(3,1,2)       % add second plot in 2 x 1 grid
% plot(obj.ringDimensions.pos,obj.ringDimensions.Xdim*obj.PX2CM)
% set(gca, 'XDir','reverse')
% ylabel({'hauteur','de grain','(cm)'}) % y-axis label
% 
% subplot(3,1,3)       % add second plot in 2 x 1 grid
% plot(obj.ringDimensions.pos,obj.ringDimensions.Ydim.*obj.ringDimensions.Xdim*(obj.PX2CM^2))
% set(gca, 'XDir','reverse')
% xlabel('Cohorte') % x-axis label
% ylabel({'surface','de grain','(cm²)'}) % y-axis label
% 
% % Epis et surface : 
% 
% % Les trois : 
% figure(1)
% 
% subplot(2,1,1),hold on       % add first plot in 2 x 1 grid
% imshow(obj.mask)
% imshow(label2rgb(obj.horzFilesProps.IfilesColor, 'jet', 'k', 'shuffle'))
% hold off
% 
% subplot(2,1,2)       % add second plot in 2 x 1 grid
% plot(obj.ringDimensions.pos,obj.ringDimensions.Ydim.*obj.ringDimensions.Xdim*(obj.PX2CM^2),'color','black')
% set(gca, 'XDir','reverse')
% xlabel('Cohorte') % x-axis label
% ylabel({'surface de grain (cm²)'}) % y-axis label

%% 4/ Plot par face : 


EarMaxLength =45 ; % cm
EarMaxDiam = 12 ; % cm
FigureLength = 900 ; % pixels  

% Get image size / proportion: 
ImSize = size(obj.mask);
ImRatio = (ImSize(2)/ImSize(1));

% Set figure size : 
FigureWidth = FigureLength/ ImRatio ;
EarSize = obj.horzAxisLength*obj.PX2CM ;
EarDiam = obj.earMaxDiameter*obj.PX2CM ;

Scaling = EarSize/EarMaxLength ;
gcaLength = Scaling * FigureLength ; 
gcaWidth = gcaLength / ImRatio ; 

% Scaling = (EarSize/EarDiam) / (EarMaxLength/EarMaxDiam) ;
%gcaLength = EarSize/EarMaxLength*FigureLength;
%gcaWidth = EarDiam/EarMaxDiam*FigureWidth;
RGB = obj.RGBImage ;
Lfertile = num2str(round(obj.ZoneMasks.FertileZone*obj.PX2CM,1));
Lapex = num2str(round(obj.ZoneMasks.ApexAbortion*obj.PX2CM,1));
Lbase = num2str(round(obj.ZoneMasks.BasalAbortion*obj.PX2CM,1)) ;


ResultsImage = figure('Name','ResultsImage'); ...
    
    set(ResultsImage,'Visible','on','InvertHardcopy','off');

    hold on

    set(gcf,'units','pixels','position',[50,50,FigureLength,FigureWidth],'Color',[0 0 0])

    set(gca,'units','pixels',...
        'position',[(FigureLength/2)-(gcaLength/2),(FigureWidth/2)-(gcaWidth/2),gcaLength,gcaWidth],...
        'Visible','on',...
        'XLim',[0 ImSize(2)*Scaling],...
        'YLim',[0 ImSize(1)*Scaling])

    % Mask :
    imshow(imresize(RGB, Scaling),'Parent', gca)

    % Setup  : 
    Xmin = 0.015 ;
    Xmax = 0.81 ;
    Ymin = 0.03 ; 
    Ymax = 0.9 ;
    PhymeaColor = [0 0.66 0] ; 
    
    % Fertile Zone + Grains :
    % -----------------------
    him = imshow(imresize(obj.horzFilesProps.IfilesColor, Scaling),'Parent', gca);
    him.AlphaData = 0.5;


    % Ear Length and zones :
    annotation(gcf,'textbox',[0.015 0.03 0.1 0.1],...
        'String','Ear dimensions :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none');
    CurrentAxes = gca ;
    CurrentFigure = gcf ;
    
    
    % Pixel of start of base zone : 
    ApexEpi = (1-(find(sum(obj.mask),1,'last')/length(obj.mask)))*Scaling  ;
    BaseEpi = find(sum(obj.mask),1,'first')/length(obj.mask)*Scaling ;
    Base = obj.ZoneMasks.BasalAbortion/length(obj.mask)*Scaling ;
    Apical =  obj.ZoneMasks.ApexAbortion/length(obj.mask)*Scaling;
    
    Xlength = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi...
        (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi] ;
    Ylength = [ (CurrentAxes.Position(1)-10)/FigureLength (CurrentAxes.Position(1)-10)/FigureLength  ] ;

    YsmallBars = [((CurrentAxes.Position(1)-10)/FigureLength)-0.02 ((CurrentAxes.Position(1)-10)/FigureLength)+0.02] ;

    annotation(gcf,'doublearrow',Xlength,Ylength,'color', PhymeaColor,'HeadStyle','hypocycloid');

    if isnan(Base) || isnan(Apical)

        annotation(gcf,'textbox',[.45 Ymin .1 .1],'String','No fertile zone','color', [1 0 0 ],...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
        annotation(gcf,'textbox',[.25 Ymin .1 .1],'String',strcat('L_{apex}= ',num2str(round(EarSize/2,1)),'cm'),'color', PhymeaColor,...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
        annotation(gcf,'textbox',[.65 Ymin .1 .1],'String',strcat('L_{base}= ',num2str(round(EarSize/2,1)),'cm'),'color', PhymeaColor,...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');

        X = [0.5 0.5] ;
        annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');

    else
        % Lines
        X = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical...
            (CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical] ;
        annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');

        X = [(CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base...
            (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base] ;
        annotation(gcf,'doublearrow',X,YsmallBars,'color', PhymeaColor,'HeadStyle','none');

        % Text :
        annotation(gcf,'textbox',[.45 Ymin .1 .1],'String',strcat('L_{fertile}= ',Lfertile,'cm'),'color', PhymeaColor,'FitBoxToText','on','fontweight','bold');
        annotation(gcf,'textbox',[.25 Ymin .1 .1],'String',strcat('L_{apex}= ',Lapex,'cm'),'color', PhymeaColor,...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
        annotation(gcf,'textbox',[.65 Ymin .1 .1],'String',strcat('L_{base}= ',Lbase,'cm'),'color', PhymeaColor,...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');

    end

    % Annotate diameter :
    
    HalfDiameter = (obj.earMaxDiameter/ImSize(1)) * Scaling /2 ; 
    Xdiam = [0.5+(gcaLength/(2*FigureLength)) 0.5+(gcaLength/(2*FigureLength))  ] ;
    Ydiam = [ 0.5-HalfDiameter 0.5+HalfDiameter   ] ;
              
%     ((FigureWidth/2)-(obj.earMaxDiameter*Scaling))/FigureWidth...
%          ((FigureWidth/2)+(obj.earMaxDiameter*Scaling))/FigureWidth] ;
    annotation(gcf,'doublearrow',Xdiam,Ydiam,'color', PhymeaColor,'HeadStyle','hypocycloid');
    annotation(gcf,'textbox',[0.5+(gcaLength/(2*FigureLength)) 0.46 .1 .1],...
        'String',strcat('D_{max}= ',num2str(round(EarDiam,1)),'cm'),...
        'color', PhymeaColor,'FitBoxToText','on','fontweight','bold','EdgeColor','none');

    % Grain size :
    % ------------
    
    Ydim = mean(obj.GrainsAttributes.ringDimensions.Ydim);
    Xdim = mean(obj.GrainsAttributes.ringDimensions.Xdim);
    Largeur = min(round(Ydim,1),round(Xdim,1));
    Longueur = max(round(Ydim,1),round(Xdim,1));
    NbRanks = num2str(round((obj.RanksCount.Mid)/3,1));
    NbGpR = num2str(round((obj.GrainPerRanksCount.Bot+obj.GrainPerRanksCount.Mid+obj.GrainPerRanksCount.Top),1));

    annotation(gcf,'rectangle',[Xmin+0.005 0.7 0.13 0.2],'color', [0 0.66 0],'FaceColor', [0.5 0.5 0.5],'FaceAlpha',0.3 )
    annotation(gcf,'textbox',[Xmin 0.90 0.1 0.1],...
        'String','Grain dimensions :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none');
    
    annotation(gcf,'rectangle',[Xmax+0.005 0.7 0.16 0.2],'color', [0 0.66 0],'FaceColor', [0.5 0.5 0.5],'FaceAlpha',0.3)
    annotation(gcf,'textbox',[Xmax 0.90 0.1 0.1],...
        'String','Grain organisation :','color', [1 1 1],'FitBoxToText','on','fontweight','bold','EdgeColor','none'); 
    
    % Orientation :
    if isnan(Base) || isnan(Apical)

        annotation(gcf,'textbox',[0.025 0.8 0.1 0.1],...
            'String','Probably no kernel','color', [1 0 0],...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
        annotation(gcf,'textbox',[0.82 0.8 0.1 0.1],...
            'String','Probably no kernel','color', [1 0 0],...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
        
    else

        if Largeur == round(Xdim,1)
            W =  (Largeur/ImSize(2)) * Scaling;
            L=  (Longueur/ImSize(1)) * Scaling;
        else
            W =  (Longueur/ImSize(2)) * Scaling;
            L=  (Largeur/ImSize(2)) * Scaling;
        end

%         annotation(gcf,'ellipse',[0.035 0.70 W L],'color', [0 0.66 0],'FaceColor',[0 0.66 0])
%         annotation(gcf,'doublearrow',...
%             [0.035 0.035+Largeur/(FigureLength*2)],...
%             [0.8 0.8],...
%             'color', [0 0.66 0],'HeadStyle','hypocycloid');
%         annotation(gcf,'doublearrow',...
%             [0.025 0.025],...
%             [0.70 0.70+Longueur/(FigureWidth*2)],...
%             'color', [0 0.66 0],'HeadStyle','hypocycloid');

        % Values :
        annotation(gcf,'textbox',[Xmin+0.005 0.81 0.1 0.1],...
            'String',strcat('G_{length}= ',num2str(round(Largeur*obj.PX2CM,2)),'cm'),'color', [0 0.66 0],...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
        annotation(gcf,'textbox',[Xmin+0.005 0.72 0.1 0.1],...
            'String',strcat('G_{width}= ',num2str(round(Longueur*obj.PX2CM,2)),'cm'),'color', [0 0.66 0],...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');

        annotation(gcf,'textbox',[Xmax+0.005 0.81 0.1 0.1],...
            'String',strcat('Ranks=',NbRanks),'color', [0 0.66 0],...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
        annotation(gcf,'textbox',[Xmax+0.005 0.72 0.1 0.1],...
            'String',strcat('Grains per rank=',NbGpR),'color', [0 0.66 0],...
            'FitBoxToText','on','fontweight','bold','EdgeColor','none');
    
    end

    
    % Date and Time / Ear / Face :
    % ----------------------------
    Code = obj.code;
    cut1 = strsplit(Code,'.');
    cut2 = strsplit(char(cut1(2)),'U');
    Num_Ear = num2str((str2double(char(cut2(1)))-1)*3+str2double(char(cut2(2))));
    Code_Ear = cut1(1);
    Num_Face = num2str(obj.numero_face);
    t = datetime('now');

    annotation(gcf,'textbox',[0.25 0.9 0.1 0.1],...
        'String',strcat(Code_Ear{1},'   |   Ear N°',Num_Ear,'   |   Face N°',' ',Num_Face),...
        'color', [0.4 0.4 0.4],'FitBoxToText','on','fontweight','bold','EdgeColor','none','Interpreter', 'none','FontSize',10);

    annotation(gcf,'textbox',[Xmax Ymin-0.03 0.1 0.1],...
        'String',char(t),'color', [0.4 0.4 0.4],'FitBoxToText','on','fontweight','bold','EdgeColor','none','Interpreter', 'none');
    annotation(gcf,'textbox',[Xmax Ymin+0.03 0.1 0.1],...
        'String','Time of analysis :','color', [0.4 0.4 0.4],'FitBoxToText','on','fontweight','bold','EdgeColor','none','Interpreter', 'none');


    % Grain number :
    % --------------
    if isnan(Base) || isnan(Apical)
        
    annotation(gcf,'textbox',[0.25 Ymax-0.075 0.1 0.1],...
        'String','No grain detected',...
        'color', [1 0 0],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',10);

    else
        
    annotation(gcf,'textbox',[0.25 Ymax-0.075 0.1 0.1],...
        'String',strcat('Estimated grain number =',' ',num2str(round(obj.GrainsAttributes.NbGr,0))),...
        'color', [0 0.66 0],'FitBoxToText','on','fontweight','bold','EdgeColor','none','FontSize',10);
        
        
    end
    

hold off

            

