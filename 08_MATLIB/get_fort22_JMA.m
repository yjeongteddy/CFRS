function get_fort22_JMA(sdate,edate,spath)
% Get zonal and meridional wind, sea level pressure out of netCDF wind data from JMA
% Generate fort.22 dataset at the end of the whole process
% for ADCIRC storm surge simulation

start_date = datetime(sdate);
end_date = datetime(edate);
dt_array = start_date:1/24:end_date;

d_vec = datevec(start_date);
tg_year = d_vec(1);

if tg_year < 2006
    fac = 9.81*10; 
else
    fac = 9.81*10^3;
end

% backpress = 101300/fac; % Background Pressure

fgs = grd_to_opnml('C:\Users\admin\Desktop\Data\fort.14');
tic
parfor d_id = 1:length(dt_array)
    % Get date
    current_date = dt_array(d_id);
    find_file = [char(current_date,'MMdd') '.nc'];
    current_hour = round(str2double(char(current_date,'HH'))) + 1;
    
    % Load nc files
    lon = double(ncread(find_file,'lon'));
    lat = double(ncread(find_file,'lat'));
    slp = ncread(find_file,'psea');
    slp = slp/fac % Pa 2 hPa
    u = ncread(find_file,'u');
    v = ncread(find_file,'v');
    [x_mat,y_mat] = meshgrid(lon,lat);
    
    % Interpolate
    fort_22_num = 1:length(fgs.x);
    fort_22_u = griddata(x_mat,y_mat,u(:,:,current_hour)',fgs.x,fgs.y);
    fort_22_v = griddata(x_mat,y_mat,v(:,:,current_hour)',fgs.x,fgs.y);
    fort_22_p = griddata(x_mat,y_mat,slp(:,:,current_hour)',fgs.x,fgs.y);
    
    % Process NaN values
    nan_id = isnan(fort_22_p);
    nearest_id = zeros(size(fgs.x));
    for id = 1:length(fgs.x)
        if nan_id(id)
            dist = sqrt((fgs.x(id)-fgs.x).^2+(fgs.y(id)-fgs.y).^2);
            nearest_id(id) = find(min(dist(~nan_id)) == dist);
        end
    end
    fort_22_p(nan_id) = fort_22_p(nearest_id(nan_id));
    fort_22_u((isnan(fort_22_u))) = 0;
    fort_22_v((isnan(fort_22_v))) = 0;
    fort_22 = [fort_22_num' fort_22_u fort_22_v fort_22_p];
    
    % Save results
    writematrix(fort_22,[spath '/' char(current_date,'yyyyMMdd_') num2str(current_hour,'%02i') '.dat'],"Delimiter",' ')
    % dlmwrite([spath '/' char(current_date,'yyyyMMdd_') num2str(current_hour,'%02i') '.dat'], ...
    %          fort_22,'delimiter',' ','precision','%.5f');
end
toc
% flist = dir('*.dat');
% ds_col = [];
% for i  = 1:length(flist)
%     tg_file = load([flist(i).folder '/' flist(i).name]);
%     ds_col = [ds_col;tg_file];
% end
% save('fort.22','ds_col','-ascii')
end






