function AssembleDataset_v2(tgt_NPP, rpath)

addpath(genpath('/home/user_006/08_MATLIB'))

% Default parameters
if nargin < 1, tgt_NPP = 'SAEUL'; end
if nargin < 2, rpath = '/home/user_006/01_WORK/2025/NPP'; end

opath = fullfile(rpath, '05_DATA', 'processed');
dpath = fullfile(opath, tgt_NPP);
SeaLevel = {'MAX', 'MIN'};

% Get target TCs
tgt_tcs = getTargetTCs(dpath);

% Load grid and get target indices
fgs = grd_to_opnml(fullfile(dpath, '10exH+SLR', 'fort.14'));
[DATA.x, DATA.y, idx_tgt] = getTargetIndices(fgs);

% Model types
modelNames = {'12_ADCIRC', '10_SWAN', '13_SETUP'};

% Loop over models and storms
for m = 1:numel(modelNames)
    model = modelNames{m};
    for i = 1:numel(tgt_tcs)
        tc_name = extractAfter(tgt_tcs{i}, '_');
        for j = 1:numel(SeaLevel)
            slvl = SeaLevel{j};
            tpath = fullfile(dpath, tgt_tcs{i}, model, slvl);
            [fnames, cases] = getCaseFolders(tpath);
            for k = 1:numel(cases)
                wpath = fullfile(tpath, cases{k});
                fname = fnames{k};
                switch model
                    case '12_ADCIRC'
                        DATA = processADCIRC(DATA, tc_name, fname, wpath, slvl, idx_tgt);
                    case '10_SWAN'
                        DATA = processSWAN(DATA, tc_name, fname, wpath, slvl, idx_tgt);
                    case '13_SETUP'
                        if strcmp(slvl, 'MAX')
                            [DATA, x_mat, y_mat] = processSETUP(DATA, tc_name, fname, wpath);
                            DATA.x_mat = x_mat;
                            DATA.y_mat = y_mat;
                        end
                end
            end
        end
    end
end

save(fullfile(dpath, 'DATA.mat'), 'DATA', '-v7.3');
end

%% Helper functions
function tgt_tcs = getTargetTCs(dpath)
entries = dir(dpath);
tgt_tcs = {entries([entries.isdir] & ~ismember({entries.name}, {'.', '..'}) & contains({entries.name}, '_')).name};
end

function [x, y, idx] = getTargetIndices(fgs)
blon = 129.3140; blat = 35.3320;
ulon = 129.3216; ulat = 35.3378;
idx = (fgs.x > blon & fgs.x < ulon) & (fgs.y > blat & fgs.y < ulat);
x = fgs.x(idx);
y = fgs.y(idx);
end

function [fnames, cases] = getCaseFolders(tpath)
clist = dir(tpath);
cases = {clist([clist.isdir] & ~ismember({clist.name}, {'.', '..'})).name};
fnames = mapFoldersToFields(cases);
end

function DATA = processADCIRC(DATA, tc_name, fname, wpath, slvl, idx_tgt)
sshFile = dir(fullfile(wpath, '*SSH.mat'));
if isempty(sshFile), return; end
sshData = load(fullfile(sshFile.folder, sshFile.name));
field = sshData.(fieldnames(sshData){1});
DATA.(tc_name).(fname).([lower(slvl) 'SSH']) = field(idx_tgt);
end

function DATA = processSWAN(DATA, tc_name, fname, wpath, slvl, idx_tgt)
resFile = fullfile(wpath, 'RESULT.mat');
if ~isfile(resFile), return; end
load(resFile, 'RESULT');
DATA.(tc_name).(fname).(['maxHS_' lower(slvl) 'SSH']) = double(RESULT.MAX_HS(idx_tgt)');
DATA.(tc_name).(fname).(['maxTP_' lower(slvl) 'SSH']) = RESULT.MAX_TP(idx_tgt)';
end

function [DATA, x_mat, y_mat] = processSETUP(DATA, tc_name, fname, wpath)
setupFile = dir(fullfile(wpath, '*SETUP.mat'));
if isempty(setupFile), return; end
setupData = load(fullfile(setupFile.folder, setupFile.name));
setup = setupData.(fieldnames(setupData){1});

[~, inputText] = system(sprintf('grep -n CGRID %s', fullfile(wpath, 'INPUT')));
line = extractBetween(inputText, 'CGRID', newline);
tokens = str2double(strsplit(strtrim(['CGRID' line{1}])));
[xs, ys, lx, ly, nx, ny] = deal(tokens(2), tokens(3), tokens(5), tokens(6), tokens(7), tokens(8));

[slat, slon] = utm2ll(xs, ys, 52);
[elat, elon] = utm2ll(xs + lx, ys + ly, 52);
xVec = linspace(slon, elon, nx + 1);
yVec = linspace(slat, elat, ny + 1);
[x_mat, y_mat] = meshgrid(xVec, yVec);

blon = 129.3140; blat = 35.3320;
ulon = 129.3216; ulat = 35.3378;
idx = (x_mat > blon & x_mat < ulon) & (y_mat > blat & y_mat < ulon);

DATA.(tc_name).(fname).SETUP = double(setup(idx));
end
