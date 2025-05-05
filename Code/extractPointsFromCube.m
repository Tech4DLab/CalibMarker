function pViewInPlane=extractPointsFromCube(ObjectsIn)

for nView = 1:size(ObjectsIn,2) %8
       % disp(['---View Processed number: ' num2str(nView)]);
        clear Obj
        X = ObjectsIn(nView).X;
        Y = ObjectsIn(nView).Y;
        Z = ObjectsIn(nView).Z;
        
              

        
     

            clear objMask objX objY objZ objN Planes map mapmask

   

            objX = X;
            objY = Y;
            objZ = Z;
           pViewInPlane{nView}=[objX' objY' objZ'];
        end
   
end