%Download files defined in lidar_search_area/ folder

% 1. Read download links from text file
inputFile = 'data/lidar_search_area/search_area_download_links.txt'; % Update with your output filename
download_urls = readlines(inputFile);

% 1.a Remove any blank trailing lines
download_urls = download_urls(strlength(download_urls) > 0);


% 2. Specify target destination folder
outputFolder = 'data/raw_lidar/';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Set web timeout options for large file downloads
options = weboptions('Timeout', 20000); 

% 3. Loop through links and download
fprintf('Starting download of %d files to ./%s...\n', length(download_urls), outputFolder);

for i = 1:length(download_urls)
    url = download_urls(i);

    % 3.1 Extract filename from URL (e.g., "USGS_LPC_..._.laz")
    [filepath, fileName, ext] = fileparts(url);
    localPath = fullfile(outputFolder, fileName + ext);

    % Download if file does not already exist
    if exist(localPath, 'file') == 0
        fprintf('[%d/%d] Downloading: %s...\n', i, length(download_urls), fileName + ext);
        
        try
            websave(localPath, url, options);
            fprintf(' -> Success!\n');
        catch ME
            fprintf(' -> Failed! Error: %s\n', ME.message);
        end
    else
        fprintf('[%d/%d] Skipping (already downloaded): %s\n', i, length(download_urls), fileName + ext);
    end
end

fprintf('\nAll downloads completed!\n');