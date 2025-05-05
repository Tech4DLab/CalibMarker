%%  GENERAL parameters

clear all;
addpath(genpath('./Include'));
pathBase='/media/deep/6FA9D9FE47CE4DC3/calibrado-alinua/c1510/';

warning('off');
path = {[pathBase,'R1H2'],[pathBase,'R3H2'],[pathBase,'R4H2'],[pathBase,'R34']};  
        
% % Cámaras por filas
camRows{1} = {'831612070293','829212071391','829212072264','728312070655'}; %TOP
camRows{2} = {'829212072262','815412070524','836612071402','848312070429'}; %TOP
camRows{3} = {'846112070086','728312070946','848312070416','848312070090'}; %DOWN

% Identify directory with camera rows (do not include inter-captures)
RowToPath{1}=[1];
RowToPath{2}=[2];
RowToPath{3}=[3];

% Alignment pairs (first row with first, second row with first, and third row with second)
RowToRowAlignment=[1,1,2]; 

angAllowedDif=2;
optimizationMethod=[6,2]; %,20}; % 10 relaxed constraints
filteringAlways=true; % Filtering always the clusters
percentageOutliers=0.2; 

if size(RowToPath,2) ~= size(camRows,2)
    disp("El tamaño de la variable camRows y RowToPath no coindiden")
else

% Number of images per directory
capturedImages=8;
scaleReg=0.25;
sizeEdge=250; %250 size of the marker in mm


% magnitude of the captures
magnitudePoints = 'm';
% Output path
pathFileCubeEstimation = '/home/deep/CalibMarker/Code/';
fileCubeEstimation=[pathFileCubeEstimation,'featureExtraction.mat'];

snCams=[];
for i=1:size(camRows,2)
    snCams = [snCams, camRows{i}];
end

factorFocal = Factores(false, snCams);


[CubePointsAux, CubeBCenterAux, CubeNormalsAux, SegmentedPointsAuxUnits,ObjectsAuxWithNormals,framesOK,errorFrame]=estimateCubesFromCaptures(path,camRows,capturedImages,magnitudePoints,scaleReg,sizeEdge,factorFocal,optimizationMethod,filteringAlways,percentageOutliers);
for nCam=1:size(ObjectsAuxWithNormals,2)
    disp(['Camera ',num2str(nCam),' found ',num2str(size(framesOK{nCam},2)),' of ',num2str(size(path,2)*capturedImages),' (',num2str(size(framesOK{nCam},2)/(size(path,2)*capturedImages)*100),' %) : ', num2str(framesOK{nCam})]);
end

save(fileCubeEstimation,'CubePointsAux','CubeBCenterAux','CubeNormalsAux','ObjectsAuxWithNormals','path','RowToPath','errorFrame','framesOK','camRows','capturedImages','magnitudePoints','snCams','SegmentedPointsAuxUnits','factorFocal','-v7.3');
end

