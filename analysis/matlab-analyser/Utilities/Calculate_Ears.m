% Code to loop and calculate over ears : 

%% 1/ Ear masking : 

workspace = uigetdir('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0','Select a working directory');

cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\ear_masking')
ear_masking


%% 2/ Calculate variables outputs :


workspace = uigetdir('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0','Select a working directory');


cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0')

% Get all the ear codes in the folder : 
dpath = strcat(workspace,'\data');
earList = cellstr(ls(fullfile(strcat(workspace,'\data'))));
earList=earList(~ismember(earList,{'.','..'}));

Outputs.Data = nan((length(earList))*6,15);
Outputs.Codes = earList;
Outputs.Vars = {'Face','Longueur','Largeur','NbrBot_New','NbrMid_New','NbrTop_New','NbrBot_Old','NbrMid_Old','NbrTop_Old','NbGpRmax','l_fertile','l_apical','l_basal','NbGpR'};


%cd(workspace)
%fileID = fopen('Outputs.txt','a');
%fprintf(fileID, '%s;', Outputs.Vars{:});
%fprintf(fileID, 'test');
%fclose(fileID);

% Loop over codes : 
for ear  = 1: length(earList)
    
    % Loop over face : 
    for face = 1:6
        
        code = earList{ear};
        ear;
        obj = FaceEarClass(dpath, code,face);

        Outputs.Data(((ear-1)*6+face),1)=face;
        Outputs.Data(((ear-1)*6+face),2)=obj.horzAxisLength*obj.PX2CM;
        Outputs.Data(((ear-1)*6+face),3)=obj.earMaxDiameter*obj.PX2CM;
        Outputs.Data(((ear-1)*6+face),4)=obj.ringCount2.bot;
        Outputs.Data(((ear-1)*6+face),5)=obj.ringCount2.mid;
        Outputs.Data(((ear-1)*6+face),6)=obj.ringCount2.top;
        Outputs.Data(((ear-1)*6+face),7)=obj.ringCount.ringCountAvgBot;
        Outputs.Data(((ear-1)*6+face),8)=obj.ringCount.ringCountAvgMid;
        Outputs.Data(((ear-1)*6+face),9)=obj.ringCount.ringCountAvgTop;
        
        % Calculate nbrGpR : 
        sortedFileLength = obj.horzFilesProps.sortedFileLength;
        NbGpR = mean(sortedFileLength(~(abs(sortedFileLength(1)-sortedFileLength)>0.5*std(sortedFileLength))));
        Outputs.Data(((ear-1)*6+face),10)=NbGpR;
        
        % Calculate zones : 
        [A,F,B] = obj.fertileZoneMaskDimensions(0.5,0.5);
        
        % If non kernel fertile :
        if any([isnan(A) isnan(F) isnan(B)])
            F = 0;
            A = (obj.horzAxisLength*obj.PX2CM)/2;
            B = (obj.horzAxisLength*obj.PX2CM)/2;
        end
            
        l_fertile = F;
        Outputs.Data(((ear-1)*6+face),11)=l_fertile*obj.PX2CM;
        l_apical = A;
        Outputs.Data(((ear-1)*6+face),12)=l_apical*obj.PX2CM;
        l_basal = B;
        Outputs.Data(((ear-1)*6+face),13)=l_basal*obj.PX2CM;
        Outputs.Data(((ear-1)*6+face),14)=gpr(obj);
        
        %show some images
        figure(1)
        obj.showHorzFileImage
        print('-f1',strcat(fullfile(dpath,code,num2str(face)),'/FullySegmented.png'),'-dpng');
        close(gcf)
    
    end
    
    save('OutputsStructure2.mat','Outputs')

end

%%% Intégrations dans le code : 

% Sortie de la surface du masque épi
% Sortie de la surfacer du masque des grains finaux
% Quelle image sortir ?
% Images issues de la discussion avec romain : positionnement de traits de
% longueur fertile, basale et apicale 



%% Outputfile  : 

%%%%%%%  Outfile : %%%%%

cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\data\Caractérisation manuelle\Données')
fileID = fopen('Output_Meabox.txt','wt') ; 
fprintf(fileID,'%s;','Code','Code_epi',Outputs.Vars{:});
fprintf(fileID,'\n');
code_epi = 1;

for code =1: length(Outputs.Codes)
       
    for face = 1:6
        
        Code = Outputs.Codes{code};
        cut1 = strsplit(Code,'.');
        cut2 = strsplit(char(cut1(2)),'U');
        code_epi = (str2num(char(cut2(1)))-1)*3+str2num(char(cut2(2)));
        
        % Code et face : 
        fprintf(fileID,'%s%s',Code,';') ;
        fprintf(fileID,'%01.0f%s',uint8(code_epi),';') ;        
        fprintf(fileID,'%d%s',face,';') ;   
        fprintf(fileID,'%2.3f;',Outputs.Data(((code-1)*6+face),2:14));
        fprintf(fileID,'\n');
        
    end
    
    
end

fclose(fileID);



%% Test d'épis : 

% Initialisation : 
cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0')
workspace = uigetdir('E:\Phymea\Meabox\Meabox_v0.4.0\data\Test','Select a working directory');
dpath = 'E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\data\Test';

% Définir les épis : 
Codes = {'MAU17-PG_13_WD2_382_2_29.1U2'};
ID = zeros(length(Codes),1);
Nepi = zeros(length(Codes),1);

for code = 1: length(Codes)
    cut1 = strsplit(Codes{code},'.');
    cut2 = strsplit(char(cut1(1)),'_');
    ID(code) =  str2num(char(cut2(4)));
    Nepi(code) = str2num(char(cut2(5))) ; 
end

        
% Recuperer la mesure : 
cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\data\Test')
data = csvread('Pheno_Ear_v1.csv',';');
Measured_Data = readtable('Pheno_Ear_Phymea_PG.csv');

% Calculate ears : 
for face = 1 %:6
    
    
    obj = FaceEarClass(dpath, Codes{1},face);
    Test.face(face,1)=face;
    Test.longueur(face,2)=obj.horzAxisLength*obj.PX2CM;
    Test.longueur(face,3)=obj.earMaxDiameter*obj.PX2CM;
    Test.NbrBot_New(face,4)=obj.ringCount2.bot;
    Test.NbrMid_New(face,5)=obj.ringCount2.mid;
    Test.NbrTop_New(face,6)=obj.ringCount2.top;
    Test.NbrBot_Old(face,7)=obj.ringCount.ringCountAvgBot;
    Test.NbrMid_Old(face,8)=obj.ringCount.ringCountAvgMid;
    Test.NbrTop_Old(face,9)=obj.ringCount.ringCountAvgTop;

end

    
Test.face(face,1)=face;
Test.longueur(face,2)=obj.horzAxisLength*obj.PX2CM;
Test.longueur(face,3)=obj.earMaxDiameter*obj.PX2CM;
Test.NbrBot_New(face,4)=obj.ringCount2.bot;
Test.NbrMid_New(face,5)=obj.ringCount2.mid;
Test.NbrTop_New(face,6)=obj.ringCount2.top;
Test.NbrBot_Old(face,7)=obj.ringCount.ringCountAvgBot;
Test.NbrMid_Old(face,8)=obj.ringCount.ringCountAvgMid;
Test.NbrTop_Old(face,9)=obj.ringCount.ringCountAvgTop;
        
    % Calculate nbrGpR : 
    Test.NbGpR(face,10)=gpr(obj);
        
    % Calculate zones : 
    [A,F,B] = obj.fertileZoneMaskDimensions(0.5,0.5);
        
    % If non kernel fertile :
    if any([isnan(A) isnan(F) isnan(B)])
        F = 0;
        A = (Test.longueur(face,2))/2;
        B = (Test.longueur(face,2))/2;
    end
            
    l_fertile = F;
    Test.l_fertile(face,11)=l_fertile*obj.PX2CM;
    l_apical = A;
    Test.l_apical(face,12)=l_apical*obj.PX2CM;
    l_basal = B;
    Test.l_basal(face,13)=l_basal*obj.PX2CM;
   
    Test.NbGpR(face,10) = gpr(obj);
    
    %show some images
    %figure(face)
    %obj.showHorzFileImage
    
    end


%% 4/ Last Calculatation of variables outputs :


workspace = 'E:\Phymea\Technique\MeaBox\Meabox_v0.4.0\data\Caractérisation manuelle compléte' ;
cd('E:\Phymea\Technique\MeaBox\Meabox_v0.4.0')

% Get all the ear codes in the folder : 
dpath = strcat(workspace,'\data');
earList = cellstr(ls(fullfile(strcat(workspace,'\data'))));
earList=earList(~ismember(earList,{'.','..'}));

Outputs.Data = nan((length(earList))*6,15);
Outputs.Codes = earList;
Outputs.Vars = {'Face','Longueur','Largeur','NbrBot_New','NbrMid_New','NbrTop_New','NbrBot_Old','NbrMid_Old','NbrTop_Old',... % 1-9
                'NbGpRmax','l_fertile','l_apical','l_basal','NbGpR',... % 10-14
                'NbGpR_New_Bot','NbGpR_New_Mid','NbGpR_New_Top',... % 15-17
                'NbGpR_New_BotMax','NbGpR_New_MidMax','NbGpR_New_TopMax',... % 18-20
                'SurfGrains','SurfEar','GrainRatio','MeanGrainSurf','NbGr'}; % 19-23
Outputs.ringDimensions = {};

% Calculate ears : 
tmwMultiWaitbar('Analysing images and saving data',0);
% Loop over codes : 
for ear  = 1 : 3 % : length(earList)
    
    % Loop over face : 
    for face = 1:6
        
        code = earList{ear};
        
        obj = FaceEarClass(dpath, code,face);

        Outputs.Data(((ear-1)*6+face),1)=face;
        Outputs.Data(((ear-1)*6+face),2)=obj.horzAxisLength*obj.PX2CM;
        Outputs.Data(((ear-1)*6+face),3)=obj.earMaxDiameter*obj.PX2CM;
        Outputs.Data(((ear-1)*6+face),4)=obj.RanksCount.Bot;
        Outputs.Data(((ear-1)*6+face),5)=obj.RanksCount.Mid;
        Outputs.Data(((ear-1)*6+face),6)=obj.RanksCount.Top;
        Outputs.Data(((ear-1)*6+face),7)=obj.ringCount.ringCountAvgBot;
        Outputs.Data(((ear-1)*6+face),8)=obj.ringCount.ringCountAvgMid;
        Outputs.Data(((ear-1)*6+face),9)=obj.ringCount.ringCountAvgTop;
        
        % Calculate nbrGpR : 
        sortedFileLength = obj.horzFilesProps.sortedFileLength;
        NbGpR = mean(sortedFileLength(~(abs(sortedFileLength(1)-sortedFileLength)>0.5*std(sortedFileLength))));
        Outputs.Data(((ear-1)*6+face),10)=NbGpR;
        
        % Calculate zones : 
        [A,F,B] = obj.fertileZoneMaskDimensions(0.5,0.5);
        
        % If non kernel fertile :
        if any([isnan(A) isnan(F) isnan(B)])
            F = 0;
            A = (obj.horzAxisLength*obj.PX2CM)/2;
            B = (obj.horzAxisLength*obj.PX2CM)/2;
        end
            
        l_fertile = F;
        Outputs.Data(((ear-1)*6+face),11)=l_fertile*obj.PX2CM;
        l_apical = A;
        Outputs.Data(((ear-1)*6+face),12)=l_apical*obj.PX2CM;
        l_basal = B;
        Outputs.Data(((ear-1)*6+face),13)=l_basal*obj.PX2CM;
        Outputs.Data(((ear-1)*6+face),14)=gpr(obj);
        
        Outputs.Data(((ear-1)*6+face),15)=obj.GrainPerRanksCount.Bot;
        Outputs.Data(((ear-1)*6+face),16)=obj.GrainPerRanksCount.Mid;
        Outputs.Data(((ear-1)*6+face),17)=obj.GrainPerRanksCount.Top;
        
        Outputs.Data(((ear-1)*6+face),18)=obj.GrainPerRanksCount.MaxBot;
        Outputs.Data(((ear-1)*6+face),19)=obj.GrainPerRanksCount.MaxMid;
        Outputs.Data(((ear-1)*6+face),20)=obj.GrainPerRanksCount.MaxTop;        
        
        Outputs.Data(((ear-1)*6+face),21) = obj.GrainsAttributes.SurfGrains ;
        Outputs.Data(((ear-1)*6+face),22) = obj.GrainsAttributes.SurfEar;
        Outputs.Data(((ear-1)*6+face),23) = obj.GrainsAttributes.MeanGrainSurf ;
        Outputs.Data(((ear-1)*6+face),24) = obj.GrainsAttributes.NbGr;
        

        Outputs.ringDimensions{(ear-1)*6+face} = obj.GrainsAttributes.ringDimensions ;

        showAndSaveResultsImage(obj,35,8);
        %show some images
%         figure(1)
%         obj.showHorzFileImage
%         print('-f1',strcat(fullfile(dpath,code,num2str(face)),'/FullySegmented.png'),'-dpng');
%         close(gcf)
    
        tmwMultiWaitbar('Analysing images and saving data', ((ear-1)*6)+face / (3*6) )
        
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

%% Outputfile  : 

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


%% Test tailles de grains : 

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

%% Plot par face : 


ImSize = size(obj.mask);
FigureLength = ImSize(2)/2 ; 
FigureWidth = ImSize(1)/2 ; 
EarSize = obj.horzAxisLength*obj.PX2CM ;
EarDiam = obj.earMaxDiameter*obj.PX2CM ;
EarMaxLength = 35 ; %cm
EarMaxDiam = 8  ; %cm
Scaling = (EarSize/EarDiam) / (EarMaxLength/EarMaxDiam) ;
gcaLength = EarSize/EarMaxLength*FigureLength;
gcaWidth = EarDiam/EarMaxDiam*FigureWidth;
RGB = obj.RGBImage ;
Grains = label2rgb(obj.horzFilesProps.IfilesColor, 'jet', 'k', 'shuffle') ; 
SegmentedImage = obj.refinedSegmentation ; 
Lfertile = num2str(round(obj.ZoneMasks.FertileZone*obj.PX2CM,1));
Lapex = num2str(round(obj.ZoneMasks.ApexAbortion*obj.PX2CM,1));
Lbase = num2str(round(obj.ZoneMasks.BasalAbortion*obj.PX2CM,1)) ;

figure(1),hold on       % add first plot in 2 x 1 grid

    set(gcf,'units','pixels','position',[10,10,FigureLength,FigureWidth],'Color',[0 0 0])

    set(gca,'units','pixels',...
        'position',[(FigureLength/2)-(gcaLength/2),(FigureWidth/2)-(gcaWidth/2),gcaLength,gcaWidth],...
        'Visible','on',...
        'XLim',[0 ImSize(2)*Scaling],...
        'YLim',[0 ImSize(1)*Scaling])
    
    imshow(imresize(RGB, Scaling),'Parent', gca)
    him = imshow(imresize(obj.horzFilesProps.IfilesColor, Scaling),'Parent', gca);
    him.AlphaData = 0.5;
% 
%     BlueMask = label2rgb(obj.horzFilesProps.IfilesColor, 'jet', 'k', 'shuffle'); 
%     Blue = cat(zeros(ImSize),BlueMask(:,:,2),zeros(ImSize))
%     BlueMask(~0,~0,1) = 0;
%     BlueMask(~0,~0,3) = 0;
%     him = imshow(imresize(BlueMask, Scaling));
%     him.AlphaData = 0.3;
            
    % Longueur de l'épi : 
    CurrentAxes = gca ;
    CurrentFigure = gcf ; 
    ApexEpi = (1-(find(sum(obj.mask),1,'last')/length(obj.mask)))*gcaLength /FigureLength  ;
    BaseEpi = find(sum(obj.mask),1,'first')/length(obj.mask)*gcaLength /FigureLength ;
    Base = B/length(obj.mask)*gcaLength /FigureLength ;
    Apical =  A/length(obj.mask)*gcaLength /FigureLength; 
    X = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+0.02...
        (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-0.02] ;
    Y = [0.2 0.2 ] ;
    annotation(gcf,'doublearrow',X,Y,'color', [0 0.66 0],'HeadStyle','none');
    annotation(gcf,'textbox',[.45 .07 .1 .1],'String',strcat('L_{fertile}= ',Lfertile,'cm'),'color', [0 0.66 0],'FitBoxToText','on');
    
    X = [(CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical+0.02...
         (CurrentAxes.Position(1))/CurrentFigure.Position(3)+ApexEpi+Apical+0.02] ;
    Y = [0.17 0.23] ;
    annotation(gcf,'doublearrow',X,Y,'color', [0 0.66 0],'HeadStyle','none');
    annotation(gcf,'textbox',[.2 .07 .1 .1],'String',strcat('L_{apex}= ',Lapex,'cm'),'color', [0 0.66 0],'FitBoxToText','on');

    X = [(CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base-0.02...
        (CurrentAxes.Position(1)+CurrentAxes.Position(3))/CurrentFigure.Position(3)-BaseEpi-Base-0.02] ;
    Y = [0.17 0.23] ;
    annotation(gcf,'doublearrow',X,Y,'color', [0 0.66 0],'HeadStyle','none');
    annotation(gcf,'textbox',[.7 .07 .1 .1],'String',strcat('L_{base}= ',Lbase,'cm'),'color', [0 0.66 0],'FitBoxToText','on');

    
    % Diametre de l'épi : 
    X = [0.76 0.76] ;
    Y = [((FigureWidth/2)-(obj.earMaxDiameter*Scaling/ImSize(1)*gcaWidth/2))/FigureWidth...
        ((FigureWidth/2)+(obj.earMaxDiameter*Scaling/ImSize(1)*gcaWidth/2))/FigureWidth] ;
    annotation(gcf,'doublearrow',X,Y,'color', [0 0.66 0],'HeadStyle','none');    
    annotation(gcf,'textbox',[0.77 0.45 .1 .1],'String',strcat('D_{max}= ',num2str(round(EarDiam,1)),'cm'),...
        'color', [0 0.66 0],'FitBoxToText','on');
    
hold off
  

%%

    imshow(label2rgb(obj.horzFilesProps.IfilesColor, 'jet', 'k', 'shuffle'),'InitialMagnification', 500)
    h = imgca();
    ImSize = size(obj.horzFilesProps.IfilesColor);
    
        % imagesc(IfilesColor)
        imshow((obj.highCutSegmentationLabels>1)*0.45+obj.mask*0.4);
        hold on
        him = imshow(label2rgb(IfilesColor, 'jet', 'k', 'shuffle'));
        him.AlphaData = 0.6;
            
    % Longueur : 
    X = [h.Position(1) h.Position(3) ];
    Y = [0.1 0.1 ];
    annotation('doublearrow',X,Y,'color', [0 0.66 0]);
    
    hold off
    

    % Diam : 
    X = [h.Position(3) h.Position(3) ];
    Y = [h.Position(4) h.Position(2) ];
    annotation('doublearrow',X,Y,'color', [0 0.66 0]);
    
    
    start = find(sum(obj.mask),1,'last');
    stop = find(sum(obj.mask),1,'first');
    xrange = find(sum(obj.mask),1,'last') - find(sum(obj.mask),1,'first');
    h = imgca(2)
    %ax1 = axes('Position',[0 0 1 1],'Visible','off');
    %ax2 = axes('Position',[.3 .1 .6 .8]);

    X = [h.Position(1) h.Position(3) ]
    Y = [h.Position(2) h.Position(4) ]
    X = [find(sum(obj.mask),1,'last')/length(obj.mask) ...
        find(sum(obj.mask),1,'first')/length(obj.mask)];
    Y = [0.2 ...
        0.2];
    annotation('arrow',X,Y,'color','red');
    
hold off


