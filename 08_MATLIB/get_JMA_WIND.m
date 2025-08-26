function get_JMA_WIND(TOP_PATH,RUN_PATH,tc_num,tc_name,fgs,mname)
CURRENT_PATH = pwd;
load('/home/user_006/03_DATA/TC_INFO.mat');
find_id = strcmp(string(num2str(str2num(str2mat(TC_INFO(:,1))),'%04d')),tc_num);

period = str2mat(TC_INFO(find_id,3));
find_str = strfind(period,'~');
start_date = datenum(period(1:find_str-1),'yymmddHH');
end_date = datenum(period(find_str+1:end),'yymmddHH');
find_year = datestr(start_date,'yyyy');
cd([TOP_PATH find_year]);
list = dir('*.nc');
% days = str2num(datestr(end_date-start_date,'dd'))+1;
days = round(end_date-start_date)+1;

new_wind_path = [RUN_PATH mname '_' tc_num '_' tc_name];

mkdir(new_wind_path);

date_vec = start_date:1/24:end_date;

parfor date_id = 1:length(date_vec)
    current_date = date_vec(date_id);
    find_file = [datestr(floor(current_date),'mmdd') '.nc'];
    current_hour = round(str2num(datestr(current_date,'HH'))) + 1;
    
    lon = ncread(find_file,'lon');
    lat = ncread(find_file,'lat');
    u = ncread(find_file,'u');
    v = ncread(find_file,'v');
    [x_mat,y_mat] = meshgrid(lon,lat);
    u_unswan = griddata(double(x_mat),double(y_mat),double(u(:,:,current_hour)'),fgs.x,fgs.y);
    v_unswan = griddata(double(x_mat),double(y_mat),double(v(:,:,current_hour)'),fgs.x,fgs.y);
    vel_unswan = [u_unswan; v_unswan];
    vel_unswan(isnan(vel_unswan)) = 0;
    dlmwrite([new_wind_path  '/' datestr(current_date,'yyyymmdd_HH') '.dat'],vel_unswan,'precision','%.2f');
end
cd(CURRENT_PATH);
end
