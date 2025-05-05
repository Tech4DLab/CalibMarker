function pViewInPlane=extractPointsFromCubeperView(ObjectsIn,maskAreas,goodViews)
model=1;

for nViewAux = 1:size(goodViews,2)
       % disp(['---View Processed number: ' num2str(nView)]);
       
        nView = goodViews(nViewAux);
        clear Obj
        X = ObjectsIn(nView).X;
        Y = ObjectsIn(nView).Y;
        Z = ObjectsIn(nView).Z;
        
      
       

            clear objMask objX objY objZ objN Planes map mapmask
        nObj=1;
           

            objX = X;
            objY = Y;
            objZ = Z;
            idx=unique(maskAreas{nView});
            if idx(1)==0
                nTAreas=size(idx,2)-1;
            else
                 nTAreas=size(idx,2);
            end
            for narea=1:nTAreas
                pViewInPlane{nView}{narea}=[objX(maskAreas{nView}==narea)' objY(maskAreas{nView}==narea)' objZ(maskAreas{nView}==narea)'];
            end
        end
   
end