function [DESIGN_WAVE]= load_design_wave_data(DW_PATH,WIND_PATH)
    RETURN_PERIOD = [10 20 30 50 100];
    DIRECTION_VEC = {'N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW'};

    for ret_id = 1 : 5
        [num,txt,~] = xlsread(DW_PATH,ret_id);
        DESIGN_WAVE(ret_id).ret_period = RETURN_PERIOD(ret_id);
        data_id = ~isnan(num(:,1));
        DESIGN_WAVE(ret_id).location.lat = num(data_id,1);
        DESIGN_WAVE(ret_id).location.lon = num(data_id,2);
        DESIGN_WAVE(ret_id).wave_height = num(data_id,4:end);
        DESIGN_WAVE(ret_id).wave_period = num([false;data_id(1:end-1)],4:end);

        DESIGN_WAVE(ret_id).event = strcmp(txt([false;false;false;false;false;data_id(1:end-1)],5:end),'EC');
        % 1 = ºñÅÂÇ³(Extratropical Cyclone), 0 = ÅÂÇ³(Tropical Cyclone)

        [num,txt,~] = xlsread(WIND_PATH,ret_id);
        DESIGN_WAVE(ret_id).location.name = txt(4:2:end,1);
        DESIGN_WAVE(ret_id).wind_velocity = num(1:2:end,4:end);

        DESIGN_WAVE(ret_id).direction_vec = DIRECTION_VEC;
    end
end
