function [easting, northing] = latlon2USNG(lat, lon)

    crs = projcrs(2228, 'Authority', 'EPSG'); 

    [easting, northing] = projfwd(crs, lat, lon);

    easting = floor(easting / 1000);
    northing = floor(northing/ 1000);

end
