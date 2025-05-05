% Calculate the closest points to the plane
function [ObjectsOut,pViewOut,errorT,timeProcessing,idxClustersOut,percChange,errorLocation,errorNormal] = ClosestPlaneWithIds(ObjectsIn,NumPlanesTot,idxClusters,goodViews)


model=1;
idxClustersOut=idxClusters;
percChange=zeros(size(idxClusters));
pViewInPlane=extractPointsFromCube(ObjectsIn);

verbose = false;
plotting = false;
ObjectsOut = ObjectsIn;

for nViewAux = 1:size(goodViews,2)
    
    idxP = goodViews(nViewAux);
    if verbose
        disp(['------View ' num2str(idxP)]);
    end
    NumPlanes = NumPlanesTot(idxP);
    pViewOutTemp=cell(1,NumPlanes);
    errorTemp=0;
    errorTempLocation=0;
    errorTempNormals=0;
    numPoints=0;
    tCplane=tic;
    pIp=pViewInPlane{idxP};
    idxC=idxClusters{idxP};
    
    
    pointsInPlane=pIp(idxC~=0,:);
    % Recalcular normales
    X=pointsInPlane(:,1);
    Y=pointsInPlane(:,2);
    Z=pointsInPlane(:,3);
    Normals = normalCalculation([X Y Z]',min(13,size(X,1)-1));
    
    % Normalization of normal vectors
    VectorNormalization = zeros(3,length(Normals)) - [X Y Z]';
    for ii = 1:length(VectorNormalization)
        VectorNormalization(:,ii) = VectorNormalization(:,ii)/norm(VectorNormalization(:,ii));
    end
    Normals = normalsNormalization(Normals,VectorNormalization);
    if plotting
        hold off
        plot3(pointsInPlane(:,1),pointsInPlane(:,2),pointsInPlane(:,3),'c.')
        hold on
    end
    distance=[];
    distanceLocation=[];
    distanceNormals=[];
    for nPP=1:NumPlanes
        
        pInPlane=ObjectsIn(idxP).Objec{1}{nPP}.plane;
        cent=mean(pInPlane);
        normal=ObjectsIn(idxP).Objec{1}{nPP}.nplane;
        N=normal/norm(normal);
        N=N';
        N2 = N.'*N;
        P1=cent;
        pointReprojected=pointsInPlane*(eye(3)-N2)+repmat(P1*N2,size(pointsInPlane,1),1);
        if plotting
            plot3(pInPlane(:,1),pInPlane(:,2),pInPlane(:,3),'r.')
            plot3(cent(:,1),cent(:,2),cent(:,3),'b.','markersize',30)
            quiver3(cent(:,1),cent(:,2),cent(:,3),N(1),N(2),N(3),50);
            
            plot3(pointReprojected(:,1),pointReprojected(:,2),pointReprojected(:,3),'g.')
        end
        % Solo puntos
        % vectDistance=points-pointReprojected;
        % contando normales
        vectDistance=[pointsInPlane 2*Normals']-[pointReprojected 2*repmat(N,size(pointsInPlane,1),1)];
        % L-2 norm
        distance(:,nPP)=sqrt(diag(vectDistance*vectDistance')); % Distancia a cada uno de los plano
%         for nPoints=1:size(vectDistance,1)
%             distance(nPoints,nPP)=norm(vectDistance(nPoints,:));
%         end
       end
    [error,idx]=min(distance,'',2); %Distancia minima al plano idx contiene el plano minimo
 %   idxRws=[1:size(idx,1)]';
 %   idxT=sub2ind(size(distance),idxRws,idx);
    errorTemp=errorTemp+sum(error.^2);
  %  errorTempLocation=errorTempLocation+sum(distanceLocation(idxT).^2);
 %   errorTempNormals=errorTempNormals+sum(distanceNormals(idxT).^2);
    numPoints=numPoints+size(error,1);
    for nPP=1:NumPlanes
        pViewOutTemp{nPP}=[pViewOutTemp{nPP}; pointsInPlane(idx==nPP,:)];
    end
    idxClustersOut{idxP}(idxC~=0)=idx;
    
    percChange(idxP)=percChange(idxP)+(sum(idxClustersOut{idxP}~=idxClusters{idxP})/size(idxClusters{idxP},2))*100;
    
    timeCPlane=toc(tCplane);
    timeProcessing(idxP)=timeCPlane;
    errorT(idxP)=sqrt(errorTemp/numPoints); % RMS
    errorLocation(idxP)=0;sqrt(errorTempLocation/numPoints); % RMS
    errorNormal(idxP)=0;sqrt(errorTempNormals/numPoints); % RMS
    pViewOut{idxP}=pViewOutTemp;
    % ObjectsOut(idxP).Objec{1}{nPP}.plane
    % Calculate distance of points for each plane
end

end