function PrepWaveSetup(tgt_tc, tgt_NPP, SeaLevel, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Set default parameters
if nargin < 1, tgt_tc   = '0314_MAEMI'; end
if nargin < 2, tgt_NPP  = 'SAEUL'; end
if nargin < 3, SeaLevel = '10exH+SLR'; end
if nargin < 4, rpath    = '/home/user_006/01_WORK/2025/NPP'; end

switch SeaLevel
    case '10exH+SLR'
        subdir = 'MAX';
    case '10exL'
        subdir = 'MIN';
    case 'AHHL'
        subdir = '';
end

opath = fullfile(rpath, '05_DATA', 'processed');
dpath = fullfile(opath, tgt_NPP);
wpath = fullfile(dpath, tgt_tc, '10_SWAN', subdir);

%% Target location
tgt_lon = 129.3172;
tgt_lat = 35.3349;

%% Do the work
dirNames = {dir(fullfile(wpath, '*')).name};
dirNames = dirNames(cellfun(@(n) ~ismember(n, {'.', '..'}), dirNames));

Nfile = 'NEST.nest';

for i = 1:numel(dirNames)
    tgt_intensity = dirNames{i};
    cd(fullfile(wpath, tgt_intensity))
    
    fid = fopen('run_script_WaveSetup.sh','w');
    fprintf(fid, '#!/bin/bash\n');
    
    system('cp 02_SCRIPT/INPUT_SU.csh .')
    HS_file = dir('*_HS.mat');
    [~, INPUT] = system('cat INPUT');
    
    ngrid = extractGridInfo(INPUT, 'NGRID');
    [ngrid.utm_xs, ngrid.utm_ys] = ll2utm(ngrid.ys, ngrid.xs,52);
    [ngrid.utm_xe, ngrid.utm_ye] = ll2utm(ngrid.ys + ngrid.ly, ngrid.xs + ngrid.lx, 52);
    [ngrid.utm_dx, ngrid.utm_dy] = getUTMDiff(ngrid);
    
    % Load HS data
    HS = load(fullfile(HS_file.folder, HS_file.name));
    fnames = fieldnames(HS);
    fgs = grd_to_opnml(fullfile(HS_file.folder, 'fort.14'));
    
    idx_tgt = abs(fgs.x - tgt_lon) < 0.01 & abs(fgs.y - tgt_lat) < 0.01;
    
    for f_id = 1:numel(fnames)
        fname = fnames{f_id};
        tgt_HS = HS.(fname);
        DATA.hs(f_id)   = griddata(fgs.x(idx_tgt),fgs.y(idx_tgt),double(tgt_HS(idx_tgt)),tgt_lon,tgt_lat);
        DATA.time(f_id) = datenum(fname(6:end),'yyyymmdd_HHMMSS');
    end
    
    [~, idx_max] = max(DATA.hs);
    max_time = DATA.time(idx_max);
    
    cgrid = extractGridInfo(INPUT, 'CGRID');
    [cgrid.utm_xs, cgrid.utm_ys] = ll2utm(cgrid.ys, cgrid.xs, 52);
    [cgrid.utm_xe, cgrid.utm_ye] = ll2utm(cgrid.ys + cgrid.ly, cgrid.xs + cgrid.lx, 52);
    [cgrid.utm_dx, cgrid.utm_dy] = getUTMDiff(cgrid);
    
    % Export calibration values
    exportGrid(fid, 'CAL', ngrid, cgrid.nx, cgrid.ny);
    
    dgrid = extractGridFromBlock(INPUT, 'INPGRID BOTTOM');
    [dgrid.utm_xs, dgrid.utm_ys] = ll2utm(dgrid.ys, dgrid.xs, 52);
    [dgrid.utm_xe, dgrid.utm_ye] = ll2utm(dgrid.ys + dgrid.ny*dgrid.dy, dgrid.xs + dgrid.nx*dgrid.dx, 52);
    [dgrid.utm_dx, dgrid.utm_dy] = getUTMDiff(dgrid);
    
    exportGrid(fid, 'DEP', dgrid);
    
    wgrid = extractGridFromBlock(INPUT, 'INPGRID WIND');
    [wgrid.utm_xs, wgrid.utm_ys] = ll2utm(wgrid.ys, wgrid.xs, 52);
    [wgrid.utm_xe, wgrid.utm_ye] = ll2utm(wgrid.ys + wgrid.ny*wgrid.dy, wgrid.xs + wgrid.nx*wgrid.dx, 52);
    [wgrid.utm_dx, wgrid.utm_dy] = getUTMDiff(wgrid);
    
    exportGrid(fid, 'WIND', wgrid);
    
    % Dates
    date_block = extractBlock(INPUT, 'NONSTATIONARY', 200);
    times = regexp(date_block, '\d{8}\.\d{6}', 'match');
    fprintf(fid, 'export WIND_STIME=%s\n', times{1});
    fprintf(fid, 'export WIND_ETIME=%s\n', times{2});
    
    % Nest region
    [nest_x, nest_y] = meshgrid(linspace(ngrid.utm_xs, ngrid.utm_xe, ngrid.nx+1), ...
                                    linspace(ngrid.utm_ys, ngrid.utm_ye, ngrid.ny+1));
    nest.x = [nest_x(1,2:end), nest_x(2:end,end)', fliplr(nest_x(end,1:end-1)), flipud(nest_x(1:end-1,1))'];
    nest.y = [nest_y(1,2:end), nest_y(2:end,end)', fliplr(nest_y(end,1:end-1)), flipud(nest_y(1:end-1,1))'];
    save('UTM_LOC', 'nest', '-ascii');
    
    % NEST file handling
    system(['head -n 6 ' Nfile ' > NEST_UTM_HEADER']);
    system('sed -i ''s/LONLAT/LOCATIONS/g'' NEST_UTM_HEADER');
    writelines(sprintf('%d number of locations\n', length(nest.x)), 'NEST_UTM_HEADER', 'WriteMode', "append");
    system('cat UTM_LOC >> NEST_UTM_HEADER');
    createFreqDir(Nfile)
    system('cat FREQ_DIR >> NEST_UTM_HEADER');
    
    % Append time data
    cmd = sprintf(['cat ' Nfile ' | grep -n %s'], datestr(max_time, 'yyyymmdd.HHMMSS'));
    [~, result] = system(cmd);
    line_id = regexp(result, '(\d+):', 'tokens', 'once');
    system('cat NEST_UTM_HEADER > NEST2.nest');
    system(sprintf(['tail -n +%s ' Nfile ' >> NEST2.nest'], line_id{1}));
    
    % Final script commands
    fprintf(fid, 'export CASE_NAME=%s\n', tgt_tc);
    fprintf(fid, 'export MAX_TIME=%s\n', datestr(max_time,'yyyymmdd.HHMMSS'));
    fprintf(fid, 'csh INPUT_SU.csh\n');
    fprintf(fid, 'export CASE=%s\n', tgt_tc);
    fprintf(fid, 'csh job.csh\n');
    fprintf(fid, 'sbatch job.sh\n');
    
    fclose(fid);
end
end

%% Helper functions
function grid = extractGridInfo(INPUT, tag)
    block = extractBlock(INPUT, tag, 100);
    idx_NESTOUT = strfind(block, 'NESTOUT');
    if ~isempty(idx_NESTOUT)
        block = block(1:idx_NESTOUT-1);
    end
    vals = sscanf(block, '%*s %*s %f %f %*s %f %f %d %d');
    grid = struct('xs', vals(1), 'ys', vals(2), 'lx', vals(3), 'ly', vals(4), 'nx', vals(5), 'ny', vals(6));
end

function grid = extractGridFromBlock(INPUT, tag)
    block = extractBlock(INPUT, tag, 200);
    block = strrep(block, '  ', ' ');
    tokens = sscanf(block, '%*s %*s %f %f %*s %*s %d %d %f %f');
    grid = struct('xs', tokens(1), 'ys', tokens(2), 'nx', tokens(3), 'ny', tokens(4), 'dx', tokens(5), 'dy', tokens(6));
end

function block = extractBlock(INPUT, keyword, len)
    idx = strfind(INPUT, keyword);
    block = INPUT(idx:min(end, idx + len));
end

function [dx, dy] = getUTMDiff(grid)
    dx = mode(diff(linspace(grid.utm_xs, grid.utm_xe, grid.nx+1)));
    dy = mode(diff(linspace(grid.utm_ys, grid.utm_ye, grid.ny+1)));
end

function exportGrid(fid, prefix, grid, nx, ny)
    if nargin < 4, nx = grid.nx; end
    if nargin < 5, ny = grid.ny; end
    fprintf(fid, 'export %s_SX=%.6f\n', prefix, grid.utm_xs);
    fprintf(fid, 'export %s_SY=%.6f\n', prefix, grid.utm_ys);
    fprintf(fid, 'export %s_NX=%d\n', prefix, nx);
    fprintf(fid, 'export %s_NY=%d\n', prefix, ny);
    fprintf(fid, 'export %s_DX=%d\n', prefix, grid.utm_dx);
    fprintf(fid, 'export %s_DY=%d\n', prefix, grid.utm_dy);
end

function createFreqDir(filename)
    lines = readlines(filename);
    startIdx = find(contains(lines, 'RFREQ'), 1, 'first');
    endIdx = find(contains(lines, 'exception value'), 1, 'first');
    extractedLines = lines(startIdx:endIdx);
    writelines(extractedLines, 'FREQ_DIR');
end












