function AssembleDataset(tgt_NPP, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

%% Set default parameters
if nargin < 1, tgt_NPP = 'HANBIT'; end
if nargin < 2, rpath   = '/home/user_006/01_WORK/2025/NPP'; end

opath    = fullfile(rpath, '05_DATA', 'processed');
dpath    = fullfile(opath, tgt_NPP);
SeaLevel = {'MAX', 'MIN'};

%% Do the work
tgt_tcs  = {'1215_BOLAVEN', '1913_LINGLING', '2008_BAVI'};

% Load FEM grid info
fgs = grd_to_opnml(fullfile(dpath, '10exL_org', 'fort.14'));

% Define model
modelName = {'12_ADCIRC', '10_SWAN', '14_RESETUP'};

% Define our target area
switch tgt_NPP
    case 'SAEUL'
        blon = 129.3140; blat = 35.3320;
        ulon = 129.3216; ulat = 35.3378;
    case 'HANBIT'
	blon = 126.397; ulon = 126.435;
	blat = 35.398; ulat = 35.424;
end

% Get indices
idx_lon = fgs.x > blon & fgs.x < ulon;
idx_lat = fgs.y > blat & fgs.y < ulat;
idx_tgt = idx_lon & idx_lat;

% Put FEM grid first
DATA.grid.x = fgs.x(idx_tgt);
DATA.grid.y = fgs.y(idx_tgt);

% Loop through
for m_id = 1:numel(modelName)
    mname = modelName{m_id};
    for i = 1:numel(tgt_tcs)
        tgt_tc  = tgt_tcs{i};
        tc_name = extractAfter(tgt_tc, '_');
        for j = 1:numel(SeaLevel)
            tpath  = fullfile(dpath, tgt_tc, mname, SeaLevel{j});
            clist = {'1.30-10','1.30','1.30+10'};
            cnames = clist;
            fnames = {'MPN','MP0','MPP'};
            for k = 1:numel(cnames)
                tgt_intensity = clist{k};
                wpath = fullfile(tpath, tgt_intensity);
                if contains(mname, 'ADCIRC')
                    idx_SSH = dir(fullfile(wpath, '*SSH.mat'));
                    tgt_SSH = load(fullfile(idx_SSH.folder, idx_SSH.name));
                    tgt_fname = fieldnames(tgt_SSH);
                    SSH = tgt_SSH.(tgt_fname{1});
                    DATA.(tc_name).(fnames{k}).([lower(SeaLevel{j}) 'SSH']) = SSH(idx_tgt);
                elseif contains(mname, 'SWAN')
                    load(fullfile(wpath, 'RESULT.mat'));
                    maxHS = RESULT.MAX_HS;
                    maxTP = RESULT.MAX_TP;
                    maxPDIR = RESULT.MAX_PDIR;
                    DATA.(tc_name).(fnames{k}).(['maxHS_' lower(SeaLevel{j}) 'SSH']) = double(maxHS(idx_tgt)');
                    DATA.(tc_name).(fnames{k}).(['maxTP_' lower(SeaLevel{j}) 'SSH']) = maxTP(idx_tgt)';
                    DATA.(tc_name).(fnames{k}).(['maxPDIR_' lower(SeaLevel{j}) 'SSH']) = maxPDIR(idx_tgt)';
                elseif contains(mname, 'SETUP') && strcmp(SeaLevel{j}, 'MAX')
                    cd(wpath)
                    idx_SETUP = dir('*SETUP.mat');
                    tgt_SETUP = load(fullfile(idx_SETUP.folder, idx_SETUP.name));
                    tgt_fname = fieldnames(tgt_SETUP);
                    SETUP = tgt_SETUP.(tgt_fname{1});
                    [~, INPUT] = system('grep -n CGRID INPUT');
                    lines = strsplit(INPUT, '\n');
                    for l = 1:length(lines)
                        line = lines{l};
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
                    idx_slon = xMatOrg >= blon & xMatOrg <= ulon;
                    idx_slat = yMatOrg >= blat & yMatOrg <= ulat;
                    idx_stgt = idx_slon & idx_slat;
                    
                    result = nan(size(SETUP));
                    result(idx_stgt) = SETUP(idx_stgt);
                    
                    DATA.(tc_name).(fnames{k}).('SETUP') = result;
                    DATA.grid.x_mat = xMatOrg; DATA.grid.y_mat = yMatOrg;
                end
            end
        end
    end
end

save(fullfile(dpath, 'DATA_HB_250821_org.mat'), 'DATA', '-v7')

end
