function PostADCIRC(tgt_tc, tgt_NPP, intensity, SeaLevel, tc_int, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Parameters
if nargin < 1, tgt_tc    = '1215_BOLAVEN'; end
if nargin < 2, tgt_NPP   = 'HANBIT'; end
if nargin < 3, intensity = '1.30-10'; end
if nargin < 4, SeaLevel  = '10exH+SLR'; end
if nargin < 5, tc_int    = '0%'; end
if nargin < 6, rpath     = '/home/user_006/01_WORK/2025/NPP'; end

switch SeaLevel
    case '10exH+SLR_org'
        subdir = 'MAX_org';
    case '10exL_org'
        subdir = 'MIN_org';
    case 'AHHL'
        subdir = '';
end

opath = fullfile(rpath, '05_DATA/processed');
dpath = fullfile(opath, tgt_NPP);
wpath = fullfile(dpath, tgt_tc, '12_ADCIRC', subdir, intensity);
fpath = fullfile(rpath, '04_FIGURE');
spath = fullfile(fpath, tgt_NPP, tgt_tc, 'SSH', subdir, intensity);
if ~exist(spath, 'dir'), mkdir(spath); end

%% Load universal params
fgs = grd_to_opnml(fullfile(dpath, SeaLevel, 'fort.14'));

cd(wpath)
% fgs = grd_to_opnml('fort.14');
switch subdir
    case 'MAX_org'
        load('maxSSH.mat')
    case 'MIN_org'
        load('minSSH.mat')
end

if contains(intensity,'+10') % if you deal with 10% windfield strengthed
    tc_vel = '+10%'; % for specification
elseif contains(intensity,'-10')
    tc_vel = '-10%';
else
    tc_vel = '0%';
end

%% Do the work (Large area)
clf;hold on;set(gcf,'position',[275 -3 1429 993]);
switch subdir
    case 'MAX_org'
        colormesh2d(fgs,maxSSH);
    case 'MIN_org'
        colormesh2d(fgs,minSSH);
end
axis equal; c = colorbar();
colormap(jet); clim([-1 1]); ax = gca;
% title([tgt_tc ' ' tg_case],'Interpreter', 'none');
% title(c,'[m]');
xlabel('Longitude (^oE)');
ylabel('Latitude (^oN)');
xlim([120 140]); ylim([26 45]);
c.Ruler.TickLabelFormat = '%.1f';
set(gca,'FontSize',25);
set(gca,'Box','on');
set(gca,'LineWidth',3);
set(gcf,'Color','w');
set(gca,'Color',[239 220 185]/255);
set(gcf, 'InvertHardcopy', 'off');

print(gcf, fullfile(spath, 'SSH_Large.png'), '-dpng', '-r300');

%% Do the work (Small area)
% load coastline data
switch tgt_NPP
    case 'SAEUL'
        COAST = load('/home/user_006/03_DATA/NEW_KR_Coastline_230206.mat').NEW_KR;
        xs = 129.29; xe = 129.36; ys = 35.29; ye = 35.36;
    case 'HANBIT'
        COAST = load('/home/user_006/03_DATA/HB_NewCoastlines.mat').COAST;
        xs = 126.38; xe = 126.43; ys = 35.38; ye = 35.45;
end
toRemove = arrayfun(@(c) any(c.X > xs & c.X < xe & c.Y > ys & c.Y < ye) && (length(c.X) < 200), COAST);
N_C = COAST(~toRemove);

% create mesh with target resolution
x_vec = xs:0.0001:xe;
y_vec = ys:0.0001:ye;
[x_mat,y_mat] = meshgrid(x_vec, y_vec);

% surge height on niche super variable -> set color shading range on its own
c_range{1} = [60,66];
c_range{2} = [80 100];
c_range{3} = [55 65];
c_range{4} = [75 85];
c_range{5} = [45 55];

range = c_range{2};

clf;hold on;set(gcf,'position',[310 -3 1376 993]);
switch subdir
    case 'MAX_org'
        maxSSH_INTP = griddata(fgs.x(~isnan(maxSSH)),fgs.y(~isnan(maxSSH)), ...
            double(maxSSH(~isnan(maxSSH))),x_mat,y_mat,'linear'); % linear interp on target resolution
        maxSSH = maxSSH_INTP;

        c_range{1} = [40 100];
        c_range{2} = [75 95];
        c_range{3} = [60 70];
        c_range{4} = [60 66];
        c_range{5} = [55 65];
        c_range{6} = [45 55];
        c_range{7} = [40 50];
        c_range{8} = [55 95];
        
        range = c_range{1};
        
        h = pcolor(x_mat, y_mat, maxSSH*100);
        clim([range(1) range(2)]);
        [C, h_c] = contour(x_mat, y_mat, maxSSH*100, range(1):1:range(2), 'Color', 'w'); colormap(jet);
    case 'MIN_org'
        minSSH_INTP = griddata(fgs.x(~isnan(minSSH)),fgs.y(~isnan(minSSH)), ...
            double(minSSH(~isnan(minSSH))),x_mat,y_mat,'linear'); % linear interp on target resolution
        minSSH = minSSH_INTP;
        
        c_range{1} = [-10 0];
        c_range{2} = [-30 -10];
        c_range{3} = [-20 -5];
        c_range{4} = [-30 0];
        c_range{5} = [-250 -50];
        
        range = c_range{5};
        
        h = pcolor(x_mat, y_mat, minSSH*100);
        clim([range(1) range(2)]);
        [C, h_c] = contour(x_mat, y_mat, minSSH*100, range(1):10:range(2), 'Color', 'k'); colormap(flipud(jet));
end
clabel(C,h_c,'LabelSpacing',500,'Color','w','FontWeight','b','FontSize',18);
for c_id = 1:length(N_C)
    fill(N_C(c_id).X,N_C(c_id).Y,[239 220 185]/255);
end
axis equal;
c = colorbar();
colormap(jet);
xlabel('Longitude (\circE)');
ylabel('Latitude (\circN)');
xtickformat('%.2f');
ytickformat('%.2f');
xlim([min(x_mat(:)) max(x_mat(:))]);
ylim([min(y_mat(:)) max(y_mat(:))]);
set(h,'EdgeColor','None');
set(gca,'FontSize',25);
set(gca,'Box','on');
set(gca,'LineWidth',3);
set(gcf,'Color','w');

rectangle('Position',[x_vec(6) y_vec(end-6)-0.013 0.026 0.013],'EdgeColor','k','FaceColor','w','LineWidth',2)
x_s = xs; y_s = ye;
text(x_s+0.001,y_s-0.0010,'[Specifications]','FontWeight','bold','VerticalAlignment','top','FontSize',20);
text(x_s+0.001,y_s-0.0035,['TC Name' ' : ' strrep(tgt_tc,'_',' ')],'VerticalAlignment','top','FontSize',18);
text(x_s+0.001,y_s-0.0060,['Intensity increment' ' : ' tc_int],'VerticalAlignment','top','FontSize',18);
text(x_s+0.001,y_s-0.0085,['Translation increment' ' : ' tc_vel],'VerticalAlignment','top','FontSize',18);
text(x_s+0.001,y_s-0.0110,['Unit' ' : ' 'cm'],'VerticalAlignment','top','FontSize',18);

print('-vector', fullfile(spath, 'SSH_Small.png'),'-dpng','-r300')
end

