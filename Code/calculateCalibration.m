function [TRcombined, TRcombinedFine] = calculateCalibration(CubePointsAux,CubeBCenterAux,CubeNormalsAux,ObjectsAuxWithNormals,path,ransacValues,RowToPath,errorFrame,framesOK,camRows,capturedImages,magnitudePoints,SegmentedPointsAuxUnits,RowToRowAlignment)
framesOKOriginal=framesOK;
verbose=true;
numRows=size(camRows,2);
snCams =[];
for i=1:numRows
    snCams = [snCams, camRows{i}];
    numCamsRow(i) = size(camRows{i},2);
    prevCam=0;
    if i==1
        idCameras{i} = [1:size(camRows{i},2)];
    else       
        for j=1:i-1
            prevCam=prevCam+size(camRows{j},2);
        end
        idCameras{i} = [1:size(camRows{i},2)]+prevCam;
    end
end

% Other parameters
InitFramesToProcess=[1:capturedImages*size(path,2)];
for i=1:numRows
    init=zeros(size(InitFramesToProcess));
    for j=1:size(RowToPath{i},2)
        iniind=(RowToPath{i}(j)-1)*capturedImages+1;
        endind=RowToPath{i}(j)*capturedImages;
        init(iniind:endind)=1;
    end
    initialCalib{i}=init;
end

% Modificar por Row
if ransacValues.filterViews==true
for nrows=1:numRows    
    errorframeMat=cell2mat(errorFrame');
    errorframeMat(errorframeMat==0)= nan;

    for nCam=1:numCamsRow(nrows)
    idCam=idCameras{nrows}(nCam);
    errorCam=nanmedian(errorframeMat(:,logical(initialCalib{nrows})),2);
    errorstdCam=nanstd(errorframeMat(:,logical(initialCalib{nrows})),'',2);
    %errorstdCam(:,1) = 100000;    %%%%%%QUITAR%%%%
    frameOKperMat=abs(errorCam-errorframeMat)<2*errorstdCam;
    framesperMat=[1:size(frameOKperMat,2)];
    
        framesOk2{idCam}=framesperMat(frameOKperMat(idCam,:));
    
    end
end
    framesOK=framesOk2;
end


fineAlignment=false;
% framesToProcess=sum(frameids,1)>numCams*0.5;

method=0; % 0: baricenter 1:all intersection points + baricenter

%/ransacValues.thresholdDst,weight(2)/ransacValues.thresholdAng]; % Adaptamos pesos
if ransacValues.mode(1)==0
    ransacValues.threshold=ransacValues.thresholdDst;%(mode(2)*thresholdDst) + (mode(3)*thresholdAng);
elseif ransacValues.mode(1)==1
    ransacValues.threshold=ransacValues.thresholdAng;%(mode(2)*thresholdDst) + (mode(3)*thresholdAng);
else
    ransacValues.threshold=(ransacValues.mode(2)*ransacValues.thresholdDst) + (ransacValues.mode(3)*ransacValues.thresholdAng);
end


disp('Calculating transformations using RANSAC');
T1 = [eye(3) [0 0 0]'; 0 0 0 1];
bestfit=[];
numRows=size(numCamsRow,2);
% Valid per Rows and Valid InterRows
for nrows=1:numRows
    frameidsRows{nrows}=zeros(numCamsRow(nrows),size(InitFramesToProcess,2));
    frameidsRowsGlobal{nrows}=zeros(numCamsRow(nrows),size(InitFramesToProcess,2));
    for nCam=1:numCamsRow(nrows)
        idCam=idCameras{nrows}(nCam);
        idsValid=abs(errorFrame{idCam}-median(errorFrame{idCam}))<10*std(errorFrame{idCam}); % Comprobando el error
        frameidsRows{nrows}(nCam,framesOK{idCam})=1;
        frameidsRows{nrows}(nCam,:) = frameidsRows{nrows}(nCam,:) & idsValid;
        frameidsRowsGlobal{nrows}(nCam,framesOKOriginal{idCam})=1;
        frameidsRowsGlobal{nrows}(nCam,:) = frameidsRowsGlobal{nrows}(nCam,:) & idsValid;
    end
    
    framesToProcessRowsGlobal(nrows,:)=sum(frameidsRows{nrows},1)==numCamsRow(nrows);
    validFramesRowsGlobal{nrows}=InitFramesToProcess(framesToProcessRowsGlobal(nrows,:));
    framesToProcessRows(nrows,:)=framesToProcessRowsGlobal(nrows,:) & initialCalib{nrows};
    validFramesRows{nrows}=InitFramesToProcess(framesToProcessRows(nrows,:));
end

%thresholdViews=0.25;
for nrows=1:numRows
    disp(['Calibrating row: ',num2str(nrows)]);
    disp('--------------------');
    TRRow{nrows}{1}.T= [eye(3) [0 0 0]'; 0 0 0 1];
    TRRow{nrows}{1}.s= [eye(3) [0 0 0]'; 0 0 0 1];
    TRRow{nrows}{1}.c= 'cam1';
    for ncamsPerRow=2:size(idCameras{nrows},2)
        idCamsT=idCameras{nrows};
        idCams(1)=idCamsT(1);
        idCams(2)=idCamsT(ncamsPerRow);
        framesToProcess=frameidsRows{nrows}(1,:)&frameidsRows{nrows}(ncamsPerRow,:)& initialCalib{nrows};
        validFrames=InitFramesToProcess(framesToProcess);
    
        validFramesFiltered=FilterViews(CubeBCenterAux(idCams),CubeNormalsAux(idCams),validFrames,snCams,method,ransacValues);
        if verbose
            disp(['Using ',num2str(size(validFramesFiltered,2)),' of ',num2str(size(RowToPath{nrows},2)*capturedImages),': ', num2str(validFramesFiltered)]);
        end
        ransacValues.numberofInliers = floor(ransacValues.thresholdViews(nrows)*sum(framesToProcessRows(nrows,:)));
        [TRRowtemp,bestFramesCaminRow] = calibrate_withRansac(CubeBCenterAux(idCams),CubeNormalsAux(idCams),CubePointsAux(idCams),validFramesFiltered,InitFramesToProcess,framesToProcess,method,ransacValues,SegmentedPointsAuxUnits(idCams),nrows);
        TRRow{nrows}{1}=TRRowtemp{1};
        TRRow{nrows}{ncamsPerRow}=TRRowtemp{2};
        if verbose
            disp(['Best views cam: ',num2str(ncamsPerRow),' in row: ',num2str(nrows),' ',num2str(bestFramesCaminRow)]);
        end
        if fineAlignment && size(idCams,2)==4
            TRRowFinetemp = calibrate_withICP(CubeBCenterAux(idCams),CubeNormalsAux(idCams),ObjectsAuxWithNormals(idCams),TRRow{nrows},bestFramesCaminRow,method,magnitudePoints);
        else
            TRRowFinetemp =TRRow{nrows};
        end
        TRRowFine{nrows}{1}=TRRowFinetemp{1};
        TRRowFine{nrows}{ncamsPerRow}=TRRowFinetemp{2};
    end
end
%% Calculating rows togheter

 disp('Calibrating rows togheter.....');
 disp('-------------------------------');
 %thresholdViews=0.25;
 
 for nrows=2:numRows
     disp(['Calibrating row ', num2str(nrows),' with: ',num2str(RowToRowAlignment(nrows))]);
     disp('-------------------------------');
     %framesToProcess=sum([framesToProcessRowsGlobal(1,:);framesToProcessRowsGlobal(nrows,:)])==2; % De 2 en 2
     
     framesToProcess=frameidsRowsGlobal{RowToRowAlignment(nrows)}(1,:)&frameidsRowsGlobal{nrows}(1,:);
     validFrames=InitFramesToProcess(framesToProcess);
     idCams=[];
     idCams(1)=idCameras{RowToRowAlignment(nrows)}(1); % Las primeras
     idCams(2)=idCameras{nrows}(1); % Las primeras
     validFramesFiltered=FilterViews(CubeBCenterAux(idCams),CubeNormalsAux(idCams),validFrames,snCams,method,ransacValues);
     disp(['Using ',num2str(size(validFramesFiltered,2)),' of ',num2str(size(path,2)*capturedImages),': ', num2str(validFramesFiltered)]);
     ransacValues.numberofInliers = floor(ransacValues.thresholdViewsInterRows(nrows-1)*sum(framesToProcess));
     
     if ransacValues.mode(1)==0
         ransacValues.threshold=ransacValues.thresholdDstInterRows;%(mode(2)*thresholdDst) + (mode(3)*thresholdAng);
    elseif ransacValues.mode(1)==1
        ransacValues.threshold=ransacValues.thresholdAngInterRows;%(mode(2)*thresholdDst) + (mode(3)*thresholdAng);
     else
        ransacValues.threshold=(ransacValues.mode(2)*ransacValues.thresholdDstInterRows) + (ransacValues.mode(3)*ransacValues.thresholdAngInterRows);
    end
   
     [TRTtmp,bestFrames]=calibrate_withRansac(CubeBCenterAux(idCams),CubeNormalsAux(idCams),CubePointsAux(idCams),validFramesFiltered,InitFramesToProcess,framesToProcess,method,ransacValues,SegmentedPointsAuxUnits(idCams),nrows-1);           
     if verbose
         disp(['Best views: ',num2str(bestFrames)]);
     end
     if fineAlignment
        TRTFinetmp = calibrate_withICP(CubeBCenterAux(idCams),CubeNormalsAux(idCams),ObjectsAuxWithNormals(idCams),TRTtmp,bestFrames,method,magnitudePoints);
     end
     if nrows==2 % Primera
         TRT=TRTtmp;
         if fineAlignment
             TRTFine=TRTFinetmp;
         end
     else
         TRT{nrows,1}=TRTtmp{2,1};
         if fineAlignment
             TRTFine{nrows,1}=TRTFinetmp{2,1};
         end
     end
 end
 
 if numRows==1
     TRT{1}=TRRow{1}{1};
     if fineAlignment
        TRTFine{1} = TRRowFine{1}{1};
     end
 end
 
 % Apply to the rows w.r.t row 1
 for nrows=1:numRows
     for nCam=1:size(idCameras{nrows},2)
         idCam=idCameras{nrows}(nCam);
         TRcombined{idCam,1}.T=TRT{RowToRowAlignment(nrows)}.T*TRT{nrows}.T*TRRow{nrows}{nCam}.T;
         TRcombined{idCam,1}.s=TRT{RowToRowAlignment(nrows)}.s*TRT{nrows}.s*TRRow{nrows}{nCam}.s;
         TRcombined{idCam,1}.c=['cam1<-','cam',num2str(idCam)];
     end
 end
 
 
 if fineAlignment
 % Apply to the rows w.r.t row 1
     for nrows=1:numRows
         for nCam=1:size(idCameras{nrows},2)
             idCam=idCameras{nrows}(nCam);
             TRcombinedFine{idCam,1}.T=TRTFine{RowToRowAlignment(nrows)}.T*TRTFine{nrows,1}.T*TRRowFine{nrows}{nCam}.T;
             TRcombinedFine{idCam,1}.s=TRTFine{RowToRowAlignment(nrows)}.s*TRTFine{nrows,1}.s*TRRowFine{nrows}{nCam}.s;
             TRcombinedFine{idCam,1}.c=['cam1<-','cam',num2str(idCam)];
         end
     end
 else
     TRcombinedFine=[];
 end
 
