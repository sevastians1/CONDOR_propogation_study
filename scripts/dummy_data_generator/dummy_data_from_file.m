
function T = dummy_data_from_file(filename)
% GPX_TO_UTM Extract GPS coordinates and convert to UTM Zone 10N.
%
% Usage:
%   T = gpx_to_utm("trail.gpx")
%
% Output CSV:
%   trail_utm.csv
%
% Requires MATLAB Mapping Toolbox.

    % Read GPX file
    gpx = readgeotable(filename, "Layer", "track_points");

    % Extract latitude and longitude
    latitude = gpx.Shape.Latitude;
    longitude = gpx.Shape.Longitude;

    % Convert to UTM Zone 10N (EPSG:26910)
    crs = projcrs(26910);
    [easting, northing] = projfwd(crs, latitude, longitude);

    % Create output table
    T = table(latitude, longitude, easting, northing);

    % Generate output filename
    [folder, name, ~] = fileparts(filename);
    output_file = fullfile(folder, name + "_utm.csv");

    % Export CSV
    writetable(T, output_file);

    fprintf("Exported %d GPS points to %s\n", ...
        height(T), output_file);
end
