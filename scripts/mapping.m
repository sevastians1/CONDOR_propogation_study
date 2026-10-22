%% 1.a Load the LiDAR tile and read the point cloud
fileName = 'data/raw_lidar/USGS_LPC_CA_AZ_FEMA_R9_Lidar_2017_D18_59172061.laz';

% 2. Automatically extract just the file name (without path or extension)
[~, baseFileName, ~] = fileparts(fileName);
% baseFileName is now: 'USGS_LPC_CA_AZ_FEMA_R9_Lidar_2017_D18_59172061'

% 3. Extract the trailing tile ID numbers using a regular expression
tileID = regexp(baseFileName, '\d+$', 'match'); 
tileID = tileID{1}; % Converts cell array to string ('59172061')

% 4. Construct a clean, dynamic output filename
outputFileName = sprintf('processed_tile_%s.mat', tileID);
% outputFileName is now: 'processed_tile_59172061.mat'

reader = lasFileReader(fileName);
ptCloud = readPointCloud(reader);

% 1.b Read ONLY Class 2 (Ground) points directly from the file
%Class 2: Ground Class 3: Low vegetation Class 4: Medium vegetation Class 5: High vegetation
ptCloudGround = readPointCloud(reader, 'Classification', 2);

%% 2.a Extract raw coordinates directly from your pointCloud object
X = ptCloudGround.Location(:, 1);
Y = ptCloudGround.Location(:, 2);
Z = ptCloudGround.Location(:, 3);


% 2.a Get x and y limits of box
gridStep = 3.28084; %in m
xMin = ptCloudGround.XLimits(1); xMax = ptCloudGround.XLimits(2);
yMin = ptCloudGround.YLimits(1); yMax = ptCloudGround.YLimits(2);

%2.b Create 2D array that represents the area to be mapped
xRange = xMin : gridStep : xMax;
yRange = yMin : gridStep : yMax;

%2.c Define the amt of data to be filled
numCols = length(xRange);
numRows = length(yRange);

% 2.d Clear reader/ptCloud to free up RAM immediately
clear reader ptCloudGround;

%% 3. Fill the empty 2D array with data from ptCloudGround

% Map each ground point to its 2D grid cell index
colIdx = min(max(floor((X - xMin) / gridStep) + 1, 1), numCols);
rowIdx = min(max(floor((Y - yMin) / gridStep) + 1, 1), numRows);

% Convert 2D (row, col) coordinates to 1D linear matrix indices
linearIdx = sub2ind([numRows, numCols], rowIdx, colIdx);

% Average Z elevations in each cell using accumarray
Z_elevation = accumarray(linearIdx, Z, [numRows * numCols, 1], @median, NaN);
Z_elevation = reshape(Z_elevation, [numRows, numCols]);

% Create full 2D coordinate matrices for plotting
[X_grid, Y_grid] = meshgrid(xRange, yRange);

%% 4. Plot 3D Interactive Surface with NaN Transparency
ds = 1;  % Set downsample factor (1 = full data, 2 = 1/4 data points, 3 = 1/9 data points)

figName = sprintf('Interactive %.2f-ft LiDAR DTM', gridStep);

figure('Name', figName, 'Color', 'w');

% Force hardware OpenGL rendering for smooth performance
set(gcf, 'Renderer', 'opengl', 'GraphicsSmoothing', 'off');

% Plot downsampled grid with MATLAB default color mapping
hSurf = surf(X_grid(1:ds:end, 1:ds:end), ...
             Y_grid(1:ds:end, 1:ds:end), ...
             Z_elevation(1:ds:end, 1:ds:end), ...
             'EdgeColor', 'none');

% Styling & View Optimization
shading interp;
axis equal;
view(-37.5, 30);
xlabel('Easting (ft)'); ylabel('Northing (ft)'); zlabel('Elevation (ft)');
figTitle = sprintf('Pinnacles NP Bare-Earth DTM (Grid Step: %.2f ft, DS: %dx)', gridStep, ds);
title(figTitle);

% Activate 3D rotation
rotate3d on;

%TODO: 
% Expand this to many tiles
%-Fix the blackened areas
%-Save the processed z data
%- Figure out how to save signal strength data and map that as color