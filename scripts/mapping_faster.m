%% SCRAP THIS SCRIPT

% 1.a Load the LiDAR tile and read the point cloud
fileName = 'data/raw_lidar/USGS_LPC_CA_AZ_FEMA_R9_Lidar_2017_D18_59172061.laz';
reader = lasFileReader(fileName);
ptCloud = readPointCloud(reader);

% 1.b Read ONLY Class 2 (Ground) points directly from the file
ptCloudGround = readPointCloud(reader, 'Classification', 2);

% 2.a Extract raw coordinates directly from your pointCloud object
X = ptCloudGround.Location(:, 1);
Y = ptCloudGround.Location(:, 2);
Z = ptCloudGround.Location(:, 3);


% 2.a Get x and y limits of box
gridStep = 3.28084;
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

% 3. Fill the empty 2D array with data from ptCloudGround

%3.a 
colIdx = min(floor((X - xMin) / gridStep) + 1, numCols);
rowIdx = min(floor((Y - yMin) / gridStep) + 1, numRows);
linearIdx = sub2ind([numRows, numCols], rowIdx, colIdx);

% Accumulate Z values directly
zSum   = accumarray(linearIdx, Z, [numRows * numCols, 1], @sum, NaN);
zCount = accumarray(linearIdx, 1, [numRows * numCols, 1], @sum, 0);

% Final DTM Elevation Grid (Array 3)
Z_elevation = reshape(zSum ./ zCount, [numRows, numCols]);

% Final Coordinate Grids (Arrays 1 and 2)
[X_grid, Y_grid] = meshgrid(xRange, yRange);

% Clear temporary variables to free RAM
clear X Y Z colIdx rowIdx linearIdx zSum zCount;

% 5. Visualize the 3D Bare-Earth Terrain

%% 4. Plot 3D Interactive Surface with NaN Transparency
figure('Name', 'Interactive 1-meter LiDAR DTM', 'Color', 'w');
surf(X_grid, Y_grid, Z_elevation, 'EdgeColor', 'none');

% Styling & Performance Optimization
shading interp;
colorbar;
axis equal;
view(-37.5, 30);
xlabel('Easting (ft)'); ylabel('Northing (ft)'); zlabel('Elevation (ft)');
title('Pinnacles NP 1-Meter Bare-Earth DTM');

% Activate 3D rotation
rotate3d on;