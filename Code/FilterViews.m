function validFramesFiltered=FilterViews(CubeBCenterAux,CubeNormalsAux,validFrames,snCams,method,ransacValues)
verbose=false;
T1 = [eye(3) [0 0 0]'; 0 0 0 1];
    % Filtrado de vistas con malos resultados: primero se eliminan los que
    % están fuera de distribución normal
    [CubeBCenter,CubeBNormals]=selectFrames(CubeBCenterAux,CubeNormalsAux,validFrames);
    if ransacValues.consideringNormals
        TR = mk_transform_cube(CubeBCenter,CubeBNormals,T1);
    else
        TR = mk_transform_ball(CubeBCenter,T1);   
    end
    
    [errorTotal,errorPerCam]=calculateAlignmentErrorCubeForViews(validFrames,CubeBCenterAux,CubeNormalsAux,TR,ransacValues.mode,method);
    meanV=mean(errorPerCam);
    medianV=mean(errorPerCam);
    desvV=std(errorPerCam);
    idCaminidsAll=sum((errorPerCam-medianV)>2*desvV,2)>2; % Si es mayor que 2 camaras
    if verbose
        disp(['Worst views: ',num2str(validFrames(idCaminidsAll))]);
    end
    medianC=median(medianV);
    desvC=std(medianV);
    checkCameras=abs(medianV-medianC)>desvC;
    if verbose
        disp(['Worst cameras (consider a intrisic calibration): ',num2str(find(checkCameras)),', id: ',snCams{checkCameras}]);
    end
    validFramesFiltered=validFrames(idCaminidsAll==0); % Solo los válidos

    [errorTotal,errorPerCam]=calculateAlignmentErrorCubeForViews(validFramesFiltered,CubeBCenterAux,CubeNormalsAux,TR,ransacValues.mode,method);
    meanV=mean(errorPerCam);
    medianV=mean(errorPerCam);
    desvV=std(errorPerCam);
    idCaminidsAll=sum((errorPerCam-medianV)>2*desvV,2)>2; % Si es mayor que 2 camaras
    if verbose
        disp(['Worst views after normal distribution: ',num2str(validFramesFiltered(idCaminidsAll))]);
    end
    medianC=median(medianV);
    desvC=std(medianV);
    % checkCameras=abs(medianV-meanC)>desvC;
    % disp(['Worst cameras (consider a intrisic calibration): ',num2str(find(checkCameras)),', id: ',snCams{checkCameras},', location: ',locationCams{checkCameras}]);
    validFramesFiltered=validFramesFiltered(idCaminidsAll==0); % Solo los válidos

end