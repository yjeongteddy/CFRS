function ReGetDepthSetup(tgt_tc, tgt_NPP, SeaLevel, rpath)

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
wpath_w = fullfile(dpath, tgt_tc, '13_SETUP', [subdir '_mod']);
wpath_s = fullfile(dpath, tgt_tc, '14_RESETUP', [subdir '_mod']);
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

if exist(fullfile(dpath, 'redgrid.mat'), 'file') ~= 2
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
    
    [slat, slon] = utm2ll(xs,ys,52);
    [elat, elon] = utm2ll(xe,ye,52);
    dxl = dx/(111320*cosd(slat));
    dyl = dy/111320;
    lon_vec = slon:dxl:elon;
    lat_vec = slat:dyl:elat;
    [lon_mat, lat_mat] = meshgrid(lon_vec, lat_vec);
    
    dgrid.xs = slon;
    dgrid.ys = slat;
    dgrid.xe = elon;
    dgrid.ye = elat;
    dgrid.nx = length(lon_vec);
    dgrid.ny = length(lat_vec);
    dgrid.dx = dxl;
    dgrid.dy = dyl;
    dgrid.mx = lon_mat;
    dgrid.my = lat_mat;
    
    save(fullfile(dpath, 'redgrid.mat'), 'dgrid')
else
    tgt_dg = load(fullfile(dpath, 'redgrid.mat'));
    dgrid = tgt_dg.dgrid;
    x_mat = dgrid.mx; y_mat = dgrid.my;
end

raw_dg = load(fullfile(dpath, 'dgrid.mat'));
raw_dgrid = raw_dg.dgrid;
raw_x_mat = raw_dgrid.mx; raw_y_mat = raw_dgrid.my;

%% Get indices of inland
if exist(fullfile(dpath,'relandmask_FDM.mat'), 'file') == 2
    load(fullfile(dpath, 'relandmask_FDM.mat'))
else
    [m,n] = size(x_mat);
    total_in = false(m,n);
    for i = 1:length(COAST)
        [in, ~] = inpolygon(x_mat, y_mat, COAST(i).X, COAST(i).Y);
        total_in = total_in | in;
    end
    save(fullfile(dpath, 'relandmask_FDM.mat'), 'total_in', '-v7.3');
end

%% Do the work (looping through each dir)
cd(wpath_s)
for i = 1:numel(dirNames)
    tgt_intensity = dirNames{i};
    if ~exist(tgt_intensity, 'dir'), mkdir(tgt_intensity); end
    
    setup_depth = load(fullfile(wpath_w, tgt_intensity, 'DEPTH_SETUP.dat'));
    
    interp_depth = griddata(raw_x_mat, raw_y_mat, setup_depth, x_mat, y_mat);
    
    interp_depth(total_in) = -999;
    
    save(fullfile(wpath_s, tgt_intensity, 'DEPTH_SETUP.dat'), 'interp_depth', '-ascii');
end
end
