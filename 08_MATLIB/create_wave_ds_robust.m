function RESULT = create_wave_ds_robust(tpath)
%% Navigate to target directory and load files
current_path = pwd;
cd(tpath);
disp(['Currently working on ' tpath]);

% Load data
RESULT.HS_FILE = dir('*_HS.mat');
RESULT.TP_FILE = dir('*_TPS.mat');
RESULT.PDIR_FILE = dir('*_PDIR.mat');

RESULT.HS = load(RESULT.HS_FILE.name);
RESULT.TP = load(RESULT.TP_FILE.name);
RESULT.PDIR = load(RESULT.PDIR_FILE.name);

%% Extract field names
fnames_HS = fieldnames(RESULT.HS);
fnames_TP = fieldnames(RESULT.TP);
fnames_PDIR = fieldnames(RESULT.PDIR);

% Initialize result arrays
initial_size = size(RESULT.HS.(fnames_HS{1}));
RESULT.MAX_HS = nan(initial_size);
RESULT.MAX_TP = nan(initial_size);
RESULT.MAX_PDIR = nan(initial_size);

%% Determine date-based processing
if contains(tpath, 'MAYSAK') || contains(tpath, 'HAISHEN')
    referenceDateTime = datetime('2020-09-03 12:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    tgt_date_str = datestr(referenceDateTime, 'yyyymmdd_HHMMSS');
    idx_tgt = find(contains(fnames_HS, tgt_date_str));
    
    % Define loop range based on target type
    loop_range = 1:idx_tgt;
    if contains(tpath, 'HAISHEN')
        loop_range = idx_tgt:length(fnames_HS);
    end
elseif contains(tpath, 'LINGLING') && ~contains(tpath, '-10') && ~contains(tpath, '+10')
    referenceDateTime = datetime('2019-09-07 16:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    tgt_date_str = datestr(referenceDateTime, 'yyyymmdd_HHMMSS');
    idx_tgt = find(contains(fnames_HS, tgt_date_str));
    loop_range = 1:idx_tgt;
else
    loop_range = 1:length(fnames_HS);
end

%% Process each time step
for f_id = loop_range
    % Temporary variable for comparison
    MAX_HS_prev = RESULT.MAX_HS;
    
    % Update max values and corresponding directions/periods
    RESULT.MAX_HS = max(RESULT.MAX_HS, RESULT.HS.(fnames_HS{f_id}));
    replace_id = (RESULT.MAX_HS ~= MAX_HS_prev);
    RESULT.MAX_PDIR(replace_id) = RESULT.PDIR.(fnames_PDIR{f_id})(replace_id);
    RESULT.MAX_TP(replace_id) = RESULT.TP.(fnames_TP{f_id})(replace_id);
end

%% Clean up large structures to save memory
RESULT.HS = [];
RESULT.TP = [];
RESULT.PDIR = [];

% Save results
save('RESULT.mat', 'RESULT', '-v7.3');

% Return to the original path
cd(current_path);
end
%{
fgs = grd_to_opnml('fort.14');
for f_id = 1:6:length(fnames_HS)
    clf;colormesh2d(fgs,RESULT.HS.Hsig_20190907_160000);axis equal;
    drawnow;
    disp(fnames_HS{f_id})
end
%}



