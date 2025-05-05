% Select centroids and vertex points for a cube of edge X mm

function [pointList,normalList,bariCenter]=CalculatePointsInCube(ObjectsIn,edgeSize,goodViews)
plotting=false;
for nViewAux = 1:size(goodViews,2)
    
        idxP = goodViews(nViewAux);
    numPlanes=size((ObjectsIn(idxP).Objec{1}),2);
    if numPlanes<3
        bariCenter(:,idxP)=[0 0 0];
        pointList(:,1,idxP)=[0 0 0];
    else
        %% Intersection point
        pointsTotal=[];
        for nPP=1:numPlanes
            pInPlane=ObjectsIn(idxP).Objec{1}{nPP}.plane;
            pointsTotal=[pointsTotal;pInPlane];
            p(nPP,:)=mean(pInPlane);
            n(nPP,:)=ObjectsIn(idxP).Objec{1}{nPP}.nplane;
        end
        matDet=det([n(1,:)' n(2,:)' n(3,:)']);
        s1=dot(p(1,:)',n(1,:)')*cross(n(2,:)',n(3,:)');
        s2=dot(p(2,:)',n(2,:)')*cross(n(3,:)',n(1,:)');
        s3=dot(p(3,:)',n(3,:)')*cross(n(1,:)',n(2,:)');
        pInt=(1/matDet)*(s1+s2+s3);
        
        cent=mean(pointsTotal);
        % Normalize
        n(1,:)=n(1,:)/norm(n(1,:));
        n(2,:)=n(2,:)/norm(n(2,:));
        n(3,:)=n(3,:)/norm(n(3,:));
        if plotting==true
        figure;
        hold on;
        
        for nPP=1:numPlanes
            pInPlane=ObjectsIn(idxP).Objec{1}{nPP}.plane;
            pInPlaneCent{nPP}=pInPlane;%-cent; % Align to zero
            plot3(pInPlaneCent{nPP}(:,1),pInPlaneCent{nPP}(:,2),pInPlaneCent{nPP}(:,3),'b.');
            plot3(ObjectsIn(idxP).Objec{1}{nPP}.points(:,1),ObjectsIn(idxP).Objec{1}{nPP}.points(:,2),ObjectsIn(idxP).Objec{1}{nPP}.points(:,3),'r.');
        end   
        end
        % Calcular en el espacio 3D
        % pInt+d*n

        pointList(:,1,idxP)=pInt;
        pointList(:,2,idxP)=pInt-edgeSize*n(1,:)';
        pointList(:,3,idxP)=pInt-edgeSize*n(2,:)';
        pointList(:,4,idxP)=pInt-edgeSize*n(3,:)';
        pointList(:,5,idxP)=pointList(:,2,idxP)-edgeSize*n(2,:)';
        pointList(:,6,idxP)=pointList(:,2,idxP)-edgeSize*n(3,:)';
        pointList(:,7,idxP)=pointList(:,3,idxP)-edgeSize*n(3,:)';
        pointList(:,8,idxP)=pointList(:,7,idxP)-edgeSize*n(1,:)';
        
        normalList(:,1,idxP)=n(1,:)'; % Introducimos las normales para hacer el calculo
        normalList(:,2,idxP)=n(2,:)'; % Introducimos las normales para hacer el calculo
        normalList(:,3,idxP)=n(3,:)'; % Introducimos las normales para hacer el calculo
        normalList(:,4,idxP)=-n(1,:)'; % Introducimos las normales para hacer el calculo
        normalList(:,5,idxP)=-n(2,:)'; % Introducimos las normales para hacer el calculo
        normalList(:,6,idxP)=-n(3,:)'; % Introducimos las normales para hacer el calculo
        
        
        bariC=pInt-(edgeSize/2)*n(1,:)';
        bariC=bariC-(edgeSize/2)*n(2,:)';
        bariC=bariC-(edgeSize/2)*n(3,:)';
        
        bariCenter(:,idxP)=bariC;
        if plotting==true
        listPA=[1 1 1 2 2 3 3 4 4 5 6 7]; 
        listPB=[2 3 4 5 6 5 7 6 7 8 8 8];
        for i=1:size(listPA,2)
            line([pointList(1,listPA(i),idxP),pointList(1,listPB(i),idxP)],[pointList(2,listPA(i),idxP),pointList(2,listPB(i),idxP)],[pointList(3,listPA(i),idxP),pointList(3,listPB(i),idxP)]);
        end
        plot3(bariC(1),bariC(2),bariC(3),'r.','markersize',10);
        end
    end
end
end