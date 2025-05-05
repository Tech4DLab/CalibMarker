function [NormalSpheresCorrected,PointsCorrected] = mk_applyTransform_calibNormal(TR,NormalSpheres)

PointsCorrected = nan;
% format TR for pctransform function
for nCam=1:size(TR,1)
    TR2{nCam} = TR{nCam};
    TR2{nCam}.T = [inv(TR{nCam}.T(1:3,1:3)) [0 0 0]' ; [TR{nCam}.T(1:3,4)' 1]];
    zP=zeros(size(NormalSpheres{nCam}));
    ptC=pointCloud(zP','Normal',NormalSpheres{nCam}');
    aux = pctransform(ptC,affine3d(TR2{nCam}.T));
    NormalSpheresCorrected{nCam} = aux.Normal';
end

end