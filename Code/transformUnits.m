 function PointsOut=transformUnits(PointsIn,units,output)
   if strcmp(output,'model')
       for nCam=1:size(PointsIn,2) % For each camera
             if strcmp(units,'mm') % m -> mm
                PointsOut{nCam}=PointsIn{nCam}.*1000;
             elseif strcmp(units,'m') % mm -> m
                PointsOut{nCam}=PointsIn{nCam}./1000;
             end
        end
       
   else
    for nCam=1:size(PointsIn,2) % For each camera
        for nFrame=1:size(PointsIn{nCam},2) % For each frame
             if strcmp(units,'mm') % m -> mm
                PointsOut{nCam}{nFrame}=PointsIn{nCam}{nFrame}.*1000;
             elseif strcmp(units,'m') % mm -> m
                PointsOut{nCam}{nFrame}=PointsIn{nCam}{nFrame}./1000;
             end
        end
    end
   end
             
 end
 
 