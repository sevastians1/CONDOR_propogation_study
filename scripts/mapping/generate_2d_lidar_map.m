% 1. Load your tile data into a container structure
D = load('C:\Users\sevas\Documents\MATLAB\CONDOR\data\processed_lidar_tiles\tile_59132061.mat');

% 2. Extract your grids
X = D.tileData.EastingGrid;
Y = D.tileData.NorthingGrid;
Z = D.tileData.ElevationGrid;

figure('Color', 'white');

% 3. Choose your contour style:

% --- Option A: Filled Contour Map (Smoothed elevation bands with a color gradient) ---
%contourf(X, Y, Z, 20, 'LineColor', 'none'); 

% --- Option B: Traditional Line Contours (Uncomment below if you want visible contour lines) ---
contour(X, Y, Z, 25, 'LineWidth', 0.8, 'ShowText', 'on'); 

% 4. Format the plot
grid off
axis image;       % Keeps spatial proportions square
colorbar;         % Adds scale bar for elevation
colormap('parula'); % Colormap (or use demcmap(Z) for automatic elevation coloring)
title('Topographic Contour Map');
xlabel('Easting (m)');
ylabel('Northing (m)');



%------------------------Do not run this------------------

xVector = D.tileData.EastingGrid(1, :);
yVector = D.tileData.NorthingGrid(:, 1);

figure('Color', 'white');
% Pass xVector and yVector so the axes show real UTM/State Plane coordinates
imagesc(xVector, yVector, D.tileData.ElevationGrid);
set(gca, 'YDir', 'normal'); % Ensures North points up correctly
axis image;
colorbar;
colormap(terrain); % 'terrain' or 'parula' work great for elevation
title('2D Elevation Map');
xlabel('Easting (m)');
ylabel('Northing (m)');

hold on;
scatter(D.tileData.Veg.VegEasting, D.tileData.Veg.VegNorthing, 5, 'green', 'filled');
hold off;

%---------------Script to run it faster with contours

figure('Color', 'white');

% 1. Fast background elevation raster (handles the heavy lifting instantly)
imagesc(D.tileData.EastingGrid(1, :), D.tileData.NorthingGrid(:, 1), D.tileData.ElevationGrid);
set(gca, 'YDir', 'normal');
axis image;
colorbar;
hold on;

% 2. Clean, sparse vector contour lines overlaid on top (using a downsampled step for speed)
step = 1; 
contour(D.tileData.EastingGrid(1, 1:step:end), ...
    D.tileData.NorthingGrid(1:step:end, 1), ...
    D.tileData.ElevationGrid(1:step:end, 1:step:end), ...
    25, 'LineColor', 'k', 'LineWidth', 0.5); % 10 black topo lines

hold off;
title('Hybrid Map: Fast Raster Base + Vector Contours');