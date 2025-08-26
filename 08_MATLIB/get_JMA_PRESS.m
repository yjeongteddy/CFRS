function get_JMA_PRESS(TOP_PATH,RUN_PATH,tc_name,fgs)
CURRENT_PATH = pwd;

tc_name = '5914_SARAH';

load('/home/user_006/03_DATA/TC_INFO.mat');
find_id = strcmp(num2str(str2num(tc_name(1:4)),'%04d'),(TC_INFO(:,1)));

% cd([tc_file_loc 'SWAN_' tc_name])
temp_time = str2mat(TC_INFO(find_id,3));
str_id = findstr(temp_time,'~');
start_date = datenum(temp_time(1:str_id-1),'yymmddHH');
end_date =  datenum(temp_time(str_id+1:end),'yymmddHH');
find_year = datestr(start_date,'yyyy');
cd([TOP_PATH find_year]);
list = dir('*.nc');
% days = str2num(datestr(end_date-start_date,'dd'))+1;
days = round(end_date-start_date)+1;

new_wind_path = [RUN_PATH 'ADCIRC_' tc_name];
new_wind_path_pressure = [RUN_PATH 'ADCIRC_' tc_name '/' tc_name '_PRESS'];

% mkdir(new_wind_path);
mkdir(new_wind_path_pressure);

% select fac
if str2num(find_year) < 2006
    fac = 9.81*10;            % convert Pa to meters of water
else
    fac = 9.81*10^3;            % convert Pa to meters of water
end

backpress = 101300/fac;     % Background Pressure

date_vec = start_date : 1/24 : end_date;

parfor date_id = 1 : length(date_vec)
    current_date = date_vec(date_id);
    find_file = [datestr(floor(current_date),'mmdd') '.nc'];
    current_hour = round(str2num(datestr(current_date,'HH'))) + 1;
    lon = ncread(find_file,'lon');
    lat = ncread(find_file,'lat');
    press = ncread(find_file,'psea');
    press = press/fac % hPa 2 Pa
    u = ncread(find_file,'u');
    v = ncread(find_file,'v');
    [x_mat,y_mat] = meshgrid(lon,lat);
    
    fort_22_num = 1:1:length(fgs.x);
    fort_22_u = griddata(double(x_mat),double(y_mat),double(u(:,:,current_hour)'),fgs.x,fgs.y);
    fort_22_v = griddata(double(x_mat),double(y_mat),double(v(:,:,current_hour)'),fgs.x,fgs.y);
    fort_22_p = griddata(double(x_mat),double(y_mat),double(press(:,:,current_hour)'),fgs.x,fgs.y);
    nan_id = isnan(fort_22_p);
    nearest_id = zeros(size(fgs.x));
    for id = 1 : length(fgs.x)
        if(nan_id(id))
            dist = sqrt( (fgs.x(id) - fgs.x).^2  + ...
                (fgs.y(id) - fgs.y).^2 );
            nearest_id(id) = find(min(dist(~nan_id)) == dist);
        end
    end
    fort_22_p(nan_id) = fort_22_p(nearest_id(nan_id));
    fort_22_u((isnan(fort_22_u))) = 0;
    fort_22_v((isnan(fort_22_v))) = 0;
    fort_22 = [fort_22_num' fort_22_u fort_22_v fort_22_p];
    dlmwrite([new_wind_path_pressure  '/' datestr(current_date,'yyyy-mm-dd_') num2str(current_hour,'%02i') '.dat'], ...
             fort_22, 'delimiter', ' ','precision','%.5f');
end
cd(new_wind_path_pressure)
% system('type *.dat > fort.22');
system('cat *.dat > fort.22 &');
cd(CURRENT_PATH);
end

