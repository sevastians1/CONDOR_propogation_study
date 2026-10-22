%Takes latitude/longitude, returns 8 digit from NAD83 format
%Lat/lon use a different type of math. To convert, we use matlab built in 
%projcrs tool

function [lat, lon] = USNG2latlon(easting, northing)

    % 1.Set up the California State Plane Zone 4
    crs = projcrs(2228, 'Authority', 'EPSG'); 
    
    % 2: Perform forward projection math
    [lat, lon] = projinv(crs, easting, northing);

end