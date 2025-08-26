function decimalDegrees = dms2dd(degrees, minutes, seconds)
    % Convert DMS (Degrees, Minutes, Seconds) to Decimal Degrees
    decimalDegrees = degrees + (minutes / 60) + (seconds / 3600);
end