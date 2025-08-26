function ReGetWindSetup_org(tgt_tc, tgt_NPP, SeaLevel, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Set default parameters
if nargin < 1, tgt_tc   = '2009_MAYSAK'; end
if nargin < 2, tgt_NPP  = 'SAEUL'; end
if nargin < 3, SeaLevel = '10exL'; end
if nargin < 4, rpath    = '/home/user_006/01_WORK/2025/NPP'; end

switch SeaLevel
    case '10exH+SLR', subdir = 'MAX';
    case '10exL',     subdir = 'MIN';
    case 'AHHL',      subdir = '';
end

opath   = fullfile(rpath, '05_DATA', 'processed');
dpath   = fullfile(opath, tgt_NPP);
wpath_w = fullfile(dpath, tgt_tc, '09_WRF');
spath   = fullfile(dpath, tgt_tc, '13_SETUP', [subdir '_org']);
wpath_s = fullfile(dpath, tgt_tc, '14_RESETUP', [subdir '_org']);

%% Do the work
dirNames = {dir(fullfile(spath, '*')).name};
dirNames = dirNames(cellfun(@(n) ~ismember(n, {'.', '..', ''}), dirNames));

% Extract yearStr
yearStr = extractYear(tgt_tc);

for i = 1:numel(dirNames)
    tgt_intensity = dirNames{i};
    cd(fullfile(wpath_w, tgt_intensity))
    
    % Load coordinate data
    x_mat = load('longitude.dat');
    y_mat = load('latitude.dat');
    
    % Load file lists
    U_FILES = dir('u10_*');
    V_FILES = dir('v10_*');
    
    % Load INPGRID BOTTOM info
    tgt_dg = load(fullfile(dpath, "redgrid.mat"));
    dgrid = tgt_dg.dgrid;
    
    parfor f_id = 1:length(U_FILES)
        u10 = load(U_FILES(f_id).name);
        v10 = load(V_FILES(f_id).name);
        
        % Extract date string
        date_string = extract_date(U_FILES(f_id).name);
        
        u_interp = griddata(x_mat, y_mat, u10, dgrid.mx, dgrid.my, 'linear');
        v_interp = griddata(x_mat, y_mat, v10, dgrid.mx, dgrid.my, 'linear');
        
        u_interp(isnan(u_interp)) = 0;
        v_interp(isnan(v_interp)) = 0;
        output_data = [u_interp; v_interp];
        
        output_file = fullfile(wpath_s, tgt_intensity, [datestr(datenum(date_string, 'yyyy-mm-dd_HH'), 'yyyy-mm-dd_HH') '.dat']);
        dlmwrite(output_file, output_data, 'delimiter', ' ', 'precision', '%.5f');
        
        plotWind(u_interp, v_interp, dgrid, f_id, fullfile(wpath_s, tgt_intensity))
    end
    cd(fullfile(wpath_s, tgt_intensity))
    system(['find . -type f -name "', yearStr, '*.dat' '" | sort -V > WIND_NAMES.dat']);
end
end

%% Helper function
function date_string = extract_date(file_name)
    % Extract date string using regex
    pattern = '\d{4}-\d{2}-\d{2}_\d{2}';
    date_string = regexp(file_name, pattern, 'match', 'once');
end

function plotWind(u_interp, v_interp, dgrid, f_id, save_path)
    mag = sqrt(u_interp.^2+v_interp.^2);
    clf; p = pcolor(dgrid.mx, dgrid.my, mag); set(p, 'EdgeColor', 'None'); axis equal;
    colormap('jet'); c = colorbar(); title(c, '[m/s]'); title('Refined Wind for setup');
    xtickformat('%.2f'); ytickformat('%.2f'); clim([0 5]); c.TickLabels = compose('%.1f', c.Ticks);
    frame = getframe(gcf);
    img = frame2im(frame);
    tgt_dir = fullfile(save_path, 'figures_setup_wind');
    if ~exist(tgt_dir, 'dir'), mkdir(tgt_dir); end
    imwrite(img, fullfile(tgt_dir, ['setup_wind_' num2str(f_id) '.png']));
end

function yearStr = extractYear(tgt_tc)
tc_num = extractBefore(tgt_tc, '_');
raw_year = str2double(tc_num(1:2));
if raw_year < 50
    yearVal = raw_year + 2000;
else
    yearVal = raw_year + 1900;
end
yearStr = num2str(yearVal);
end





