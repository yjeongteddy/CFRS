clc;clear;close all;

%% target folder
cd 'S:\home\user_006'
cd 'C:\Users\admin\Desktop\Data'

%% plot sample target area
% 한울
lat = [37.07 37.1];
lon = [129.34 129.46];

% 월성
lat = [35.69 35.72];
lon = [129.45 129.5];

% 고리
lat = [35.32 35.34];
lon = [129.29 129.34];

% 영광
lat = [35.39 35.44];
lon = [126.38 126.435];

% plot
figure;hold on;set(gcf,'position',[507 204 831 622]);
ax(1) = subplot(1,1,1);
plot(lon,lat,'.k','MarkerSize',1);
ax1 = plot_google_map('Resize',2,'MapType','satellite','style','feature:all|color:0xff0000', ...
    'MapScale',1,'APIKey','AIzaSyA--EREY_h9EJFK9M9HDo0AT2Dd0EZSNmw');
ax1.CData = rgb2gray(ax1.CData);
colormap('gray');
xlabel('Longitude (\circE)','FontWeight','b','FontSize',13);
ylabel('Latitude (\circN)','FontWeight','b','FontSize',13);
set(ax(1).XAxis,'FontWeight','b','FontSize',11);
set(ax(1).YAxis,'FontWeight','b','FontSize',11);
xtickformat('%.2f'); ytickformat('%.2f');

%% Tidal components
% hanwool
M2(1)=4.8;S2(1)=1.4;K1(1)=4.2;O1(1)=4.1;
% wolsung
M2(2)= 6.3;S2(2)= 2.7;K1(2)= 3.6;O1(2)= 3.7;
% kori
M2(3)= 24.1;S2(3)= 11.5;K1(3)= 3.1;O1(3)= 2.2;
% hanbit
M2(4)= 204.2;S2(4)= 77.4;K1(4)= 34;O1(4)= 26.1;

%% extract target depth
clc;clear all;close all;

cd 'path'
hanbit_raw = load('Hanbit_DL_Scatter_depth.mat').FINAL_DL;
wolsung_raw = load('Wolsung_DL_Scatter_depth.mat').FINAL_DL;
hanwool_raw = load('Hanwool_DL_Scatter_depth.mat').FINAL_DL;
kori_raw = load('Kori_DL_Scatter_depth.mat').FINAL_DL;

% Hanwool
x_id = and(hanwool_raw.x >= lon(1), hanwool_raw.x <= lon(2));
y_id = and(hanwool_raw.y >= lat(1), hanwool_raw.y <= lat(2));
in_id  = and(x_id,y_id);

hanwool.x = hanwool_raw.x(in_id);
hanwool.y = hanwool_raw.y(in_id);
hanwool.z = hanwool_raw.z(in_id);

% Wolsung
x_id = and(walsung_raw.x >= lon(1), walsung_raw.x <= lon(2));
y_id = and(walsung_raw.y >= lat(1), walsung_raw.y <= lat(2));
in_id  = and(x_id,y_id);

wolsung.x = wolsung_raw.x(in_id);
wolsung.y = wolsung_raw.y(in_id);
wolsung.z = wolsung_raw.z(in_id);

% Hanbit
x_id = and(hanbit_raw.x >= lon(1), hanbit_raw.x <= lon(2));
y_id = and(hanbit_raw.y >= lat(1), hanbit_raw.y <= lat(2));
in_id  = and(x_id,y_id);

hanbit.x = hanbit_raw.x(in_id);
hanbit.y = hanbit_raw.y(in_id);
hanbit.z = hanbit_raw.z(in_id);

% Kori
x_id = and(kori_raw.x >= lon(1), kori_raw.x <= lon(2));
y_id = and(kori_raw.y >= lat(1), kori_raw.y <= lat(2));
in_id  = and(x_id,y_id);

kori.x = kori_raw.x(in_id);
kori.y = kori_raw.y(in_id);
kori.z = kori_raw.z(in_id);

% Hanwool test
lonvec = lon(1):0.001:lon(2);
latvec = lat(1):0.001:lat(2);

[mlon,mlat] = meshgrid(lonvec,latvec);

vq = griddata(hanwool.x,hanwool.y,hanwool.z,mlon,mlat);

save('Hanwool_mdpth','vq','.mat');

figure;hold on;set(gcf,'position',[507 204 831 622]);
ax(1) = subplot(1,1,1);
plot(lon,lat,'.k','MarkerSize',1);
ax1 = plot_google_map('Resize',2,'MapType','satellite','style','feature:all|color:0xff0000', ...
    'MapScale',1,'APIKey','AIzaSyA--EREY_h9EJFK9M9HDo0AT2Dd0EZSNmw');
ax1.CData = rgb2gray(ax1.CData);
colormap('gray');
xlabel('Longitude (\circE)','FontWeight','b','FontSize',13);
ylabel('Latitude (\circN)','FontWeight','b','FontSize',13);
set(ax(1).XAxis,'FontWeight','b','FontSize',11);
set(ax(1).YAxis,'FontWeight','b','FontSize',11);
xtickformat('%.2f');ytickformat('%.2f');

contour(mlon,mlat,vq)

















