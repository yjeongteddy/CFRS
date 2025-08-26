function PrepWaveSetup_v3(tgt_tc, tgt_NPP, SeaLevel, rpath)
addpath(genpath('/home/user_006/08_MATLIB'));

% Set default arguments
if nargin < 1, tgt_tc   = '0314_MAEMI'; end
if nargin < 2, tgt_NPP  = 'SAEUL'; end
if nargin < 3, SeaLevel = '10exH+SLR'; end
if nargin < 4, rpath    = '/home/user_006/01_WORK/2025/NPP'; end

% Setup paths
subdir = getSubDir(SeaLevel);
opath = fullfile(rpath, '05_DATA', 'processed');
wpath = fullfile(opath, tgt_NPP, tgt_tc, '10_SWAN', subdir);

% Target location
tgt_lon = 129.3172;
tgt_lat = 35.3349;

% List of intensity cases
dirNames = getDirectoryList(wpath);

for i = 1:numel(dirNames)
    tgt_intensity = dirNames{i};
    cd(fullfile(wpath, tgt_intensity))

    INPUT = readInputFile();
    ngrid = parseGridInfo(INPUT);
    [ngrid, nest] = computeUTMGrid(ngrid);
    
    HS_data = loadWaveData(tgt_lon, tgt_lat);
    [max_time, mtimeStr, DATA] = findMaxWaveTime(HS_data);
    
    sdateStr = extractDate(INPUT, 'start');
    edateStr = extractDate(INPUT, 'end');
    
    % Write script
    fid = fopen('run_script_WaveSetup.sh','w');
    writeExportVars(fid, tgt_NPP, tgt_tc, ngrid, sdateStr, edateStr, mtimeStr);
    fclose(fid);
    
    % Generate nest files
    saveNestPoints(nest);
    generateHeaderFile('NEST.nest', 'NEST_UTM_HEADER', length(nest.x));
    createFreqDir('NEST.nest');
    appendFreqDir('FREQ_DIR', 'NEST_UTM_HEADER');

    % Create NEST2.nest
    tailLine = getTailLine('NEST.nest', sdateStr);
    generateNest2('NEST_UTM_HEADER', 'NEST.nest', tailLine);
end
end

%% Helper functions
function subdir = getSubDir(SeaLevel)
    switch SeaLevel
        case '10exH+SLR', subdir = 'MAX';
        case '10exL',     subdir = 'MIN';
        case 'AHHL',      subdir = '';
    end
end

function dirNames = getDirectoryList(path)
    files = dir(fullfile(path, '*'));
    dirNames = {files([files.isdir] & ~ismember({files.name}, {'.', '..'})).name};
end

function INPUT = readInputFile()
    system('cp 02_SCRIPT/INPUT_SU.csh .');
    [~, INPUT] = system('cat INPUT');
end

function ngrid = parseGridInfo(INPUT)
    info = extractBetween(INPUT, 'NGRID', 'NESTOUT');
    parts = str2double(strsplit(strtrim(info{1})));
    ngrid = struct('xs', parts(1), 'ys', parts(2), 'lx', parts(3), ...
                   'ly', parts(4), 'nx', parts(5), 'ny', parts(6));
end

function [ngrid, nest] = computeUTMGrid(ngrid)
    [ngrid.utm_xs, ngrid.utm_ys] = ll2utm(ngrid.ys, ngrid.xs, 52);
    [ngrid.utm_xe, ngrid.utm_ye] = ll2utm(ngrid.ys + ngrid.ly, ngrid.xs + ngrid.lx, 52);
    ngrid.utm_dx = mode(diff(linspace(ngrid.utm_xs, ngrid.utm_xe, ngrid.nx+1)));
    ngrid.utm_dy = mode(diff(linspace(ngrid.utm_ys, ngrid.utm_ye, ngrid.ny+1)));

    x = linspace(ngrid.utm_xs, ngrid.utm_xe, ngrid.nx+1);
    y = linspace(ngrid.utm_ys, ngrid.utm_ye, ngrid.ny+1);
    [xmat, ymat] = meshgrid(x, y);
    nest.x = [xmat(1,2:end), xmat(2:end,end)', fliplr(xmat(end,1:end-1)), flipud(xmat(1:end-1,1))'];
    nest.y = [ymat(1,2:end), ymat(2:end,end)', fliplr(ymat(end,1:end-1)), flipud(ymat(1:end-1,1))'];
end

function HS = loadWaveData(tgt_lon, tgt_lat)
    HS_file = dir('*_HS.mat');
    HS = load(fullfile(HS_file.folder, HS_file.name));
    fgs = grd_to_opnml(fullfile(HS_file.folder, 'fort.14'));
    HS.fgs = fgs;
    HS.tgt_idx = and(fgs.x > tgt_lon - 0.01 & fgs.x < tgt_lon + 0.01, ...
                     fgs.y > tgt_lat - 0.01 & fgs.y < tgt_lat + 0.01);
end

function [max_time, mtimeStr, DATA] = findMaxWaveTime(HS)
    fnames = fieldnames(HS);
    for i = 1:length(fnames)
        if strcmp(fnames{i}, 'fgs') || strcmp(fnames{i}, 'tgt_idx')
            continue
        end
        H = HS.(fnames{i});
        DATA.Hs(i) = griddata(HS.fgs.x(HS.tgt_idx), HS.fgs.y(HS.tgt_idx), ...
                              double(H(HS.tgt_idx)), 129.3172, 35.3349);
        DATA.time(i) = datenum(fnames{i}(6:end), 'yyyymmdd_HHMMSS');
    end
    [~, idx_max] = max(DATA.Hs);
    max_time = DATA.time(idx_max);
    mtimeStr = datestr(max_time,'yyyymmdd.HHMMSS');
end

function s = extractDate(INPUT, flag)
    idx = strfind(INPUT, 'COMPUTE NONST');
    info = INPUT(idx:end);
    stop = strfind(info, 'STOP');
    if ~isempty(stop)
        info = info(1:stop-1);
    end
    dates = regexp(info, '\d{8}\.\d{6}', 'match');
    s = dates{strcmp(flag, {'start','end'}) + 1};
end

function writeExportVars(fid, site, caseName, ngrid, sdateStr, edateStr, maxTimeStr)
    fprintf(fid, '#!/bin/bash\n');
    fprintf(fid,'export SITE=%s\n', site);
    fprintf(fid,'export CASE_NAME=%s\n', caseName);
    fprintf(fid,'export MAX_TIME=%s\n', maxTimeStr);

    fields = {'SX','SY','LX','LY','NX','NY'};
    vals = {ngrid.utm_xs, ngrid.utm_ys, ngrid.utm_xe-ngrid.utm_xs, ...
            ngrid.utm_ye-ngrid.utm_ys, ngrid.nx, ngrid.ny};

    for prefix = {'CAL','DEP','WIND'}
        for i = 1:length(fields)
            fprintf(fid, 'export %s_%s=%g\n', prefix{1}, fields{i}, vals{i});
        end
    end

    fprintf(fid,'export DEP_DX=%d\n', ngrid.utm_dx);
    fprintf(fid,'export DEP_DY=%d\n', ngrid.utm_dy);
    fprintf(fid,'export WIND_DX=%d\n', ngrid.utm_dx);
    fprintf(fid,'export WIND_DY=%d\n', ngrid.utm_dy);
    fprintf(fid,'export WIND_STIME=%s\n', sdateStr);
    fprintf(fid,'export WIND_ETIME=%s\n', edateStr);
    fprintf(fid,'csh INPUT_SU.csh\n');
    fprintf(fid,'export CASE=%s\n', caseName);
    fprintf(fid,'csh job.csh\n');
    fprintf(fid,'sbatch job.sh\n');
end

function saveNestPoints(nest)
    save_nest = [nest.x' nest.y'];
    save('UTM_LOC','save_nest','-ascii')
end

function generateHeaderFile(nfile, hfile, numPts)
    system(['head -n 6 ' nfile ' > ' hfile]);
    system(['sed -i s/LONLAT/LOCATIONS/g ' hfile]);
    writelines(['  ' num2str(numPts) ' number of locations\n'], hfile, WriteMode="append");
end

function appendFreqDir(freqFile, headerFile)
    system(['cat ' freqFile ' >> ' headerFile]);
end

function generateNest2(headerFile, nestFile, tailLine)
    system(['cat ' headerFile ' > NEST2.nest']);
    system(['tail -n +' tailLine ' ' nestFile ' >> NEST2.nest']);
end

function tailLine = getTailLine(nfile, sdateStr)
    [~, result] = system(['cat ' nfile ' | grep -n ''' sdateStr '''']);
    idx_start = strfind(result, 'snap');
    idx_end = strfind(result, ':');
    tailLine = result(idx_start+5:idx_end(end)-1);
end

function createFreqDir(filename)
    lines = readlines(filename);
    startIdx = find(contains(lines, 'RFREQ'), 1, 'first');
    endIdx = find(contains(lines, 'exception value'), 1, 'first');
    writelines(lines(startIdx:endIdx), 'FREQ_DIR');
end

