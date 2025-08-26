function GetDepthSetup(tgt_tc, tgt_NPP, SeaLevel, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Parameters
if nargin < 1, tgt_tc   = '1215_BOLAVEN'; end
if nargin < 2, tgt_NPP  = 'HANBIT'; end
if nargin < 3, SeaLevel = '10exH+SLR'; end
if nargin < 4, rpath    = '/home/user_006/01_WORK/2025/NPP'; end

switch SeaLevel
    case '10exH+SLR', subdir = 'MAX';
    case '10exL',     subdir = 'MIN';
    case 'AHHL',      subdir = '';
end

opath   = fullfile(rpath, '05_DATA', 'processed');
dpath   = fullfile(opath, tgt_NPP);
wpath_w = fullfile(dpath, tgt_tc, '10_SWAN', [subdir '_org']);
wpath_a = fullfile(dpath, tgt_tc, '12_ADCIRC', [subdir '_org']);
wpath_s = fullfile(dpath, tgt_tc, '13_SETUP', [subdir '_org']);
if ~exist(wpath_s, 'dir'), mkdir(wpath_s); end

%% Load coastline data
switch tgt_NPP
    case 'SAEUL'
        COAST = load('/home/user_006/03_DATA/NEW_KR_Coastline_230206.mat').NEW_KR;
    case 'HANBIT'
        COAST = load('/home/user_006/03_DATA/HB_NewCoastlines.mat').COAST;
end

%% NGRID info
dirNames = {dir(fullfile(wpath_w, '*')).name};
dirNames = dirNames(cellfun(@(n) ~ismember(n, {'.', '..'}), dirNames));

if exist(fullfile(dpath, 'dgrid.mat'), 'file') ~= 2
    [~, INPUT] = system(['cat ' fullfile(wpath_w, dirNames{1}, 'INPUT')]);
    
    idx_NEST  = strfind(INPUT, 'NGRID'); 
    info_NEST = INPUT(idx_NEST:idx_NEST+100);
    idx_STOP  = strfind(info_NEST, 'NESTOUT');
    info_NEST = info_NEST(1:idx_STOP-1);
    idx_blank = strfind(info_NEST, ' ');
    
    ngrid.xs = str2double(info_NEST(idx_blank(2)+1:idx_blank(3)-1));
    ngrid.ys = str2double(info_NEST(idx_blank(3)+1:idx_blank(4)-1));
    ngrid.lx = str2double(info_NEST(idx_blank(5)+1:idx_blank(6)-1));
    ngrid.ly = str2double(info_NEST(idx_blank(6)+1:idx_blank(7)-1));
    ngrid.nx = str2double(info_NEST(idx_blank(7)+1:idx_blank(8)-1));
    ngrid.ny = str2double(info_NEST(idx_blank(8)+1:end));
    
    dx = ngrid.lx/ngrid.nx;
    dy = ngrid.ly/ngrid.ny;
    
    % Target INPGRID BOTTOM
    inc = 250;
    
    xs = ngrid.xs-dx*inc;
    ys = ngrid.ys-dy*inc;
    
    xe = ngrid.xs+ngrid.lx+dx*inc;
    ye = ngrid.ys+ngrid.ly+dy*inc;
    
    x_vec = xs:dx:xe;
    y_vec = ys:dy:ye;
    
    [x_mat, y_mat] = meshgrid(x_vec, y_vec);
    
    dgrid.xs = xs;
    dgrid.ys = ys;
    dgrid.xe = xe;
    dgrid.ye = ye;
    dgrid.nx = int32((xe-xs)/dx); % SWAN takes this as an actual increment, not # of spacing
    dgrid.ny = int32((ye-ys)/dy);
    dgrid.dx = dx;
    dgrid.dy = dy;
    dgrid.mx = x_mat;
    dgrid.my = y_mat;
    
    save(fullfile(dpath, 'dgrid.mat'), 'dgrid')
else
    tgt_dg = load(fullfile(dpath, "dgrid.mat"));
    dgrid = tgt_dg.dgrid;
    x_mat = dgrid.mx; y_mat = dgrid.my;
end

%% Get indices of inland
if exist(fullfile(dpath,'landmask_FDM.mat'), 'file') == 2
    load(fullfile(dpath, 'landmask_FDM.mat'))
else
    [m,n] = size(x_mat);
    total_in = false(m,n);
    for i = 1:length(COAST)
        [in, ~] = inpolygon(x_mat, y_mat, COAST(i).X, COAST(i).Y);
        total_in = total_in | in;
    end
    save(fullfile(dpath, 'landmask_FDM.mat'), 'total_in', '-v7.3');
end

%% Get indices of inside FDM depth values
tgt_dth = load(fullfile(dpath, [SeaLevel '_org'], [SeaLevel '.mat']));
fname = fieldnames(tgt_dth);
raw_depth = tgt_dth.(fname{1});

raw_depth_FDM = griddata(raw_depth.x, raw_depth.y, raw_depth.z, x_mat, y_mat);

raw_depth_FDM(total_in) = -999;

%% Load FEM grid structure
% fgs = grd_to_opnml(fullfile(wpath_a, dirNames{1}, 'fort.14'));
fgs = grd_to_opnml(fullfile(dpath, [SeaLevel '_org'], 'fort.14'));

%% Do the work (looping through each dir)
cd(wpath_s)
for i = 1:numel(dirNames)
    tgt_intensity = dirNames{i};
    if ~exist(tgt_intensity, 'dir'), mkdir(tgt_intensity); end
    
    % load SSH output
    SSH = load(fullfile(wpath_a, tgt_intensity, [lower(subdir) 'SSH.mat']));
    fname = fieldnames(SSH);
    tgt_SSH = SSH.(fname{1});
    
    % interpolate them on FDM grid
    interp_SSH = griddata(fgs.x, fgs.y, tgt_SSH, x_mat, y_mat);
    
    % Mask out values in land
    interp_SSH(total_in) = -999;
    
    % Add SSH
    final_depth = raw_depth_FDM + interp_SSH;
    
    clf;p = pcolor(x_mat,y_mat,final_depth);c = colorbar();
    %set(p, 'EdgeColor', 'none'); 
    axis equal;
    switch tgt_NPP
        case 'HANBIT',  clim([0 20]);
        case 'SAEUL',   clim([0 70]);
        case 'KORI',    clim([0 70]);
        case 'WOLSUNG', clim([0 70]);
        case 'HANUL',   clim([0 70]);    
    end
    title(c, '[m]');xtickformat('%.2f');ytickformat('%.2f');
    title('Refined depth for setup')
    frame = getframe(gcf);
    
    xlim([126.40 126.43]); ylim([35.40 35.42]);
    
    img = frame2im(frame);
    imwrite(img, fullfile(wpath_s, tgt_intensity, [tgt_tc(1:4) '_setup_depth_' subdir '.png']));
    
    save(fullfile(wpath_s, tgt_intensity, 'DEPTH_SETUP.dat'), 'final_depth', '-ascii');
end
end

% Depth_20120828_092000 = double(Depth_20120828_092000);
% save('DEPTH_SETUP_mod.dat', 'Depth_20120828_092000', '-ascii');

% sample = load('DEPTH_SETUP.dat');




