function [TR,bestFrames] = calibrate_withRansac(CubeBCenterAux,CubeNormalsAux,CubePointsAux,validFramesFiltered,InitFramesToProcess,framesToProcess,method,ransacValues,SegmentedPointsAuxUnits,nrow)

verbose = false;
mode=ransacValues.mode;
maxIterations=ransacValues.maxIterations;
numFramesToCalculateModel=ransacValues.numFramesToCalculateModel;
consideringNormals=ransacValues.consideringNormals;
threshold=ransacValues.threshold(nrow);
numberofInliers=ransacValues.numberofInliers;
if verbose
    disp(['numberofInliers: ', num2str(numberofInliers)]);
end
besterr = 100000;

T1 = [eye(3) [0 0 0]'; 0 0 0 1];
plotting=false;

if size(validFramesFiltered,2) == 3
    maybeinliers=validFramesFiltered;
    [CubeBCenter,CubeBNormals]=selectFrames(CubeBCenterAux,CubeNormalsAux,maybeinliers);
        if consideringNormals
            TR = mk_transform_cube(CubeBCenter,CubeBNormals,T1);
        else
            TR = mk_transform_ball(CubeBCenter,T1);   
        end
        bestFrames=validFramesFiltered;
else
for nIterations=1:maxIterations
    maskFrames=framesToProcess; % Only for frames with 3 planes
    
    idRand = randperm(size(validFramesFiltered,2),numFramesToCalculateModel);
    maybeinliers=validFramesFiltered(idRand);
    maskFrames(maybeinliers)=false;
    comprobeinliers = InitFramesToProcess(maskFrames);
    % Model calculated from maybeinliers
    if method == 0 % Baricenter
        [CubeBCenter,CubeBNormals]=selectFrames(CubeBCenterAux,CubeNormalsAux,maybeinliers);
        if consideringNormals
            TR = mk_transform_cube(CubeBCenter,CubeBNormals,T1);
        else
            TR = mk_transform_ball(CubeBCenter,T1);   
        end
        if plotting
            TransformandDrawCube(CubePointsAux,CubeNormalsAux,[1:8],maybeinliers(1),TR,SegmentedPointsAuxUnits);
        end
    else
        [CubePoints,CubeNormals]=selectFrames(CubePointsAux,CubeNormalsAux,maybeinliers);
        CBAll=MergePoints(CubePoints);
        if plotting
            DrawCube(CubePointsAux{1},maybeinliers,'red');
            DrawCube(CubePointsAux{2},maybeinliers,'blue');
            DrawCube(CubePointsAux{3},maybeinliers,'green');
            DrawCube(CubePointsAux{4},maybeinliers,'black');
        end
        TR = mk_transform_ball(CBAll,T1);
        if plotting
            [CBAllCorrected,PointsCorrected] = mk_applyTransform_calib(TR,CBAll,points,rgb);
            CubePoints=UnMergePoints(CBAllCorrected);
            DrawCube(CubePoints{1},[1:size(maybeinliers,2)],'red');
            DrawCube(CubePoints{2},[1:size(maybeinliers,2)],'blue');
            DrawCube(CubePoints{3},[1:size(maybeinliers,2)],'green');
            DrawCube(CubePoints{4},[1:size(maybeinliers,2)],'black');
        end
    end
    alsoinliers = [];
    for idFrame=1:size(comprobeinliers,2)
       
        if method == 0 % Baricenter
            [CubeBCenter,CubeBNormals]=selectFrames(CubeBCenterAux,CubeNormalsAux,comprobeinliers(idFrame));
            errorFrameRansac=calculateAlignmentErrorCube(CubeBCenter,CubeBNormals,TR,mode);
        else
            [CubePoints,CubeNormals]=selectFrames(CubePointsAux,CubeNormalsAux,comprobeinliers(idFrame));
            errorFrameRansac=calculateAlignmentErrorCube(CubePoints,CubeNormals,TR,mode);
        end
        if errorFrameRansac < threshold
             alsoinliers = [alsoinliers,comprobeinliers(idFrame)];
        end
    end
    if size(alsoinliers,2) >= numberofInliers
        % this implies that we may have found a good model
        % now test how good it is
      
        idsAllCalculated=[maybeinliers,alsoinliers];
        idsAll=validFramesFiltered;
        if ransacValues.errorAllViews==true
            idsUsed=idsAll;
        else
            idsUsed=idsAllCalculated;
        end
        if method == 0 % Baricenter
            [CubeBCenter,CubeBNormals]=selectFrames(CubeBCenterAux,CubeNormalsAux,idsAllCalculated);
            if consideringNormals
               betterTR = mk_transform_cube(CubeBCenter,CubeBNormals,T1);
            else
               betterTR = mk_transform_ball(CubeBCenter,T1);
            end
        else
            [CubePoints,CubeNormals]=selectFrames(CubePointsAux,CubeNormalsAux,idsAllCalculated);
            CBAll=MergePoints(CubePoints);
            betterTR = mk_transform_ball(CBAll,T1);
        end

        [errorTotal,errorPerCam]=calculateAlignmentErrorCubeForViews(idsUsed,CubeBCenterAux,CubeNormalsAux,betterTR,mode,method);
        %[errorTotal,errorPerCam]=calculateAlignmentErrorCubeForViews(idsAllCalculted,CubeBCenterAux,CubeNormalsAux,betterTR,mode,method);
        thiserr = mean(errorTotal); % Tiene en cuenta todas las camaras
        %[thiserr,idMax]=max(mean(errorPerCam)); % El mayor de los errores por camara
         if thiserr < besterr
            bestfit = betterTR;
            besterr = thiserr;
            bestFrames = idsAllCalculated;
%             if mode(1)==0
% %                 disp(['*Error transformation: ',num2str(thiserr),' mm']);
% %                 disp(['*Error per camera transformation: ',num2str(mean(errorPerCam)),' mm']);
% %                 [errorTotalAngle,errorPerCamAngles]=calculateAlignmentErrorCubeForViews(idsUsed,CubeBCenterAux,CubeNormalsAux,betterTR,1,method);
% %                 disp(['Error transformation: ',num2str(mean(errorTotalAngle)),' degrees']);
% %                 disp(['Error per camera transformation: ',num2str(mean(errorPerCamAngles)),' degrees']);
% %                 disp(['Best views: ',num2str(bestFrames)]);
%                 
%             elseif mode(1)==1
%                 disp(['*Error transformation: ',num2str(thiserr),' degrees']);
%                 disp(['*Error per camera transformation: ',num2str(mean(errorPerCam)),' degrees']);
%                 [errorTotalPoints,errorPerCamPoints]=calculateAlignmentErrorCubeForViews(idsUsed,CubeBCenterAux,CubeNormalsAux,betterTR,0,method);
%                 disp(['Error transformation: ',num2str(mean(errorTotalPoints)),' mm']);
%                 disp(['Error per camera transformation: ',num2str(mean(errorPerCamPoints)),' mm']);
%                 disp(['Best views: ',num2str(bestFrames)]);
%             elseif mode(1)==2
%                 disp(['Error per camera transformation: ',num2str(mean(errorPerCam)),' mm+degrees']);
%             end
            if plotting
                TransformandDrawCube(CubePointsAux,CubeNormalsAux,[1:2],[1:8],bestfit,SegmentedPointsAuxUnits);
            end
%             [~,idMax]=max(mean(errorPerCam));
%             meanV=mean(errorPerCam);
%             medianV=mean(errorPerCam);
%             desvV=std(errorPerCam);
%             idCaminidsAll=sum((errorPerCam-medianV)>desvV,2)>2; % Si es mayor que 2 camaras
%             disp(['Worst views (consider not taking into account): ',num2str(idsAll(idCaminidsAll))]);
%             medianC=median(medianV);
%             desvC=std(medianV);
%             checkCameras=abs(medianV-meanC)>desvC;
%             disp(['Worst cameras (consider a intrisic calibration): ',num2str(find(checkCameras)),', id: ',snCams{checkCameras},', location: ',locationCams{checkCameras}]);
        end
    end
end

% Final error
[errorTotal,errorPerCam]=calculateAlignmentErrorCubeForViews(idsAll,CubeBCenterAux,CubeNormalsAux,bestfit,0,method);
thiserr = mean(errorTotal);
disp(['Error transformation: ',num2str(thiserr),' mm']);
[errorTotalAngle,errorPerCamAngles]=calculateAlignmentErrorCubeForViews(idsAll,CubeBCenterAux,CubeNormalsAux,bestfit,1,method);
thiserr = mean(errorTotalAngle);
disp(['Error transformation: ',num2str(thiserr),' degrees']);
disp(['Best views (',num2str(size(bestFrames,2)),'): ',num2str(bestFrames)]);

 

TR=bestfit;
end
end