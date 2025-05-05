function [CentresSphereCorrected,PointsCorrected] = mk_applyTransform_calib(TR,CentreSpheres, points, rgb,normals)

PointsCorrected = nan;
% format TR for pctransform function
for nCam=1:size(TR,1)
    TR2{nCam} = TR{nCam};
    TR2{nCam}.T = [inv(TR{nCam}.T(1:3,1:3)) [0 0 0]' ; [TR{nCam}.T(1:3,4)' 1]];
    if size(CentreSpheres,2)==0
        CentresSphereCorrected=[];
    else
        aux = pctransform(pointCloud(CentreSpheres{nCam}'),affine3d(TR2{nCam}.T));
        CentresSphereCorrected{nCam} = aux.Location';
    end
end
if nargin > 4
      clear PointsCorrected;
    % apply data for visualization
    for nCam=1:size(TR,1) 
        for ftp=1:size(points{1},1)
            ccAux = rgb{nCam}{ftp}.readImage; % to provide color to the points
%         ccAux2(:,:,1) = ccAux(:,:,1)';
%         ccAux2(:,:,2) = ccAux(:,:,2)';
%         ccAux2(:,:,3) = ccAux(:,:,3)';
        ccAux2=ccAux;
        PointsCorrected{nCam}{ftp,1} = pctransform(pointCloud(points{nCam}{ftp}.readXYZ,'Normal',normals{nCam}{ftp}, 'Color',  reshape(ccAux2,points{nCam}{ftp}.Width*points{nCam}{ftp}.Height,3)),affine3d(TR2{nCam}.T));
        end
    end
elseif nargin > 3
    clear PointsCorrected;
    % apply data for visualization
    for nCam=1:size(TR,1) 
        for ftp=1:size(points{1},1)
            ccAux = rgb{nCam}{ftp}.readImage; % to provide color to the points
%         ccAux2(:,:,1) = ccAux(:,:,1)';
%         ccAux2(:,:,2) = ccAux(:,:,2)';
%         ccAux2(:,:,3) = ccAux(:,:,3)';
        ccAux2=ccAux;
        PointsCorrected{nCam}{ftp,1} = pctransform(pointCloud(points{nCam}{ftp}.readXYZ, 'Color',  reshape(ccAux2,points{nCam}{ftp}.Width*points{nCam}{ftp}.Height,3)),affine3d(TR2{nCam}.T));
        end
    end
elseif nargin > 2
    clear PointsCorrected;
    for nCam=1:size(TR,1)
        PointsCorrected{nCam}  = pctransform(pointCloud(points{nCam}{1}.readXYZ),affine3d(TR2{nCam}.T));
    end
end


end