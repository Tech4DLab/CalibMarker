function [PointsOut,NormalsOut]=selectFrames(PointsIn,NormalsIn,ids)
for nCam=1:size(PointsIn,2)
    if ndims(PointsIn{nCam})==2
      PointsOut{nCam}=PointsIn{nCam}(:,ids);
      NormalsOut{nCam}=NormalsIn{nCam}(:,:,ids);
    else
       PointsOut{nCam}=PointsIn{nCam}(:,:,ids);
       NormalsOut{nCam}=NormalsIn{nCam}(:,:,ids);
    end
end
end