function run_swan_robust(opath, tgt_NPP, tgt_TC, tgt_stn)

% Set default inputs if not provided
if nargin < 1, opath   = '/home/user_006/01_WORK/2025/NPP'; end
if nargin < 2, tpath   = fullfile(opath, '05_DATA/processed'); end
if nargin < 3, tgt_NPP = 'SAEUL'; end
if nargin < 4, tgt_TC  = '0314_MAEMI'; end
if nargin < 5, tgt_stn = '1.2'; end

% Set the path of requaired libraries
addpath(genpath('/home/user_006/08_MATLIB'));

% Extract tc serial number in advance
tc_num = extractBefore(tgt_TC, '_');

% Target dir
tgt_wrf_path = fullfile(tpath, tgt_NPP, tgt_TC, '09_WRF', tgt_stn);
cd(tgt_wrf_path)

% Take extracted variables
u_list = dir('u10*'); % Zonal wind
v_list = dir('v10*'); % Meridional wind
lon = load('longitude.dat');
lat = load('latitude.dat');

% Create a new dir to run SWAN
tgt_swn_path = fullfile(tpath, tgt_NPP, tgt_TC, '10_SWAN', tgt_stn, 'WIND');
exist(tgt_swn_path, 'dir') || mkdir(tgt_wrf_path);
cd(tgt_wrf_path)

% Load depth data
fgs = grd_to_opnml('fort.14');

% Process wind data to feed SWAN
parfor k = 1:length(u_list) % Create wind field
    U10 = double(load([u_list(k).folder '/' u_list(k).name]));
    V10 = double(load([v_list(k).folder '/' v_list(k).name]));
    
    str_id = strfind(u_list(k).name,'_');
    TIME = datenum(u_list(k).name(str_id(1)+1:end),'yyyy-mm-dd_HH:MM:SS')
    u_unswan = griddata(lon,lat,U10,fgs.x,fgs.y);
    v_unswan = griddata(lon,lat,V10,fgs.x,fgs.y);
    vel_unswan = [u_unswan; v_unswan];
    vel_unswan(isnan(vel_unswan)) = 0;
    dlmwrite([datestr(TIME,'yyyymmdd_HH') '.dat'],vel_unswan,'precision','%.2f'); % currently in WIND_tg_tc
end

% Take starting date and ending date of TC
dlist = dir('*.dat');

[sDateStr, ~, ~] = fileparts(dlist(1).name);
[eDateStr, ~, ~] = fileparts(dlist(end).name);

sDateNum = datenum(sDateStr,'yyyymmdd_HH');
eDateNum = datenum(eDateStr,'yyyymmdd_HH');

% 
cd('../')
copyfile(fullfile(opath, '02_SCRIPT', 'INPUT.csh'), './');
f_id = 1;
fid = fopen(['run_script_' num2str(f_id, '%02i') '.sh'],'w');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,'export start_date=%s\n',datestr(sDateNum,'yyyymmdd.HHMMSS'));
fprintf(fid,'export end_date=%s\n',datestr(eDateNum,'yyyymmdd.HHMMSS'));
fprintf(fid,'export CASE=%s\n',[tc_num '_S' tg_GR tc_vel]); % Change this!
fprintf(fid,'csh INPUT.csh\n');


end


















