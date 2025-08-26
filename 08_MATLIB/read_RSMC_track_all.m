function TRACK = read_RSMC_track_all(track_file)
track_count = 0;
fid = fopen(track_file);

while(1)
    line = fgetl(fid);
    if(line<0) break; end
    if(findstr(line,'66666') == 1)
        track_count = track_count + 1;
        count = 1;
        TRACK(track_count).INT_NUMID = line(7:10);
        TRACK(track_count).TC_NUMID  = line(22:25);
        TRACK(track_count).TC_NAME   = deblank(strtrim(line(31:59)));
        continue;
    end
    if(str2num(line(1:2))>50)
        TRACK(track_count).TIME(count)       = datenum(['19' line(1:8)],'yyyymmddHH');
    else
        TRACK(track_count).TIME(count)       = datenum(line(1:8),'yymmddHH');
    end
    TRACK(track_count).LATITUDE(count)   = str2num(line(15:18)) * 0.1;
    TRACK(track_count).LONGITUDE(count)  = str2num(line(20:23)) * 0.1;
    TRACK(track_count).MSLP(count)       = str2num(line(25:28));
    TEMP_VMAX = str2num(line(34:36));
    if(sum(size(TEMP_VMAX))==0)
        TRACK(track_count).VMAX_KNOT(count)  = (11.7 * (1010 - TRACK(track_count).MSLP(count)).^0.5) * 0.88;
        TRACK(track_count).VMAX_MPS(count)   = (11.7 * (1010 - TRACK(track_count).MSLP(count)).^0.5) * 0.514444 * 0.88;
    else
        TRACK(track_count).VMAX_KNOT(count)  = str2num(line(34:36));
        TRACK(track_count).VMAX_MPS(count)   = str2num(line(34:36)) * 0.5144;
    end
    
    TRACK(track_count).R50L(count) = 0;
    TRACK(track_count).R50S(count) = 0;
    TRACK(track_count).R30L(count) = 0;
    TRACK(track_count).R30S(count) = 0;
    TRACK(track_count).R50D(count) = 9;
    TRACK(track_count).R30D(count) = 9;
    if(length(deblank(line)) > 61)
        TRACK(track_count).R50D(count) = str2num(line(42));
        TRACK(track_count).R50L(count) = str2num(line(43:46));
        TRACK(track_count).R50S(count) = str2num(line(48:51));
        
        TRACK(track_count).R30D(count) = str2num(line(53));
        TRACK(track_count).R30L(count) = str2num(line(54:57));
        TRACK(track_count).R30S(count) = str2num(line(59:62));
    end
    TRACK(track_count).R0_KM(count) = TRACK(track_count).R30L(count) * 1.852;
    if(TRACK(track_count).R0_KM(count) == 0)
        TRACK(track_count).R0_KM(count) = 300 + ((1010-TRACK(track_count).MSLP(count)) - 50 ) * 4;
    end
    count = count + 1;
end
end
