function [PointsOut, RGBOut, DepthOut]=filterPoints(PointsIn, RGBIn, DepthIn)
thresDist=1200;    
RGBOut=RGBIn;
    for nCam=1:size(PointsIn,2) % For each camera
        for nFrame=1:size(PointsIn{nCam},1) % For each frame
            
            Image = RGBIn{nCam}{nFrame};
            ImAux = Image.readImage;
            ImAuxR = ImAux(:,:,1);
            ImAuxG = ImAux(:,:,2);
            ImAuxB = ImAux(:,:,3);
            
            
            Depth = DepthIn{nCam}{nFrame};
             DepthAux = Depth.readImage;
            Points = PointsIn{nCam}{nFrame};
            Object(nFrame).depth=DepthAux;
            Object(nFrame).img=ImAux;
            PointsAux = Points.readXYZ;
           
            Object(nFrame).mask=false(size(DepthAux));
            Object(nFrame).mask=Object(nFrame).mask;
           % ind=Indices{nCam}{nFrame};
           % Object(nFrame).mask(ind)=true;
          %  Object(nFrame).mask=Object(nFrame).mask;
            Object(nFrame).mask(DepthAux>0 & DepthAux<thresDist)=true;
             Mask=Object(nFrame).mask;
             
             ColorFilteredR = uint8(nan(size(ImAuxR)));
             DepthOut{1,nCam}{nFrame,1}=nan(size(ImAuxR));
            
             ColorFilteredG = ColorFilteredR;
             ColorFilteredB = ColorFilteredR;
             ColorFiltered = zeros(size(ImAux));
             ColorFilteredR(Mask) = uint8(ImAuxR(Mask));
             ColorFilteredG(Mask) =  uint8(ImAuxG(Mask));
             ColorFilteredB(Mask) =  uint8(ImAuxB(Mask));
            %  DepthOut(Mask)=DepthAux(Mask);
              DepthOut{1,nCam}{nFrame,1}(Mask)=DepthAux(Mask);
             ColorFiltered(:,:,1)= uint8(ColorFilteredR);
             ColorFiltered(:,:,2)= uint8(ColorFilteredG);
             ColorFiltered(:,:,3)= uint8(ColorFilteredB);
             
             %se = strel('disk',5);
             %erodedI = imerode(Mask,se);
             %Mask=erodedI;
             Object(nFrame).mask=Mask;
            ind = (Mask==0);
            PointsAux(ind,1)=NaN; % Pasamos a mm
            PointsAux(ind,2)=NaN;
            PointsAux(ind,3)=NaN;
            PointsOut{1,nCam}{nFrame,1} = MyPointCloudClass(PointsAux, size(ImAux,2), size(ImAux,1));
              
                
            
         end
       
           
    end
end