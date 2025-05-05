%% Parameters for calibration
fileCubeEstimation="featureExtraction.mat";
load(fileCubeEstimation);

ransacValues.numFramesToCalculateModel = 3; %  5 n - the minimum number of data values required to fit the model
ransacValues.maxIterations             = 50; %500 %k - the maximum number of iterations allowed in the algorithm
ransacValues.thresholdAng              = [0.6,0.5,0.6,0.5]; %0.5 0.6 0.8 1.75; %degree % t - a threshold value for determining when a data point fits a model
ransacValues.thresholdDst              = [0.006,0.006,0.006,0.004]; %0.008 %m % t - a threshold value for determining when a data point fits a model

ransacValues.thresholdDstInterRows     = [0.002,0.002,0.009,0.01];
ransacValues.thresholdAngInterRows     = [0.3,0.3,0.6,0.6];
ransacValues.thresholdDstInterRows     = [0.06,0.06,0.01,0.01];
ransacValues.thresholdAngInterRows     = [0.6,0.6,0.6,0.6];

ransacValues.consideringNormals        = true;
ransacValues.thresholdViews            = [0.6,0.6,0.6,0.6]; 
ransacValues.thresholdViewsInterRows   = [0.6,0.5,0.5]; 
ransacValues.errorAllViews             = false;
ransacValues.filterViews               = true;
weight=[0.2,0.8];
ransacValues.mode=[2,weight(1)*1000,weight(2)]; % 0 distance 1 angle 2 weight
RowToRowAlignment=[1,1,2]; % Alignment pairs

[TRcombined, TRcombinedFine]=calculateCalibration(CubePointsAux,CubeBCenterAux,CubeNormalsAux,ObjectsAuxWithNormals,path,ransacValues,RowToPath,errorFrame,framesOK,camRows,capturedImages,magnitudePoints,SegmentedPointsAuxUnits,RowToRowAlignment);

TR=TRcombined;
disp(['Generating calibration file']);
generateCalibrationFile(['calibrationFile.cfg'],snCams,TR,path,factorFocal);

%TransformandDrawCube(CubePointsAux,CubeNormalsAux,[1:4],1,TR,SegmentedPointsAuxUnits);