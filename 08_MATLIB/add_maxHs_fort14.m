clc;clear;close all;

%% Target TC
opath = '/home/user_006/SHARE/240605_NMJ_WORK_0605/0.METEO/';
cd(opath)
tc_name = {'0314_MAEMI','2009_MAYSAK','2211_HINNAMNOR','5914_SARAH'};

for i = 2%1:length(tc_name)
    tg_tc = tc_name{i};
    cd([tg_tc '/WRF']);
    clist = dir('BOGUS_GR*0517');
    for j = 1:length(clist)
        tg_case = clist(j).name;

        if any(strfind(tg_case,'GR1'))
            fgs = grd_to_opnml([opath 'GR1_depth/'  'fort.14']);
        elseif any(strfind(tg_case,'GR2'))
            fgs = grd_to_opnml([opath 'GR2_depth/'  'fort.14']);
        end

        cd([tg_case '/ADCIRC_' tg_tc]);
        maxHs = load('maxHs.mat').maxHs;
        new_fgs = fgs;
        ndepth = new_fgs.z + maxHs;
        new_fgs.z = ndepth;
        new_fgs.name = [tg_tc '_' tg_case];
        
        cd([opath tg_tc '/WRF/' tg_case])

        system('rm -rf SWAN*');

        mkdir(['SWAN_' tg_tc])
        cd(['SWAN_' tg_tc])

        fgs2fort14_nmj(new_fgs);
        cd('../../')
    end
    cd('../../')
end

for i = 2%1:length(tc_name)
    tg_tc = tc_name{i};
    cd([tg_tc '/WRF']);
    clist = dir('BOGUS_GR*0517');
    for j = 1:length(clist)
        tg_case = clist(j).name;
        cd([tg_case '/SWAN_' tg_tc]);
        system(['mv ' tg_tc '_' tg_case '.grd fort.14']);
        cd('../../');
    end
    cd('../../');
end



