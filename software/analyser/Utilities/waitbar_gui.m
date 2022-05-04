figure('units','pixels','position',[200 200 540 140],...
       'name','A simple code to use a waitbar inside gui',...
       'menubar','none','numbertitle','off','resize','off');
ax1=axes('Units','pix','Position',[20 40 500 20]);
set(ax1,'Xtick',[],'Ytick',[],'Xlim',[0 1000]);
box on;
ax2=axes('Units','pix','Position',[20 80 500 20]);
set(ax2,'Xtick',[],'Ytick',[],'Xlim',[0 1000]);
box on;
k=800;
for i=1:k
    axes(ax1)
    cla
	rectangle('Position',[0,0,1001-(round(1000*i/k)),20],'FaceColor','b');
    text(482,10,[num2str(100-round(100*i/k)),'%']);
    axes(ax2)
    cla
	rectangle('Position',[0,0,(round(1000*i/k))+1,20],'FaceColor','r'); 
    text(480,10,[num2str(round(100*i/k)),'%']);
    pause(0.01)
end
