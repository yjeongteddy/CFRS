function AdjustTranslationSpeed(opath, tgt_NPP, tgt_TC, intensifier, numWorkers)
%% Set default values
if nargin < 1, opath       = '/home/user_006/01_WORK/2025/NPP/05_DATA/processed'; end
if nargin < 2, tgt_NPP     = 'SAEUL'; end
if nargin < 3, tgt_TC      = '0314_MAEMI'; end
if nargin < 4, intensifier = '2.03'; end
if nargin < 5, numWorkers  = 96; end

%% Setup directories
inputDir  = fullfile(opath, tgt_NPP, tgt_TC, '08_BOGUS', intensifier);

% List target files (assumes filenames end with '00.nc')
mfList = dir(fullfile(inputDir, '*00.nc'));

%% Load RSMC Best Track Data
rs_path = '/data/2.DATA/DATA_SHARE/DATA/RSMC_BEST_TRACK';
bstFile = fullfile(rs_path, 'bst_all.txt');
RSMC = read_RSMC_track_all(bstFile);

load('/home/user_006/03_DATA/TC_INFO.mat')

%% Find target TC in TRACK (match before underscore)
tc_id = extractBefore(tgt_TC, '_');
idx_TC = find(arrayfun(@(x) strcmp(x.INT_NUMID, tc_id), RSMC), 1);
if isempty(idx_TC)
    error('TC with id %s not found in the best track data.', tc_id);
end
TC = RSMC(idx_TC);

% start_date = TC.TIME(1);
% end_date   = TC.TIME(end);

%% Take time range
pattern = '\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}';
sdateStr = regexp(mfList(1).name, pattern, 'match', 'once');
edateStr = regexp(mfList(end).name, pattern, 'match', 'once');

sdate = datenum(sdateStr,'yyyy-mm-dd_HH:MM:SS');
edate = datenum(edateStr,'yyyy-mm-dd_HH:MM:SS');
time_vec = sdate:1/24:edate;

%% Set rate of speedup to adjust translation speed 
rates = [-0.1 0.1];
rates(rates==0) = [];

%% Take parameters
tgt_1st_file = fullfile(mfList(1).folder,mfList(1).name);

LON = ncread(tgt_1st_file,'XLONG_M');
LAT = ncread(tgt_1st_file,'XLAT_M');
[utm_lon,utm_lat] = ll2utm(LAT,LON,52);
ULON = ncread(tgt_1st_file,'XLONG_U');
ULAT = ncread(tgt_1st_file,'XLAT_U');
VLON = ncread(tgt_1st_file,'XLONG_V');
VLAT = ncread(tgt_1st_file,'XLAT_V');

parpool(numWorkers)
for r_id = 1:length(rates)
    rate = rates(r_id);

    if rate < 0
        rateStr = num2str(rate*100);
    else
        rateStr = ['+' num2str(rate*100)];
    end

    outputDir = fullfile(opath, tgt_NPP, tgt_TC, '08_BOGUS', [intensifier rateStr]);
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    
    time_vec_nend = (time_vec(end) - time_vec(1)) / (1+rate);
    time_vec_new = linspace(time_vec(1),time_vec(1) + time_vec_nend, length(time_vec));
    ntime = round((time_vec_new(end) - time_vec_new(1))*24);
    time_vec_calc = time_vec_new(1) : 1/24 : time_vec_new(1)+1/24*(ntime-1);
    
    INTERP_VALUE.TIME = [];INTERP_VALUE.R30 = [];INTERP_VALUE.R50 = [];INTERP_VALUE.LON = [];INTERP_VALUE.LAT = [];
    INTERP_VALUE.VMAX = [];INTERP_VALUE.MSLP = [];
    
    for id = 1:length(RSMC(idx_TC).TIME)-1
        TIME_INTERP = (RSMC(idx_TC).TIME(id):1/24:RSMC(idx_TC).TIME(id+1) - 1/24)';
        R30_INTERP  = interp1([RSMC(idx_TC).TIME(id) RSMC(idx_TC).TIME(id+1)],[RSMC(idx_TC).R30L(id) RSMC(idx_TC).R30L(id+1)],TIME_INTERP) ;
        R50_INTERP  = interp1([RSMC(idx_TC).TIME(id) RSMC(idx_TC).TIME(id+1)],[RSMC(idx_TC).R50L(id) RSMC(idx_TC).R50L(id+1)],TIME_INTERP) ;
        LON_INTERP  = interp1([RSMC(idx_TC).TIME(id) RSMC(idx_TC).TIME(id+1)],[RSMC(idx_TC).LONGITUDE(id) RSMC(idx_TC).LONGITUDE(id+1)],TIME_INTERP) ;
        LAT_INTERP  = interp1([RSMC(idx_TC).TIME(id) RSMC(idx_TC).TIME(id+1)],[RSMC(idx_TC).LATITUDE(id) RSMC(idx_TC).LATITUDE(id+1)],TIME_INTERP) ;
        VMAX_INTERP = interp1([RSMC(idx_TC).TIME(id) RSMC(idx_TC).TIME(id+1)],[RSMC(idx_TC).VMAX_KNOT(id) RSMC(idx_TC).VMAX_KNOT(id+1)],TIME_INTERP) ;
        MSLP_INTERP = interp1([RSMC(idx_TC).TIME(id) RSMC(idx_TC).TIME(id+1)],[RSMC(idx_TC).MSLP(id) RSMC(idx_TC).MSLP(id+1)],TIME_INTERP) ;
        
        INTERP_VALUE.TIME = [INTERP_VALUE.TIME; TIME_INTERP];
        INTERP_VALUE.R30  = [INTERP_VALUE.R30; R30_INTERP];
        INTERP_VALUE.R50  = [INTERP_VALUE.R50; R50_INTERP];
        INTERP_VALUE.LON  = [INTERP_VALUE.LON; LON_INTERP];
        INTERP_VALUE.LAT  = [INTERP_VALUE.LAT; LAT_INTERP];
        INTERP_VALUE.VMAX = [INTERP_VALUE.VMAX; VMAX_INTERP];
        INTERP_VALUE.MSLP = [INTERP_VALUE.MSLP; MSLP_INTERP];
    end
    
    TIME_INTERP = time_vec_calc';
    TI.R30  = interp1(INTERP_VALUE.TIME,INTERP_VALUE.R30,TIME_INTERP) ;
    TI.R50  = interp1(INTERP_VALUE.TIME,INTERP_VALUE.R50,TIME_INTERP) ;
    TI.LON  = interp1(INTERP_VALUE.TIME,INTERP_VALUE.LON,TIME_INTERP) ;
    TI.LAT  = interp1(INTERP_VALUE.TIME,INTERP_VALUE.LAT,TIME_INTERP) ;
    TI.VMAX = interp1(INTERP_VALUE.TIME,INTERP_VALUE.VMAX,TIME_INTERP) ;
    TI.MSLP = interp1(INTERP_VALUE.TIME,INTERP_VALUE.MSLP,TIME_INTERP) ;
    
    parfor i = 1:length(time_vec_calc)-1
        temp_time = time_vec_calc(i);
        find_id = find(abs(temp_time-time_vec_new) == min(abs(temp_time-time_vec_new)));
        if(temp_time-time_vec_new(find_id(1)) < 0)
            after_id = find_id(1);
            before_id = find_id(1)-1;
            after_rate = 1-(time_vec_new(find_id(1))-temp_time)*24;
            before_rate = (time_vec_new(find_id(1))-temp_time)*24;
        else
            after_id = find_id(1)+1;
            before_id = find_id(1);
            after_rate = (temp_time - time_vec_new(find_id(1)))*24;
            before_rate = 1-(temp_time-time_vec_new(find_id(1)))*24;
        end

        R30 = TI.R30(i).*1.852*1000;
        [X_C,Y_C] = ll2utm(TI.LAT(i),TI.LON(i));
        [X_C2,Y_C2] = ll2utm(TI.LAT(i+1),TI.LON(i+1));
        
        tgt_bfile = fullfile(mfList(before_id).folder,mfList(before_id).name);
        tgt_afile = fullfile(mfList(after_id).folder,mfList(after_id).name);

        UU1   = ncread(tgt_bfile,'UU');
        UU2   = ncread(tgt_afile,'UU');
        VV1   = ncread(tgt_bfile,'VV');
        VV2   = ncread(tgt_afile,'VV');
        RH1   = ncread(tgt_bfile,'RH');
        RH2   = ncread(tgt_afile,'RH');
        GHT1  = ncread(tgt_bfile,'GHT');
        GHT2  = ncread(tgt_afile,'GHT');
        TT1   = ncread(tgt_bfile,'TT');
        TT2   = ncread(tgt_afile,'TT');
        PMSL1 = ncread(tgt_bfile,'PMSL');
        PMSL2 = ncread(tgt_afile,'PMSL');
        PSFC1 = ncread(tgt_bfile,'PSFC');
        PSFC2 = ncread(tgt_afile,'PSFC');

        NEW_RH   = RH1(:,:,:)   .* before_rate + RH2(:,:,:)   .*after_rate;
        NEW_TT   = TT1(:,:,:)   .* before_rate + TT2(:,:,:)   .*after_rate;
        NEW_GHT  = GHT1(:,:,:)  .* before_rate + GHT2(:,:,:)  .*after_rate;
        NEW_PMSL = PMSL1(:,:,:) .* before_rate + PMSL2(:,:,:) .*after_rate;
        NEW_PSFC = PSFC1(:,:,:) .* before_rate + PSFC2(:,:,:) .*after_rate;

        x_id = and(LON > TI.LON(i) - 3,LON < TI.LON(i) + 3);
        y_id = and(LAT > TI.LAT(i) - 3,LAT < TI.LAT(i) + 3);
        in_id = and(x_id,y_id);
        TEMP = NEW_PMSL;
        TEMP(~in_id) = 99999999999;
        [min_x,min_y] = find(TEMP == min(min(TEMP)));
        
        utm_r = sqrt((utm_lon - utm_lon(min_x(1),min_y(1))).^2 + (utm_lat - utm_lat(min_x(1),min_y(1))).^2);
        B = ones(size(utm_r));
        m = 1/R30;
        B(utm_r<=R30) = m.*abs(utm_r(utm_r<=R30) - R30).*0.5;
        B(B == 1) = 0;
        nan_id = isnan(B);
        B(nan_id) = 0;

        Vt = (sqrt((X_C2 - X_C).^2 + (Y_C2 - Y_C).^2)/((time_vec_calc(i+1) - time_vec_calc(i))*24*60*60))
        deg = atan2d((Y_C2 - Y_C),(X_C2 - X_C));
        u_vt = cosd(deg).*Vt; v_vt = sind(deg).*Vt;

        UB = griddata(double(LON),double(LAT),B,double(ULON),double(ULAT))*u_vt;
        VB = griddata(double(LON),double(LAT),B,double(VLON),double(VLAT))*v_vt;
        
        NEW_UU = UU1(:,:,:).*before_rate + UU2(:,:,:).*after_rate;
        NEW_VV = VV1(:,:,:).*before_rate + VV2(:,:,:).*after_rate;
        
        pattern = 'merge_met_em\.d01\.';
        prefix = regexp(mfList(1).name, pattern, 'match', 'once');
        new_file_name = fullfile(outputDir, [prefix datestr(time_vec_calc(i),'yyyy-mm-dd_HH:MM:SS') '.nc']);
        N_TIME = char(datestr(time_vec_calc(i),'yyyy-mm-dd_HH:MM:SS'))';
        copyfile(tgt_bfile,new_file_name);
        fileattrib(new_file_name,'+w');
        
        ncid = netcdf.open(new_file_name,'WRITE');
        varid = netcdf.inqVarID(ncid,'Times');
        netcdf.putVar(ncid,varid,N_TIME);
        varid = netcdf.inqVarID(ncid,'PMSL');
        netcdf.putVar(ncid,varid,NEW_PMSL);
        varid = netcdf.inqVarID(ncid,'PSFC');
        netcdf.putVar(ncid,varid,NEW_PSFC);
        varid = netcdf.inqVarID(ncid,'UU');
        netcdf.putVar(ncid,varid,NEW_UU);
        varid = netcdf.inqVarID(ncid,'VV');
        netcdf.putVar(ncid,varid,NEW_VV);
        varid = netcdf.inqVarID(ncid,'TT');
        netcdf.putVar(ncid,varid,NEW_TT);
        varid = netcdf.inqVarID(ncid,'GHT');
        netcdf.putVar(ncid,varid,NEW_GHT);
        varid = netcdf.inqVarID(ncid,'RH');
        netcdf.putVar(ncid,varid,NEW_RH);
        netcdf.close(ncid);
    end
end
end
