function normalNew = normalsNormalization(normals,normOrig)
    
    if size(normals,1) ~= 3
        error('Normals size in normalsNormalization should be 3xN.');
    end
    Nx = normals(1,:);
    Ny = normals(2,:);
    Nz = normals(3,:);
    
   
        
    
    if nargin == 1 
        normOrig = [0,0,-1]; 
        norigen = sqrt( repmat(normOrig(1),size(Nx,2),1).^2 + repmat(normOrig(2),size(Ny,2),1).^2 + repmat(normOrig(3),size(Nz,2),1).^2 );
    else
         dim = size(normOrig);
    dimOK = find(dim ==3);
    if dimOK ~= 1
        normOrig = normOrig';
    end
        if size(normOrig,2) > size(normOrig,1)
            norigen = sqrt(normOrig(1,:).^2 + normOrig(2,:).^2 + normOrig(3,:).^2)';
        else
            norigen = sqrt( repmat(normOrig(1),size(Nx,2),1).^2 + repmat(normOrig(2),size(Ny,2),1).^2 + repmat(normOrig(3),size(Nz,2),1).^2 );
        end
    end
    
    normales = sqrt( Nx(:).^2 + Ny(:).^2 + Nz(:).^2 );
    nOrigNormales=norigen.*normales;
    
    if nargin > 1 & length(normOrig) > 3
        nOrigenNormales=ceil(acos(dot( [ Nx(:) Ny(:) Nz(:)]' , normOrig)' ./nOrigNormales)*180/pi);
    else
        nOrigenNormales=ceil(acos(dot( [ Nx(:) Ny(:) Nz(:)]' , [repmat(normOrig(1),size(Nx,2),1), repmat(normOrig(2),size(Ny,2),1), repmat(normOrig(3),size(Nz,2),1)]')' ./nOrigNormales)*180/pi);
    end
    
    idxAngle = find(nOrigenNormales > 90);
    Nx(idxAngle) = -Nx(idxAngle);
    Ny(idxAngle) = -Ny(idxAngle);
    Nz(idxAngle) = -Nz(idxAngle);
    
    normalNew = normals;
    normalNew(1,:) = Nx;
    normalNew(2,:) = Ny;
    normalNew(3,:) = Nz;
end
