function Objects=generateObjectData(SegmentedPoints, SegmentedRGB, SegmentedDepth, Indices)
    for nCam=1:size(SegmentedPoints,2) % For each camera
        for nFrame=1:size(SegmentedPoints{nCam},2) % For each frame
            
            Image = SegmentedRGB{nCam}(:,:,:,nFrame);
            Depth = SegmentedDepth{nCam}(:,:,nFrame);
            Points = SegmentedPoints{nCam}{nFrame};
            Object(nFrame).depth=Depth;
            Object(nFrame).img=Image;
            Object(nFrame).X=Points(:,1)'; % Pasamos a mm
            Object(nFrame).Y=Points(:,2)';
            Object(nFrame).Z=Points(:,3)';
            if size(Object(nFrame).X,2)==0
                disp(['Error en la lectura de im�genes, el frame ',num2str(nFrame),' de la camara ',num2str(nCam),' no existe']);
                %return 
            end
            Object(nFrame).mask=false(size(Depth));
            Object(nFrame).mask=Object(nFrame).mask;
            ind=Indices{nCam}{nFrame};
            Object(nFrame).mask(ind)=true;
           % Object(nFrame).mask=Object(nFrame).mask;
          %  Object(nFrame).mask(Depth>0)=Depth>0;
        end
        Objects{nCam}=Object;
        clear Object;
    end
end