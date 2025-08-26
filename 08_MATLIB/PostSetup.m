function PostSetup(tgt_tc, tgt_NPP, intensity, tc_int, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Set default parameters
if nargin < 1, tgt_tc    = '1215_BOLAVEN'; end
if nargin < 2, tgt_NPP   = 'HANBIT'; end
if nargin < 3, intensity = '1.30'; end
if nargin < 4, tc_int    = '33.8%'; end
if nargin < 5, rpath     = '/home/user_006/01_WORK/2025/NPP'; end

subdir = 'MAX_mod';
opath = fullfile(rpath, '05_DATA', 'processed');
dpath = fullfile(opath, tgt_NPP);
wpath = fullfile(dpath, tgt_tc, '13_SETUP', subdir, intensity);
fpath = fullfile(rpath, '04_FIGURE');
spath = fullfile(fpath, tgt_NPP, tgt_tc, 'SETUP', subdir, intensity);
if ~exist(spath, 'dir'), mkdir(spath); end

%% Do the work
% load coastline data
switch tgt_NPP
    case 'SAEUL'
        COAST = load('/home/user_006/03_DATA/NEW_KR_Coastline_230206.mat').NEW_KR;
        blon = 129.29; ulon = 129.35; blat = 35.31; ulat = 35.36;
    case 'HANBIT'
        COAST = load('/home/user_006/03_DATA/HB_NewCoastlines.mat').COAST;
        blon = 126.38; ulon = 126.43; blat = 35.38; ulat = 35.45;
end

toRemove = arrayfun(@(c) any(c.X > blon & c.X < ulon & c.Y > blat & c.Y < ulat) && (length(c.X) < 200), COAST);
N_C = COAST(~toRemove);

cd(wpath)
sFile = dir('*_SETUP.mat');
result = load(fullfile(sFile.folder, sFile.name));
fname = fieldnames(result);
setup = result.(fname{1});

[~, INPUT] = system('grep -n CGRID INPUT');

% suffix of translation speed
if contains(intensity,'+10')
    tc_vel = '+10%';
elseif contains(intensity,'-10')
    tc_vel = '-10%';
else
    tc_vel = '0%';
end

lines = strsplit(INPUT, '\n');
for j = 1:length(lines)
    line = lines{j};
    if contains(line, 'CGRID')
        tokens = split(line);
        vals = str2double(tokens);
        xs = vals(2);
        ys = vals(3);
        lx = vals(5);
        ly = vals(6);
        nx = vals(7);
        ny = vals(8);
    end
end

[slat, slon] = utm2ll(xs, ys, 52);
[elat, elon] = utm2ll(xs+lx, ys+ly, 52);
xVecOrg = linspace(slon, elon, nx+1);
yVecOrg = linspace(slat, elat, ny+1);

[xMatOrg, yMatOrg] = meshgrid(xVecOrg, yVecOrg);

% create target mesh grid
xVecItp = blon:0.0001:ulon;
yVecItp = blat:0.0001:ulat;
[xMatItp, yMatItp] = meshgrid(xVecItp, yVecItp);

% interpolate HS values
SETUP_INTP = griddata(xMatOrg(~isnan(setup)),yMatOrg(~isnan(setup)), ...
    double(setup(~isnan(setup))),xMatItp,yMatItp,'linear');

% plot it
clf;hold on;set(gcf,'position',[310 -3 1376 993]);
p = pcolor(xMatItp, yMatItp, SETUP_INTP); set(p, 'EdgeColor', 'None'); axis equal;
% caxis([0 1]); p = pcolor(xMatOrg, yMatOrg, setup); set(p, 'EdgeColor', 'None');
xlim([blon ulon]); ylim([blat ulat]);

% fill colors on land
for c_id = 1:length(N_C)
    fill(N_C(c_id).X,N_C(c_id).Y,[239 220 185]/255);
end

c = colorbar(); c.Ruler.TickLabelFormat = '%.1f';
colormap(jet);
xlabel('Longitude (\circE)');
ylabel('Latitude (\circN)');
xtickformat('%.2f')
ytickformat('%.2f')
xmin = min(xMatItp(:)); ymin = min(yMatItp(:));
xmax = max(xMatItp(:)); ymax = max(yMatItp(:));
xticks(xmin:0.01:xmax);
yticks(ymin:0.01:ymax);
set(gca,'FontSize',25);        
set(gca,'Box','on');
set(gca,'LineWidth',3);        
set(gcf,'Color','w');

rectangle('Position',[xVecItp(6) yVecItp(end-6)-0.013 0.026 0.013],'EdgeColor','k','FaceColor','w','LineWidth',2)
x_s = blon; y_s = ulat;
text(x_s+0.001,y_s-0.0010,'[Specifications]','FontWeight','bold','VerticalAlignment','top','FontSize',20);
text(x_s+0.001,y_s-0.0035,['TC Name' ' : ' strrep(tgt_tc,'_',' ')],'VerticalAlignment','top','FontSize',18);
text(x_s+0.001,y_s-0.0060,['Intensity increment' ' : ' tc_int],'VerticalAlignment','top','FontSize',18);
text(x_s+0.001,y_s-0.0085,['Translation increment' ' : ' tc_vel],'VerticalAlignment','top','FontSize',18);
text(x_s+0.001,y_s-0.0110,['Unit' ' : ' 'cm'],'VerticalAlignment','top','FontSize',18);

print('-vector', fullfile(spath, ['SETUP_' intensity '.png']), '-dpng', '-r300');
end

%{

tgt_lon = {126.4126, 126.415, 126.4173, 126.4196, 126.4217, 126.424};
tgt_lat = {35.4059, 35.4073, 35.4087, 35.41, 35.4114, 35.4127};
tgt_label = {'A','B','C','D','E','F'};

for i = 1:length(tgt_lon)
    plot(tgt_lon{i},tgt_lat{i},'r.', 'markersize',15)
end

new_lon = {126.4217, 126.4240}
new_lat = {35.4114, 35.4127}

for i = 1:length(new_lon)
    plot(new_lon{i},new_lat{i},'y.', 'markersize',8)
end

%}