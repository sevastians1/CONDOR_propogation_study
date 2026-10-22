% download_lidar.m

%1. Take an initial lat/long border
top_lat     = 36.472698;
right_long  = -121.187473;

bot_lat     = 36.474441;
left_long   = -121.185413;


%1.b convert to USNG coords
[right_easting, north_northing] = latlon2USNG(top_lat, right_long);
[left_easting, south_northing] = latlon2USNG(bot_lat, left_long);

fprintf('\n================ Search Area Boundaries ================\n');
fprintf('Easting  Range (X): %d to %d\n', left_easting, right_easting);
fprintf('Northing Range (Y): %d to %d\n', south_northing, north_northing);
fprintf('=======================================================\n\n');

%2.a Load all text download links into array
laz_download_links = readlines("data\online_laz_download_links.txt");
laz_download_links = laz_download_links(strlength(laz_download_links) > 0); %Remove empty lines

%2.aa Create array to store matches
matching_links = strings(0, 1);

%2.b Iterate over all lines
for i = 1:length(laz_download_links)
    %2.c Get tileCode and easting/northing from name
        fileName = laz_download_links(i); 
        cleanName = erase(fileName, ".laz");
        %Get last 8 digits
        len       = strlength(cleanName);
        if len > 3 %if file exists
            tileCode  = extractBetween(cleanName, len - 7, len);
    
            eastingNum = str2double(extractBefore(tileCode, 5));  % "6654"
            northingNum = str2double(extractAfter(tileCode, 4));   % "4011"
    
            fprintf('Easting: %d | Northing: %d\n', eastingNum, northingNum);
    
        %2.d Check if tilecode is in specified range

        % Check whether the tile overlaps the ROI
        %Adding +5 because the lidar increments in 5's. 5919 doesn't exist,
        %but 5917 and 5922 do
            tileBuffer = 5;
            is_in_easting = (eastingNum >= min(left_easting, right_easting) - tileBuffer) && ...
                           (eastingNum <= max(left_easting, right_easting) + tileBuffer);
            is_in_northing = (northingNum >= min(south_northing, north_northing) - tileBuffer) && ...
                            (northingNum <= max(south_northing, north_northing) + tileBuffer);
            
            if is_in_easting && is_in_northing
                fprintf('Found tile in ROI: %s\n', fileName);
                matching_links(end + 1) = fileName;
                
            end
        end
end


% Save string array to text file
writelines(matching_links, 'data/lidar_search_area/search_area_download_links.txt');
