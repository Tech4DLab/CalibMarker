function [CubePointsAux, CubeBCenterAux, CubeNormalsAux,SegmentedPointsAuxUnits,ObjectsAuxWithNormals,framesOK,errorFrame] = estimateCubesFromCaptures(path,camRows,capturedImages,magnitudePoints,scaleReg,sizeEdge,factorFocal,methods,filteringAlways,percentageOutliers)

FramesToProcessAux = 1:capturedImages;

numRows=size(camRows,2);
snCams =[];
for i=1:numRows
    snCams = [snCams, camRows{i}];
end
    
%% reading, segmentation and cube generation


    numCams = size(snCams,2);
    
    %% get the points, color image and depth image from the bag file using different directories
    points=cell(1,numCams);
    rgb=cell(1,numCams);
    depth=cell(1,numCams);
    for nfold=1:size(path,2)
         [pointsAux, rgbAux, depthAux] = getDataFromFiles(path{nfold}, snCams, numCams, FramesToProcessAux,factorFocal,true); %,FramesToProcess);
         for ncam=1:numCams
             points{ncam}=[points{ncam};pointsAux{ncam}];
             rgb{ncam}=[rgb{ncam};rgbAux{ncam}];
             depth{ncam}=[depth{ncam};depthAux{ncam}];
         end
            rgbAux=[];
            clear rgbAux
            pointsAux=[];
            clear pointsAux
            depthAux=[];
            clear depthAux
    end
    

    
    
    %% segment the data based on color information
    [SegmentedPointsAux, SegmentedRGBAux, SegmentedDepthAux, IndicesAux] = segmentationCubeCalibration(points, rgb, depth);
    
    clear points
    clear rgb
    clear depth
    
%% generate Objects data from RGB, Depth and Points
    if strcmp(magnitudePoints,'m') % if meters
        SegmentedPointsAux=transformUnits(SegmentedPointsAux,'mm','data');
    end
    
    ObjectsAux=generateObjectData(SegmentedPointsAux, SegmentedRGBAux, SegmentedDepthAux,IndicesAux);
 
    clear IndicesAux
    clear SegmentedRGBAux
    clear SegmentedDepthAux
    
     
    %% estimate the cube for each camera
    for nCam=1:size(ObjectsAux,2)
        disp('-----------------------------------------');
        disp(['Estimating the cubes presented in camera: ',num2str(nCam)]);
        
        ObjectsAux{nCam}=samplingTiles(ObjectsAux{nCam},scaleReg,'nearest');
        [CubePointsAuxM{nCam},CubeBCenterAuxM{nCam},CubeNormalsAux{nCam},framesOK{nCam},errorFrame{nCam},ObjectsAuxWithNormals{nCam}] = estimateCubeModel(ObjectsAux{nCam},sizeEdge,methods,filteringAlways,percentageOutliers);
        disp(['Error (mean,median,min,max): ',num2str(mean(errorFrame{nCam}(framesOK{nCam}))),' ', num2str(median(errorFrame{nCam}(framesOK{nCam}))),' ', num2str(min(errorFrame{nCam}(framesOK{nCam}))),' ', num2str(max(errorFrame{nCam}(framesOK{nCam})))]); 
        disp('-----------------------------------------');
        disp('')
    end
    
    
   if strcmp(magnitudePoints,'m') % if meters
        CubePointsAux=transformUnits(CubePointsAuxM,'m','model');
        CubeBCenterAux=transformUnits(CubeBCenterAuxM,'m','model');
        SegmentedPointsAuxUnits=transformUnits(SegmentedPointsAux,'m','data');
   end

    clear SegmentedPointsAux
    
end