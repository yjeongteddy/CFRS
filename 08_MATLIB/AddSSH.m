function AddSSH(tgt_tc, tgt_NPP, intensity, SeaLevel, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Parameters
if nargin < 1, tgt_tc    = '0314_MAEMI'; end
if nargin < 2, tgt_NPP   = 'SAEUL'; end
if nargin < 3, intensity = '2.03-10'; end
if nargin < 4, SeaLevel  = '10exH+SLR'; end
if nargin < 5, rpath     = '/home/user_006/01_WORK/2025/NPP'; end

switch SeaLevel
    case '10exH+SLR'
        subdir = 'MAX';
    case '10exL'
        subdir = 'MIN';
    case 'AHHL'
        subdir = '';
end

opath = fullfile(rpath, '05_DATA/processed');
dpath = fullfile(opath, tgt_NPP);
wpath = fullfile(dpath, tgt_tc, '12_ADCIRC', subdir, intensity);
spath = fullfile(dpath, tgt_tc, '10_SWAN', subdir, intensity);
if ~exist(spath, 'dir'), mkdir(spath); end

%% Load existing depth
fgs = grd_to_opnml(fullfile(dpath, SeaLevel, 'fort.14'));

%% Load SSH output
raw_tgt_SSH = load(fullfile(wpath, [lower(subdir) 'SSH.mat']));
fname = cell2mat(fieldnames(raw_tgt_SSH));
tgt_SSH = raw_tgt_SSH.(fname);

%% Add SSH output to the existing depth
fgs_ssh_add = fgs;
fgs_ssh_add.z = fgs.z + tgt_SSH;

%% Plot DL
cd(spath)

clf;colormesh2d(fgs,fgs.z);colorbar();colormap('jet');
xlim([129.3046 129.3433]);
ylim([35.3276 35.3531]);
clim([0 40]);
title('original');
saveas(gcf, 'original.png');

%% Plot 10% exceedance high tide sea level
clf;colormesh2d(fgs_ssh_add,fgs_ssh_add.z);colorbar();colormap('jet');
xlim([129.3046 129.3433]);
ylim([35.3276 35.3531]);
clim([0 40]);
title('SSH added');
saveas(gcf, 'SSH_added.png');

%% Save them
fgs2fort14_nmj(fgs_ssh_add)
glist = dir('*.grd');
movefile(glist(1).name, 'fort.14')

end


