
function Tiles=samplingTiles(TilesData,scale,mode)
% Sampling the views to be processed
Tiles=TilesData;
numViews=size(TilesData,2);

for numTile=1:numViews
        % Resize the image
     
    resxGrid=nan(size(TilesData(numTile).mask));
    resyGrid=resxGrid;
    reszGrid=resxGrid;
   
    resBnd = zeros(size(TilesData(numTile).mask));
    resxGrid(TilesData(numTile).mask) =TilesData(numTile).X;
    resyGrid(TilesData(numTile).mask) =TilesData(numTile).Y;
    reszGrid(TilesData(numTile).mask) =TilesData(numTile).Z;
    
  	

    resmask = TilesData(numTile).mask;
    
    

    resimg=TilesData(numTile).img;
  
    resdepth=TilesData(numTile).depth;
  
   
        resxGrid = resize2dWithNans(resxGrid,scale,mode);
        resyGrid = resize2dWithNans(resyGrid,scale,mode);
        reszGrid = resize2dWithNans(reszGrid,scale,mode);
        
        
        % Resize the mask
        resmask=~isnan(resxGrid)&~isnan(resyGrid)&~isnan(reszGrid);
     
        
        resxGrid=single(resxGrid);
        resyGrid=single(resyGrid);
        reszGrid=single(reszGrid);
        
      
        
  
     Tiles(numTile).X=resxGrid(resmask)';   
     Tiles(numTile).Y=resyGrid(resmask)';
     Tiles(numTile).Z=reszGrid(resmask)';

    
   
    % Finally, the mask is stored
     Tiles(numTile).mask=resmask;
     
    
     B = bwboundaries(resmask,'noholes');
     bnd = cat(1,B{:});
       % numTile
       if size(bnd,1)==0
           indBnd=1;
       else
           indBnd = sub2ind(size(resmask),bnd(:,1),bnd(:,2));
       end
        indMask = int32(resmask(:));
        indMask(indMask == 0) = -1;
        indMask(indBnd) = 0;
        boundaries = ~(indMask(indMask>-1));
        bb = boundaries';
        resBnd = resmask;
        resBnd(resBnd == 1) = bb;
     resBnd=single(resBnd);

     Tiles(numTile).boundaries = logical(resBnd(resmask));
    rescolor = resize2dWithNans(TilesData(numTile).img,scale,mode);
     Tiles(numTile).color=rescolor;
      


end