% Modificado s�lo para baricentros
function [error,errorPerCam] = calculateAlignmentErrorCube(CheckingCube,NormalsIn,TR,modeInput)

mode=0; % Puntos
mode=1; % Planos
mode=2; % Punto+Planos

mode=modeInput(1);
plotting = false;

    points = CheckingCube;
    centers = CheckingCube;
    normals = NormalsIn;
    numCams = size(centers,2);
    
%     nCams=2;
%     figure
%     for nNormalsCam=1:6
%      quiver3(0,0,0,NormalsIn{nCams}(1,nNormalsCam),NormalsIn{nCams}(2,nNormalsCam),NormalsIn{nCams}(3,nNormalsCam))
%                     hold on
%     end
    [centersAligned] = mk_applyTransform_calib(TR,centers);
    [normalsAligned] = mk_applyTransform_calibNormal(TR,normals);
    
%     nCams=2;
%     figure
%     for nNormalsCam=1:6
%      quiver3(0,0,0,normalsAligned{nCams}(1,nNormalsCam),normalsAligned{nCams}(2,nNormalsCam),normalsAligned{nCams}(3,nNormalsCam))
%                     hold on
%     end
    
    error=0;
    
    switch mode
        case 0
            for nCams=1:size(centersAligned,2)
                % Calcular desde un punto a todos
                [~,errorCam(:,nCams)]=knnsearch(centersAligned{nCams}',cell2mat(centersAligned)');
            end
            error=mean(sum(errorCam))/(size(centersAligned,2));
            errorPerCam=sum(errorCam)/size(centersAligned,2);
        case 1
            errorCam=zeros(size(normalsAligned,2),size(normalsAligned,2));
            for nCams=1:size(normalsAligned,2)
                for nNormalsCam=1:size(normalsAligned,2)
                    % Calcular desde un punto a todos
                    if nCams ~= nNormalsCam
                        errorCam(nCams,nNormalsCam)=calculateErrorAngles(normalsAligned,nCams,nNormalsCam);
                    end
                end
            end
            error=mean(sum(errorCam)/size(centersAligned,2));
            errorPerCam=sum(errorCam)/size(centersAligned,2);
          case 2
               for nCams=1:size(centersAligned,2)
                % Calcular desde un punto a todos
                [~,errorCamDist(:,nCams)]=knnsearch(centersAligned{nCams}',cell2mat(centersAligned)');
            end
            errorDist=mean(sum(errorCamDist))/(size(centersAligned,2));
       
            errorCam=zeros(size(normalsAligned,2),size(normalsAligned,2));
            for nCams=1:size(normalsAligned,2)
                for nNormalsCam=1:size(normalsAligned,2)
                    % Calcular desde un punto a todos
                    if nCams ~= nNormalsCam
                        errorCam(nCams,nNormalsCam)=calculateErrorAngles(normalsAligned,nCams,nNormalsCam);
                    end
                end
            end
            errorAngle=mean(sum(errorCam)/size(centersAligned,2));
            error = modeInput(2)*errorDist + modeInput(3)*errorAngle;
            errorPerCam=modeInput(2)*(sum(errorCamDist)/size(centersAligned,2))+modeInput(3)*(sum(errorCam)/size(centersAligned,2));
    end
            
end

function error=calculateErrorAngles(normalsAligned,nCams,nNormalsCam)

    for nNormalsCamOne=1:6
        for nNormalsCamTwo=1:6
            ang=acos(dot(normalsAligned{nCams}(:,nNormalsCamOne)',normalsAligned{nNormalsCam}(:,nNormalsCamTwo)'))*180/pi;
            if imag(ang)>0
                ang=real(ang);
            end
            angleError(nNormalsCamOne,nNormalsCamTwo)=ang;
        end
    end
    [errorind,ids]=min(angleError);
    error=sum(errorind)/6;
    if sum(abs(sort(ids)-[1:6]))>10
        % disp("ERROR en el calculo del error.................");
        error=100000000; % Comprobar que sea correcto
    end
end