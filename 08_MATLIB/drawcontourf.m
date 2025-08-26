function drawcontourf(settings)
% functin drawcontourf(mlon,mlat,clon,clat,ds,varargin)
%
% Plot a google map on the current axes and add depth contours
%
% USAGE:
% settings.NPP    = 'SAEUL';           % target NPP
% settings.mlon   = [129.306 129.328]; % grid for map
% settings.mlat   = [35.325 35.345];
% settings.clon   = settings.mlon;     % grid for contour 
% settings.clat   = settings.mlat;
% settings.dthctr = 1;                 % Whether or not plot depth contour
% settings.fgs    = fgs;               % FEM grid structure
% settings.xtickf = 3;                 % axis tick format
% settings.ytickf = 3;
% settings.xticki = 0.004;             % axis tick interval
% settings.yticki = 0.002;
% settings.crange = [0 35];            % colorbar axis limits
% settings.clevel = 0:2:35;            % contour levels 
% 
% drawcontourf(settings)

% Take input parametrs
NPP    = settings.NPP;
mlon   = settings.mlon;
mlat   = settings.mlat;
clon   = settings.clon;
clat   = settings.clat;
fgs    = settings.fgs;
dthctr = settings.dthctr;
xtickf = settings.xtickf;
ytickf = settings.ytickf;
xticki = settings.xticki;
yticki = settings.yticki;
crange = settings.crange;
clevel = settings.clevel;

%% Create meshgrid
lat_vec = mlat(1) : 0.01 : mlat(2);
lon_vec = mlon(1) : 0.01 : mlon(2);
[x_mat,y_mat] = meshgrid(lon_vec, lat_vec);

%% Plot map
clf; hold on; set(gcf,'position',[-1919 -4 1920 1003]);
for lat_id = 1:length(lat_vec)-1 
    for lon_id = 1:length(lon_vec)-1
        XLIM = [x_mat(lat_id,lon_id) x_mat(lat_id,lon_id+1)];
        YLIM = [y_mat(lat_id,lon_id) y_mat(lat_id+1,lon_id)];
        axis equal;
        fig = figure();
        xlim(XLIM); ylim(YLIM);
        [lonVec,latVec,imag] = plot_google_map('MapType','satellite','style','feature:all|color:0xff0000', ...
                                               'APIKey','AIzaSyA--EREY_h9EJFK9M9HDo0AT2Dd0EZSNmw','Resize',2);
        close(fig);
        sz = size(imag);
        sz_cut = int16(sz*0.1); sz_cut = sz_cut(1);
        image(lonVec(sz_cut : end-sz_cut), ...
              latVec(sz_cut : end-sz_cut), ...
              imag(sz_cut : end-sz_cut, sz_cut : end-sz_cut, :) ...
              );
        set(gca, 'YDir','normal');
        hold on;
    end
end
axis equal;
xlim([mlon(1) mlon(2)]); ylim([mlat(1) mlat(2)]);
xlabel('Longitude [\circE]');
ylabel('Latitude [\circN]')
set(gca, 'FontSize', 23)
clim(crange);
xtickformat(['%.' num2str(xtickf) 'f']); 
ytickformat(['%.' num2str(ytickf) 'f']);
xmin = mlon(1); ymin = mlat(1);
xmax = mlon(2); ymax = mlat(2);
xticks(xmin:xticki:xmax);
yticks(ymin:yticki:ymax);

%% Plot contour
if dthctr
    colormesh2d(fgs,fgs.z);colorbar();colormap('jet');
    xlim([xmin xmax]);
    ylim([ymin ymax]);
    clim(crange);

    latvec = clat(1) : 0.00001 : clat(2);
    lonvec = clon(1) : 0.00001 : clon(2);
    [lon_mat,lat_mat] = meshgrid(lonvec, latvec);
    z_mat = griddata(fgs.x,fgs.y,fgs.z,lon_mat,lat_mat);
    lpath = 'S:/home/user_006/01_WORK/2025/NPP/05_DATA/raw';
    land_id = load(fullfile(lpath,[NPP '_small_land_id.mat'])).land_id;
    z_mat(land_id) = NaN;
    [c,h] = contour(lon_mat,lat_mat,z_mat,clevel,'LineColor','k');
    clabel(c,h,'LabelSpacing',1000,'FontSize',16,'FontWeight','bold','Color','k');
end
end
%{

if dthctr
    latvec = clat(1) : 0.00001 : clat(2);
    lonvec = clon(1) : 0.00001 : clon(2);
    [lon_mat,lat_mat] = meshgrid(lonvec, latvec);
    
    z_mat = griddata(fgs.x,fgs.y,fgs.z,lon_mat,lat_mat);
    
    lpath = 'S:/home/user_006/01_WORK/2025/NPP/05_DATA/raw';
    land_id = load(fullfile(lpath,[NPP '_small_land_id.mat'])).land_id;
    
    z_mat(land_id) = NaN;
    
    [c,h] = contourf(lon_mat,lat_mat,z_mat,clevel,'LineColor','k');
    colormap(jet); colorbar();
    
    clabel(c,h,'LabelSpacing',1000,'FontSize',16,'FontWeight','bold','Color','k');
end

COAST = load('S:/home/user_006/03_DATA/HB_NewCoastlines_02.mat').COAST;

[m,n] = size(lon_mat);
land_id = false(m,n);
for i = 1:length(COAST)
    [in, ~] = inpolygon(lon_mat, lat_mat, COAST(i).X, COAST(i).Y);
    land_id = land_id | in;
end
lpath = 'S:/home/user_006/01_WORK/2025/NPP/05_DATA/raw';
save(fullfile(lpath,[NPP '_small_land_id.mat']), 'land_id', '-v7.3');
%}
