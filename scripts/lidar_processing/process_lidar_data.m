function process_lidar_data(fileName)
    
    %% 1.a Load the LiDAR tile and read the point cloud
    fprintf('Loading LiDAR file: %s\n', fileName);
    reader = lasFileReader(fileName);
    
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
    clear ptCloudGround;
    
    %% 3. Fill the empty 2D array with data from ptCloudGround
    
    % Map each ground point to its 2D grid cell index
    colIdx = min(max(floor((X - xMin) / gridStep) + 1, 1), numCols);
    rowIdx = min(max(floor((Y - yMin) / gridStep) + 1, 1), numRows);
    
    % Convert 2D (row, col) coordinates to 1D linear matrix indices
    linearIdx = sub2ind([numRows, numCols], rowIdx, colIdx);
    
    % Average Z elevations in each cell using accumarray
    Z_elevation = accumarray(linearIdx, Z, [numRows * numCols, 1], @median, NaN);
    Z_elevation = reshape(Z_elevation, [numRows, numCols]);
    
    %Construct the X grid and ygrid
    [X_grid, Y_grid] = meshgrid(xRange, yRange);
    X_grid = single(X_grid);
    Y_grid = single(Y_grid);
    clear X Y Z colIdx rowIdx linearIdx zSum zCount;
    
    
    %% 4. Process Vegetation Points (Classes 3, 4, 5) -> 3D Obstacles
    fprintf('Extracting vegetation points...\n');
    ptCloudVeg = readPointCloud(reader, 'Classification', [3, 4, 5]);
    Xv = ptCloudVeg.Location(:, 1);
    Yv = ptCloudVeg.Location(:, 2);
    Zv = ptCloudVeg.Location(:, 3);
    clear reader ptCloudVeg;
    
    % Heavy downsampling for vegetation to keep storage
    dsVeg = 10; %Divides array into 1/dsVeg small arrays
    Xv_sub = single(Xv(1:dsVeg:end)); 
    Yv_sub = single(Yv(1:dsVeg:end));
    Zv_sub = single(Zv(1:dsVeg:end));
    clear Xv Yv Zv;
    
    
    
    %% 5. Package all data into a Structured Container (`tileData`)
    fprintf('Packaging tile metadata and data structures...\n');
    tileData = struct();
    tileData.bounds = [xMin, xMax, yMin, yMax];
    tileData.gridStep = gridStep;
    tileData.EastingGrid = X_grid;
    tileData.NorthingGrid = Y_grid;
    tileData.ElevationGrid = Z_elevation;
    tileData.Veg.VegEasting = Xv_sub;
    tileData.Veg.VegNorthing = Yv_sub;
    tileData.Veg.VegElevation = Zv_sub;
    tileData.Signal_strength = []; % Reserved slot for your future signal survey data
    
    %% 6. Save to Disk using -v7.3 (HDF5 Binary Format)
    
    %6.a Define output file name based off of filename
    [~, baseFileName, ~] = fileparts(fileName);
    tileID = regexp(baseFileName, '\d+$', 'match'); 
    tileID = tileID{1}; % Converts cell array to string ('59172061')
    outputFileName = sprintf('tile_%s.mat', tileID);
    outputFileName = "./data/processed_lidar_tiles/" + outputFileName;
    
    %6.b Save 
    fprintf('Saving tile struct to %s...\n', outputFileName);
    save(outputFileName, 'tileData', '-v7.3');
    
    fprintf('Processing complete! Tile saved successfully.\n');
end