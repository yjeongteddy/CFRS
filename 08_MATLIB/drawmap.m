function varargout = drawmap(llon,rlon,blat,ulat)
% How to add a marker and text on m_map
%{

sample = m_plot(lon, lat, 's', 'markersize', 15, 'markerfacecolor', 'none', 
'markeredgecolor', 'k', 'linestyle', 'none', 'linewidth', 2)

m_text(lon, lat, 'Hello world!', 'fontsize', 18, fontweight, 'b')

%}

%% Set target area and load bottom topography data
lon1 = llon;
lon2 = rlon;
lat1 = blat;
lat2 = ulat;

%% Get a targeted sheet
clf;hold on;set(gcf,'position',[2237 2 1429 993]);
m_proj('mercator','lon',[lon1 lon2],'lat',[lat1 lat2]);

%% Fill land with gray and get a fancy box outline
m_gshhs_h('patch',[0.9373,0.8667,0.7255]);
m_grid('linestyle','none','tickdir','in','fontsize',20);

%% Get title, xlabel and ylabel
xlabel('Longitude (\circE)');
ylabel('Latitude (\circN)');
set(gca, 'Box', 'on', 'Linewidth', 3, 'fontsize',20);
set(gcf, 'Color', 'w')
end






