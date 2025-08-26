function PostWRF_home(tgt_tc, tgt_NPP, intensity, tc_int, tc_vel, rpath)

addpath(genpath('S:/home/user_006/08_MATLIB'))

%% Parameters
if nargin < 1, tgt_tc    = '1215_BOLAVEN'; end
if nargin < 2, tgt_NPP   = 'HANBIT'; end
if nargin < 3, intensity = '1.30'; end
if nargin < 4, tc_int    = '30.17'; end
if nargin < 5, tc_vel    = '0%'; end
if nargin < 6, rpath     = 'S:/home/user_006/01_WORK/2025/NPP'; end

opath     = fullfile(rpath, '05_DATA/processed');
wpath     = fullfile(opath, tgt_NPP, tgt_tc, '09_WRF', intensity);
fpath     = fullfile(rpath, '04_FIGURE');
spath_w   = fullfile(fpath, tgt_NPP, tgt_tc, 'WIND_noleg', intensity);
spath_p   = fullfile(fpath, tgt_NPP, tgt_tc, 'PRS', intensity);
if ~exist(spath_w, 'dir'), mkdir(spath_w); end
if ~exist(spath_p, 'dir'), mkdir(spath_p); end

%% Load needed data
load('S:/home/user_006/03_DATA/LARGE_COAST.mat') % coastline data

%% Take out uneccessary areas
xs = 120; xe = 145; ys = 26; ye = 47; % set target area
% xs = 125; xe = 130; ys = 32; ye = 38;
toRemove = arrayfun(@(c) any(c.X > xs & c.X < xe & c.Y > ys & c.Y < ye) && (length(c.X) < 200), COAST);

N_C = COAST(~toRemove);

%% Do the work
cd(wpath);

% lon = load('BASE_WRF/longitude.dat');
% lat = load('BASE_WRF/latitude.dat');
lon = load('longitude.dat');
lat = load('latitude.dat');
u_list = dir('u10_*'); % index target data
v_list = dir('v10_*');
p_list = dir('slp_*');

for k = 1:length(u_list) % convert all time step into Julian
    tgt_ulist = u_list(k).name;
    if contains(tgt_ulist, '%3A')
        u_list(k).name = strrep(tgt_ulist, '%3A', ':');
        c_times(k) = datenum(u_list(k).name(5:end), 'yyyy-mm-dd_HH:MM:SS');
    else
        c_times(k) = datenum(tgt_ulist(5:end),'yyyy-mm-dd_HH:MM:SS');
    end
end

idx_uscore = strfind(u_list(1).name,'_'); % where the underscore is
tgt_idx = idx_uscore(2); % see hour info from start time
s_hour = u_list(1).name(tgt_idx+1:tgt_idx+2); % take the hour info

time_intvl = 0:3:18; % target time interval to extract (6 hourly)

if ismember(str2double(s_hour),time_intvl) % if hour on start time belongs to target time interval
    ts_date = datenum(u_list(1).name(5:end),'yyyy-mm-dd_HH:MM:SS'); % Convert start time to Julian
    te_date = datenum(u_list(end).name(5:end),'yyyy-mm-dd_HH:MM:SS'); % Convert end time to Julian
    
    time_vec = ts_date:3/24:te_date; % re-set time frame (6 hourly)
    
    [~,idx_tg_time] = ismember(time_vec,c_times); % index re-seted time frame from the original time frame
    
else 
    k = 2;
    while 1 % find which index belongs to target time interval for the first time
        idx_uscore = strfind(u_list(k).name,'_');
        tgt_idx = idx_uscore(2);
        s_hour = u_list(k).name(tgt_idx+1:tgt_idx+2);
        if ismember(str2double(s_hour),time_intvl)
            break
        else
            k = k + 1;
        end
    end
    ts_date = datenum(u_list(k).name(5:end),'yyyy-mm-dd_HH:MM:SS');
    te_date = datenum(u_list(end).name(5:end),'yyyy-mm-dd_HH:MM:SS');
    
    time_vec = ts_date:3/24:te_date;

    [~,idx_tg_time] = ismember(time_vec,c_times);
end

u_list = dir('u10_*'); % index target data
v_list = dir('v10_*');
p_list = dir('slp_*');

% final_max_mag = 0;
% final_linear_idx = 0;
for t_id = 20:length(idx_tg_time) % our target time interval index info from original time frame
    u_cur = load(u_list(idx_tg_time(t_id)).name);
    v_cur = load(v_list(idx_tg_time(t_id)).name);
    p_cur = load(p_list(idx_tg_time(t_id)).name);
    u_mag = sqrt(u_cur.^2 + v_cur.^2);
    
    % [tgt_max_mag, tgt_linear_idx] = max(u_mag(:));
    % tgt_max_mag_1m = tgt_max_mag*1.18;
    % if tgt_max_mag_1m > final_max_mag
    %     final_max_mag = tgt_max_mag_1m;
    %     final_linear_idx = tgt_linear_idx;
    %     final_lat = lat(final_linear_idx);
    % end
    
    % Windfield
    clf; hold on; set(gcf,'position',[-1628 -3 1376 994]);
    h = pcolor(lon,lat,u_mag/0.8144);
    disp(max(max(u_mag/0.8144)))
    disp(t_id)
    set(h,'EdgeColor','None');
    xtickformat('%.1f');
    ytickformat('%.1f');
    clim([0 60]);
    c = colorbar();
    colormap(jet);
    xlabel('Longitude (\circE)');
    ylabel('Latitude (\circN)');
    set(gca,'FontSize',25); % modify whole axis fontsize
    set(gca,'Box','on'); % encircle thick line around figure
    set(gca,'LineWidth',3);
    for coast_id = 1:length(N_C) % fill color on continent
        plot(N_C(coast_id).X,N_C(coast_id).Y,'w-','LineWidth',1);
    end
    axis equal;
    xlim([xs xe]); ylim([ys ye]);
    set(gcf,'Color','w');
    ax = gcf;
    drawnow;
    
    % rectangle('Position',[120.1 42.7 9 4.2],'EdgeColor','k','FaceColor','w')
    % y_loc_vec = linspace(43.5,46.6,5);
    % x_loc = 120.3;
    % text(x_loc+0.01,46.7296,'[Specifications]','FontWeight','bold','VerticalAlignment','top','FontSize',20);
    % text(x_loc+0.015,y_loc_vec(4),['TC Name' ' : ' strrep(tgt_tc,'_',' ')],'VerticalAlignment','top','FontSize',18);
    % text(x_loc+0.015,y_loc_vec(3),['Intensity increment' ' : ' tc_int],'VerticalAlignment','top','FontSize',18);
    % text(x_loc+0.015,y_loc_vec(2),['Translation increment' ' : ' tc_vel],'VerticalAlignment','top','FontSize',18);
    % text(x_loc+0.015,y_loc_vec(1),['Unit' ' : ' 'm/s'],'VerticalAlignment','top','FontSize',18);
    
    % best way to save current figure with the highest resolution
    % print('-vector', fullfile(spath_w, [datestr(time_vec(t_id),'yyyy-mm-dd_HH') '.png']),'-dpng','-r300');
    
    % Prsfield
    % figure;hold on;set(gcf,'position',[310 -3 1376 993]);
    % h = pcolor(lon,lat,p_cur);
    % set(h,'EdgeColor','None');
    % xtickformat('%.1f');
    % ytickformat('%.1f');
    % clim([950 1010]);
    % c = colorbar();
    % colormap(flipud(jet));
    % xlabel('Longitude (\circE)');
    % ylabel('Latitude (\circN)');
    % set(gca,'FontSize',25);
    % set(gca,'Box','on');
    % set(gca,'LineWidth',3);
    % for coast_id = 1 : length(N_C)
    %     plot(N_C(coast_id).X,N_C(coast_id).Y,'w-','LineWidth',1);
    % end
    % set(gcf,'Color','w');
    % axis equal;
    % xlim([xs xe]); ylim([ys ye]);
    % ax = gcf;

    % rectangle('Position',[120.1 42.7 9 4.2],'EdgeColor','k','FaceColor','w')
    % y_loc_vec = linspace(43.5,46.6,5);
    % x_loc = 120.3;
    % text(x_loc+0.01,46.7296,'[Specifications]','FontWeight','bold','VerticalAlignment','top','FontSize',20);
    % text(x_loc+0.015,y_loc_vec(4),['TC Name' ' : ' strrep(tgt_tc,'_',' ')],'VerticalAlignment','top','FontSize',18);
    % text(x_loc+0.015,y_loc_vec(3),['Intensity increment' ' : ' tc_int],'VerticalAlignment','top','FontSize',18);
    % text(x_loc+0.015,y_loc_vec(2),['Translation increment' ' : ' tc_vel],'VerticalAlignment','top','FontSize',18);
    % text(x_loc+0.015,y_loc_vec(1),['Unit' ' : ' 'hPa'],'VerticalAlignment','top','FontSize',18);
    
    % print('-vector', fullfile(spath_p, [datestr(time_vec(t_id),'yyyy-mm-dd_HH') '.png']),'-dpng','-r300');
end
end
    








































