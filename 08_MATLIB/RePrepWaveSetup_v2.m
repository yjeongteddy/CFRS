function RePrepWaveSetup_v2(tgt_tc, tgt_NPP, SeaLevel, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Set default parameters
if nargin < 1, tgt_tc   = '2008_BAVI'; end
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

%% Do the work
dirNames = {dir(fullfile(wpath_w, '*')).name};
dirNames = dirNames(cellfun(@(n) ~ismember(n, {'.', '..'}), dirNames));

for i = 1:numel(dirNames)
    tgt_intensity = dirNames{i};
    tgt_resetup_path = fullfile(wpath_s, tgt_intensity);
    tgt_setup_path = fullfile(wpath_w, tgt_intensity);
    
    cd(tgt_resetup_path)
    copyfile(fullfile(tgt_setup_path,'run_script_WaveSetup.sh'), ...
        fullfile(tgt_resetup_path,'run_script_ReWaveSetup.sh'))
    
    system(['ln -sf ' fullfile(tgt_setup_path,'NEST3.nest') ' .']);
    
    fid = fopen('run_script_ReWaveSetup.sh', 'r');
    
    [~, INPUT] = system(['cat ' fullfile(tgt_setup_path, 'INPUT')]);
    
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
    
    tgt_dg = load(fullfile(dpath, "redgrid.mat"));
    dgrid = tgt_dg.dgrid;
    
    [dgrid.utm_xs, dgrid.utm_ys] = ll2utm(dgrid.ys, dgrid.xs, 52);
    [dgrid.utm_xe, dgrid.utm_ye] = ll2utm(dgrid.ye, dgrid.xe, 52);
    dgrid.utm_dx = mode(diff(linspace(dgrid.utm_xs,dgrid.utm_xe,dgrid.nx+1)));
    dgrid.utm_dy = mode(diff(linspace(dgrid.utm_ys,dgrid.utm_ye,dgrid.ny+1)));
    
    lines = {};                 
    tline = fgetl(fid);
    
    while ischar(tline)
        if startsWith(strtrim(tline), 'export CAL_SX=')
            tline = sprintf('export CAL_SX=%.8f', ngrid.xs);
        end
        
        if startsWith(strtrim(tline), 'export CAL_SY=')
            tline = sprintf('export CAL_SY=%.8f', ngrid.ys);
        end
        
        if startsWith(strtrim(tline), 'export CAL_LX=')
            tline = sprintf('export CAL_LX=%.8f', ngrid.lx);
        end
        
        if startsWith(strtrim(tline), 'export CAL_LY=')
            tline = sprintf('export CAL_LY=%.8f', ngrid.ly);
        end
        
        if startsWith(strtrim(tline), 'export CAL_NX=')
            tline = sprintf('export CAL_NX=%d', ngrid.nx);
        end
        
        if startsWith(strtrim(tline), 'export CAL_NY=')
            tline = sprintf('export CAL_NY=%d', ngrid.ny);
        end
        
        if startsWith(strtrim(tline), 'export DEP_SX=')
            tline = sprintf('export DEP_SX=%d', dgrid.utm_xs);
        end

        if startsWith(strtrim(tline), 'export DEP_SY=')
            tline = sprintf('export DEP_SY=%d', dgrid.utm_ys);
        end

        if startsWith(strtrim(tline), 'export DEP_NX=')
            tline = sprintf('export DEP_NX=%d', dgrid.nx - 1);
        end

        if startsWith(strtrim(tline), 'export DEP_NY=')
            tline = sprintf('export DEP_NY=%d', dgrid.ny - 1);
        end

        if startsWith(strtrim(tline), 'export DEP_DX=')
            tline = sprintf('export DEP_DX=%d', dgrid.utm_dx);
        end

        if startsWith(strtrim(tline), 'export DEP_DY=')
            tline = sprintf('export DEP_DY=%d', dgrid.utm_dy);
        end

        if startsWith(strtrim(tline), 'export WIND_SX=')
            tline = sprintf('export WIND_SX=%d', dgrid.utm_xs);
        end

        if startsWith(strtrim(tline), 'export WIND_SY=')
            tline = sprintf('export WIND_SY=%d', dgrid.utm_ys);
        end

        if startsWith(strtrim(tline), 'export WIND_NX=')
            tline = sprintf('export WIND_NX=%d', dgrid.nx - 1);
        end

        if startsWith(strtrim(tline), 'export WIND_NY=')
            tline = sprintf('export WIND_NY=%d', dgrid.ny - 1);
        end

        if startsWith(strtrim(tline), 'export WIND_DX=')
            tline = sprintf('export WIND_DX=%d', dgrid.utm_dx);
        end

        if startsWith(strtrim(tline), 'export WIND_DY=')
            tline = sprintf('export WIND_DY=%d', dgrid.utm_dy);
        end

        if contains(strtrim(tline), 'csh INPUT_SU.csh')
            tline = 'csh INPUT_ReSU.csh';
        end
        
        lines{end+1} = tline;
        tline = fgetl(fid);
    end
    fclose(fid);
    
    fid = fopen('run_script_ReWaveSetup.sh', 'w');
    fprintf(fid, '%s\n', lines{:});
    fclose(fid);
    system('chmod u+x run_script_ReWaveSetup.sh');
end
end
