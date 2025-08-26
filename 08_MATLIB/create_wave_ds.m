function RESULT = create_wave_ds(tpath)
%% Take target variables
current_path = pwd;
cd(tpath)
disp(['Currently working on ' tpath])
RESULT.HS_FILE = dir('*_HS.mat');
RESULT.HS = load(RESULT.HS_FILE.name);
RESULT.TP_FILE = dir('*_TPS.mat');
RESULT.TP = load(RESULT.TP_FILE.name);
RESULT.PDIR_FILE = dir('*_PDIR.mat');
RESULT.PDIR = load(RESULT.PDIR_FILE.name);

%% Get lists from each sub-structure
fnames_HS = fieldnames(RESULT.HS);
fnames_TP = fieldnames(RESULT.TP);
fnames_PDIR = fieldnames(RESULT.PDIR);

%% Create empty arraies for target max variables
RESULT.MAX_HS = nan(size(RESULT.HS.(fnames_HS{1})));
RESULT.MAX_TP = nan(size(RESULT.HS.(fnames_HS{1})));
RESULT.MAX_PDIR = nan(size(RESULT.HS.(fnames_HS{1})));

%% Extract max value
if contains(tpath, 'MAYSAK')
    referenceDateTime = datetime('2020-09-03 12:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    tgt_date_str = datestr(referenceDateTime, 'yyyymmdd_HHMMSS');
    idx_tgt = find(contains(fnames_HS, tgt_date_str));
    for f_id = 1:idx_tgt
        RESULT.MAX_HS_prev = RESULT.MAX_HS;
        RESULT.MAX_HS = max(RESULT.MAX_HS, RESULT.HS.(fnames_HS{f_id}));
        replace_id = (RESULT.MAX_HS ~= RESULT.MAX_HS_prev);
        RESULT.MAX_PDIR(replace_id) = RESULT.PDIR.(fnames_PDIR{f_id})(replace_id);
        RESULT.MAX_TP(replace_id) = RESULT.TP.(fnames_TP{f_id})(replace_id);
    end
elseif contains(tpath, 'HAISHEN')
    referenceDateTime = datetime('2020-09-03 12:00:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    tgt_date_str = datestr(referenceDateTime, 'yyyymmdd_HHMMSS');
    idx_tgt = find(contains(fnames_HS, tgt_date_str));
    for f_id = idx_tgt:length(fnames_HS)
        RESULT.MAX_HS_prev = RESULT.MAX_HS;
        RESULT.MAX_HS = max(RESULT.MAX_HS, RESULT.HS.(fnames_HS{f_id}));
        replace_id = (RESULT.MAX_HS ~= RESULT.MAX_HS_prev);
        RESULT.MAX_PDIR(replace_id) = RESULT.PDIR.(fnames_PDIR{f_id})(replace_id);
        RESULT.MAX_TP(replace_id) = RESULT.TP.(fnames_TP{f_id})(replace_id);
    end
else
    for f_id = 1:length(fnames_HS)
        RESULT.MAX_HS_prev = RESULT.MAX_HS;
        RESULT.MAX_HS = max(RESULT.MAX_HS, RESULT.HS.(fnames_HS{f_id}));
        replace_id = (RESULT.MAX_HS ~= RESULT.MAX_HS_prev);
        RESULT.MAX_PDIR(replace_id) = RESULT.PDIR.(fnames_PDIR{f_id})(replace_id);
        RESULT.MAX_TP(replace_id) = RESULT.TP.(fnames_TP{f_id})(replace_id);
    end
end

RESULT.HS = []; RESULT.TP = []; RESULT.PDIR = []; % just for the maximum value

save('RESULT_new.mat','RESULT','-v7.3');

cd(current_path)
end

