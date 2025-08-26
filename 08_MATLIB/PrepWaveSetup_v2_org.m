function PrepWaveSetup_v2_org(tgt_tc, tgt_NPP, SeaLevel, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Set default parameters
if nargin < 1, tgt_tc   = '2211_HINNAMNOR'; end
if nargin < 2, tgt_NPP  = 'SAEUL'; end
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
wpath_s = fullfile(dpath, tgt_tc, '13_SETUP', [subdir '_org']);

%% Target location
switch tgt_NPP
    case 'SAEUL'
        tgt_lon = 129.3172;
        tgt_lat = 35.3349;
    case 'HANBIT'
        tgt_lon = 126.4173;
        tgt_lat = 35.4087;
end

%% Do the work
dirNames = {dir(fullfile(wpath_w, '*')).name};
dirNames = dirNames(cellfun(@(n) ~ismember(n, {'.', '..'}), dirNames));

Nfile = 'NEST.nest';
Hfile = 'NEST_UTM_HEADER';

for i = 1:numel(dirNames)
    tgt_intensity = dirNames{i};
    tgt_setup_path = fullfile(wpath_s, tgt_intensity);
    if ~exist(tgt_setup_path, 'dir'), mkdir(tgt_setup_path); end
    
    cd(tgt_setup_path)
    fid = fopen('run_script_WaveSetup.sh','w');
    fprintf(fid, '#!/bin/bash\n');
    
    system('ln -sf 02_SCRIPT/INPUT_SU.csh .')
    
    tgt_swan_path = fullfile(wpath_w, tgt_intensity);
    HS_file = dir(fullfile(tgt_swan_path, '*_HS.mat'));
    [~, INPUT] = system(['cat ' fullfile(tgt_swan_path, 'INPUT')]);
    
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
    
    format longG
    
    [ngrid.utm_xs, ngrid.utm_ys] = ll2utm(ngrid.ys, ngrid.xs, 52);
    [ngrid.utm_xe, ngrid.utm_ye] = ll2utm(ngrid.ys+ngrid.ly, ngrid.xs+ngrid.lx, 52);
    
    ngrid.utm_dx = mode(diff(linspace(ngrid.utm_xs, ngrid.utm_xe, ngrid.nx+1)));
    ngrid.utm_dy = mode(diff(linspace(ngrid.utm_ys, ngrid.utm_ye, ngrid.ny+1)));
    
    HS = load(fullfile(HS_file.folder, HS_file.name));
    fnames = fieldnames(HS);
    fgs = grd_to_opnml(fullfile(HS_file.folder, 'fort.14'));
    idx_lon = fgs.x > tgt_lon - 0.01 & fgs.x < tgt_lon + 0.01;
    idx_lat = fgs.y > tgt_lat - 0.01 & fgs.y < tgt_lat + 0.01;
    idx_tgt = idx_lon & idx_lat;
    
    clear DATA
    
    for f_id = 1:length(fnames)
        fname = fnames{f_id};
        tgt_Hs = HS.(fname);
        DATA.Hs(f_id)   = griddata(fgs.x(idx_tgt), fgs.y(idx_tgt), double(tgt_Hs(idx_tgt)), tgt_lon, tgt_lat);
        DATA.time(f_id) = datenum(fname(6:end), 'yyyymmdd_HHMMSS');
    end
    
    [~, idx_max] = max(DATA.Hs);
    max_time = DATA.time(idx_max);
    mtimeStr = datestr(max_time,'yyyymmdd.HHMMSS');
    
    fprintf(fid,'export SITE=%s\n', tgt_NPP);
    fprintf(fid,'export CAL_SX=%.6f\n', ngrid.utm_xs); % starting point in m
    fprintf(fid,'export CAL_SY=%.6f\n', ngrid.utm_ys);
    fprintf(fid,'export CAL_LX=%.4f\n', ngrid.utm_xe - ngrid.utm_xs); % length of a whole cgrid in m
    fprintf(fid,'export CAL_LY=%.4f\n', ngrid.utm_ye - ngrid.utm_ys);
    fprintf(fid,'export CAL_NX=%d\n', ngrid.nx); % # of meshes
    fprintf(fid,'export CAL_NY=%d\n', ngrid.ny);
    
    tgt_dg = load(fullfile(dpath, "dgrid.mat"));
    dgrid = tgt_dg.dgrid;
    
    [dgrid.utm_xs, dgrid.utm_ys] = ll2utm(dgrid.ys, dgrid.xs, 52);
    [dgrid.utm_xe, dgrid.utm_ye] = ll2utm(dgrid.ye, dgrid.xe, 52);
    dgrid.utm_dx = mode(diff(linspace(dgrid.utm_xs,dgrid.utm_xe,dgrid.nx+1)));
    dgrid.utm_dy = mode(diff(linspace(dgrid.utm_ys,dgrid.utm_ye,dgrid.ny+1)));
    
    fprintf(fid,'export DEP_SX=%.6f\n', dgrid.utm_xs); % starting point in m
    fprintf(fid,'export DEP_SY=%.6f\n', dgrid.utm_ys); 
    fprintf(fid,'export DEP_NX=%d\n', dgrid.nx);       % # of meshes
    fprintf(fid,'export DEP_NY=%d\n', dgrid.ny);       
    fprintf(fid,'export DEP_DX=%d\n', dgrid.utm_dx);   % length of a single mesh in m
    fprintf(fid,'export DEP_DY=%d\n', dgrid.utm_dy);   
    
    fprintf(fid,'export WIND_SX=%.2f\n', dgrid.utm_xs);
    fprintf(fid,'export WIND_SY=%.2f\n', dgrid.utm_ys);
    fprintf(fid,'export WIND_NX=%d\n', dgrid.nx);
    fprintf(fid,'export WIND_NY=%d\n', dgrid.ny);
    fprintf(fid,'export WIND_DX=%d\n', dgrid.utm_dx);
    fprintf(fid,'export WIND_DY=%d\n', dgrid.utm_dy);
    
    idx_NONST = strfind(INPUT, 'COMPUTE NONST');
    info_DATE = INPUT(idx_NONST:end);
    idx_STOP = strfind(info_DATE, 'STOP');
    if ~isempty(idx_STOP)
        info_DATE = info_DATE(1:idx_STOP-1);
    end
    date_strings = regexp(info_DATE, '\d{8}\.\d{6}', 'match');
    sdateStr = date_strings{1};
    edateStr = date_strings{2};
    
    fprintf(fid,'export WIND_STIME=%s\n', sdateStr);
    fprintf(fid,'export WIND_ETIME=%s\n', edateStr);
    
    nest_x = linspace(ngrid.utm_xs, ngrid.utm_xe, ngrid.nx+1);
    nest_y = linspace(ngrid.utm_ys, ngrid.utm_ye, ngrid.ny+1);
    [nest_xmat, nest_ymat] = meshgrid(nest_x, nest_y);
    nest.x = [nest_xmat(1,2:end) nest_xmat(2:end,end)' fliplr(nest_xmat(end,1:end-1)) flipud(nest_xmat(1:end-1,1))'];
    nest.y = [nest_ymat(1,2:end) nest_ymat(2:end,end)' fliplr(nest_ymat(end,1:end-1)) flipud(nest_ymat(1:end-1,1))'];
    
    clear save_nest
    
    save_nest = [nest.x' nest.y'];  
    % save('UTM_LOC', 'save_nest', '-ascii')
    
    fileID = fopen('UTM_LOC', 'w');
    fprintf(fileID, '%.6f\t%.6f\n', save_nest'); % Transpose if needed
    fclose(fileID);
    
    system(['head -n 6 ' fullfile(tgt_swan_path, Nfile) ' > ' Hfile]);
    system(['sed -i s/LONLAT/LOCATIONS/g ' Hfile]);
    lines = sprintf('  %d number of locations\n', length(nest.x));
    writelines(string(lines), Hfile, WriteMode="append")
    
    system(['cat UTM_LOC >> ' Hfile])
    createFreqDir(fullfile(tgt_swan_path, Nfile))
    system(['cat FREQ_DIR >> ' Hfile])
    
    [~, result] = system(['grep -n "' mtimeStr '" ' fullfile(tgt_swan_path, Nfile)]);
    
    tgt_lines = strsplit(result, '\n');
    
    idx_tail = -1;
    
    for j = 1:length(tgt_lines)
        line = tgt_lines{j};
        if contains(line, 'date and time')
            tokens = strsplit(line, ':');
            if ~isempty(tokens)
                idx_tail = str2double(tokens{1});
                break;
            end
        end
    end
    
    if idx_tail > 0
        system(['cat ' Hfile ' > NEST2.nest']);
        system(['tail -n +' num2str(idx_tail) ' ' fullfile(tgt_swan_path, Nfile) ' >> NEST2.nest']);
    else
        error('Could not find valid line number to start tail from.');
    end
    
    fprintf(fid,'export CASE_NAME=%s\n', tgt_tc);
    fprintf(fid,'export MAX_TIME=%s\n', mtimeStr);
    fprintf(fid,'csh INPUT_SU.csh\n');
    fprintf(fid,'export CASE=%s\n', tgt_tc);
    fprintf(fid,'export TC_NUM=%s\n', tgt_tc(1:4));
    fprintf(fid,'csh job_setup.csh\n');
    % fprintf(fid,'sbatch job_swan.sh\n');
    
    fclose(fid);
    
    system('chmod u+x run_script_WaveSetup.sh')
end
end

%% Helper functions
function createFreqDir(filename)
    lines = readlines(filename);
    startIdx = find(contains(lines, 'RFREQ'), 1, 'first');
    endIdx = find(contains(lines, 'exception value'), 1, 'first');
    extractedLines = lines(startIdx:endIdx);
    writelines(extractedLines, 'FREQ_DIR');
end
