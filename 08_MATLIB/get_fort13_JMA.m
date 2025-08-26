function get_fort13_JMA(tpath)
% run_list = dir('*.22');
% for i = 1:length(run_list)
%     cd(run_list(i).name)
%     system(['head -n ' num2str(length(fgs.x)) ' ' run_list(i).name(8:end) '_PRESS/fort.22' ...
%         ' > ' run_list(i).name(8:end) '_PRESS/fort.22_first']);
% end
% fort22 = load([run_list(i).name(8:end) '_PRESS/fort.22_first']);
fort22 = load(tpath);

fgs = grd_to_opnml('C:\Users\admin\Desktop\Data\fort.14');

lth = length(fgs.z);

id_jump = 1;
id_start = lth*(id_jump-1)+1;
id_end   = lth*(id_jump);
target  = fort22(id_start:id_end,4)'*100;

base = 1033;  % adcirc ramp 6611th line in wind.F
ele = -(target - base)/100;

fid = fopen('fort.13','w');
fprintf(fid, 'Spatial attributes description\n');
fprintf(fid, '%d\n',lth);
fprintf(fid, '%d\n',1);
fprintf(fid, 'sea_surface_height_above_geoid\n');
fprintf(fid, 'm\n');
fprintf(fid, '%d\n',1);
fprintf(fid, '%f\n',0.000000);
fprintf(fid, 'sea_surface_height_above_geoid\n');
fprintf(fid, '%d\n',lth);

for k = 1 : lth
    fprintf(fid,'%d %10.6f\n',k,ele(k));
end
fclose(fid);
clear fort22
cd('../')

end
