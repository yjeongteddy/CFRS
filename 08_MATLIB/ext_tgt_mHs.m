clc;clear;close all;

%% Target TC
opath = '/home/user_006/SHARE/240605_NMJ_WORK_0605/0.METEO/';
cd(opath)
tc_name = {'0314_MAEMI','2009_MAYSAK','2211_HINNAMNOR','5914_SARAH'};

%% Load target location
ds_loc = load('KR_LOCATION.mat').KR_Location;
loclist = fieldnames(ds_loc);

%% Do the work (get Hs, Pdir, Tps, and maxSSH at target location)
tic
for i = 1:length(tc_name)
    tg_tc = tc_name{i};
    
    idx_uscore = strfind(tg_tc,'_');
    v_tc_name = tg_tc(idx_uscore+1:end);
    
    cd([tg_tc '/WRF']);
    clist = dir('BOGUS_GR*0517');
    for j = 1:length(clist)
        tg_case = clist(j).name;
        
        cd([tg_case '/SWAN_' tg_tc]);
        
        if contains(tg_case,'GR1')
            fgs = grd_to_opnml([opath 'GR1_depth/'  'fort.14']);
            tg_loc = loclist(1:2);
        elseif contains(tg_case,'GR2')
            fgs = grd_to_opnml([opath 'GR2_depth/'  'fort.14']);
            tg_loc = loclist(3:end);
        end
        
        if contains(tg_case,'+10')
            case_name = strrep(tg_case,'+10','_plus_10');
        elseif contains(tg_case,'-10')
            case_name = strrep(tg_case,'-10','_minus_10');
        else
            case_name = tg_case;
        end
        
        load('RESULT.mat');
        
        for k = 1:length(tg_loc)
            tg_lon = ds_loc.(tg_loc{k})(:,1);tg_lat = ds_loc.(tg_loc{k})(:,2);
            
            DATA.(tg_loc{k}).(v_tc_name).(case_name).hs = griddata(fgs.x,fgs.y,double(RESULT.MAX_HS),tg_lon,tg_lat);
            DATA.(tg_loc{k}).(v_tc_name).(case_name).tp = griddata(fgs.x,fgs.y,double(RESULT.MAX_TP),tg_lon,tg_lat);
            DATA.(tg_loc{k}).(v_tc_name).(case_name).pd = griddata(fgs.x,fgs.y,double(RESULT.MAX_PDIR),tg_lon,tg_lat);
            
            load(['../ADCIRC_' tg_tc '/maxSSH.mat']);
            
            DATA.(tg_loc{k}).(v_tc_name).(case_name).surge = griddata(fgs.x,fgs.y,double(maxHs),tg_lon,tg_lat);
        end
        
        clear RESULT maxSSH

        cd('../../')
    end
    cd('../../')
end
toc

%% Save created dataset
save([opath tg_tc '/DATA.mat'],'DATA','-v7.3');

%% Check
sample = load('DATA.mat');

