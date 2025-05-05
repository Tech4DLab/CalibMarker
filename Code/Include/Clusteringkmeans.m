function [idxClusters, idxClustersJoined , Solution,idxModPl, idxInAngle, clusterNormals, clusterCentro] = Clusteringkmeans(points, normals,numFaces,angle,VectorNormalization)
%% Clustering with kmeans
    numClust = numFaces;
    minSizeNPoints = 30;
    Solution = [];
    plotting = 0;
    X = points(1,:);
    Y = points(2,:);
    Z = points(3,:);
    Nx = normals(1,:);
    Ny = normals(2,:);
    Nz = normals(3,:);
%     X2 = X./sum(abs(X));
%     Y2 = Y./sum(abs(Y));
%     Z2 = Z./sum(abs(Z));
    scale = max([(max(X) - min(X)) (max(Y) - min(Y)) (max(Z) - min(Z))]);
%     X2 = (X-min(X))/scale;
%     Y2 = (Y-min(Y))/scale;
%     Z2 = (Z-min(Z))/scale;
    X2 = (X)/scale;
    Y2 = (Y)/scale;
    Z2 = (Z)/scale;

    [idxClusters,C,sumPrueba,D]=kmeans([Nx.*1.5;Ny.*1.5;Nz.*1.5;X2;Y2;Z2]',numClust,'Replicates',10,'EmptyAction','drop','start','uniform');%,'distance','cityblock');

    %  [idxClusters,C,sumPrueba,D]=kmeans([Nx;Ny;Nz;X2;Y2;Z2]',numClust,'Replicates',10,'EmptyAction','drop');
    idxUnique = unique(idxClusters);
    for ii=1:length(idxUnique)
       numPointsPerCluster(ii) = sum(idxClusters==ii);
    end
    minSizeNPoints = min(minSizeNPoints,mean(numPointsPerCluster));
    idxUnderMin = find(numPointsPerCluster < minSizeNPoints);
    idxClusters(ismember(idxClusters,idxUnderMin)) = 0;
    
    idxInAngle = zeros(1,size(idxClusters,1));
    
    numClust = length(uunique(idxClusters));
    
    % k clusters
    for i = 1:numClust
        cen(1,i) = mean(X(idxClusters==i));
        cen(2,i) = mean(Y(idxClusters==i));
        cen(3,i) = mean(Z(idxClusters==i));

        cnor(1,i) = median(Nx(idxClusters==i));
        cnor(2,i) = median(Ny(idxClusters==i));
        cnor(3,i) = median(Nz(idxClusters==i)); 

        % Angle between normals and their median
        n = sqrt( repmat(cnor(1,i),1,size(Nx(idxClusters==i),2)).^2 + repmat(cnor(2,i),1,size(Nx(idxClusters==i),2)).^2 + repmat(cnor(3,i),1,size(Nx(idxClusters==i),2)).^2 );
        normAux = sqrt( Nx(idxClusters==i).^2 + Ny(idxClusters==i).^2 + Nz(idxClusters==i).^2 );
        normas=n.*normAux;
        angleNMed{i} = ceil(acos(dot([Nx(idxClusters==i);Ny(idxClusters==i);Nz(idxClusters==i)] , [repmat(cnor(1,i),1,size(Nx(idxClusters==i),2));repmat(cnor(2,i),1,size(Ny(idxClusters==i),2));repmat(cnor(3,i),1,size(Nz(idxClusters==i),2))]) ./normas)*180/pi);

        medAngleNMed = mean(angleNMed{i});
        stdAngleNMed = std(angleNMed{i});

        idxInAngle(idxClusters == i) = angleNMed{i} < medAngleNMed + stdAngleNMed & angleNMed{i} > medAngleNMed - stdAngleNMed;
    end
    if nargin < 7
        VectorNormalization = zeros(3,size(cen,2)) - cen;
        for ii = 1:size(VectorNormalization,2)
            VectorNormalization(:,ii) = VectorNormalization(:,ii)/norm(VectorNormalization(:,ii));
        end
    end
    cnor = normalsNormalization(cnor,VectorNormalization);
    
    if plotting
        figure('Name','Before Joining KMeans');
            hold on
            plot3(X(idxClusters==1),Y(idxClusters==1),Z(idxClusters==1),'.b','markersize',0.1);
            plot3(X(idxClusters==2),Y(idxClusters==2),Z(idxClusters==2),'.g','markersize',0.1);
            plot3(X(idxClusters==3),Y(idxClusters==3),Z(idxClusters==3),'.m','markersize',0.1);
%             plot3(X(idxClusters==4),Y(idxClusters==4),Z(idxClusters==4),'.r','markersize',0.1);
%             plot3(X(idxClusters==5),Y(idxClusters==5),Z(idxClusters==5),'.k','markersize',0.1);
%             plot3(X(idxClusters==6),Y(idxClusters==6),Z(idxClusters==6),'.y','markersize',0.1);
            plot3(cen(1,1),cen(2,1),cen(3,1),'ob');
            plot3(cen(1,2),cen(2,2),cen(3,2),'og');
            plot3(cen(1,3),cen(2,3),cen(3,3),'om');
%             plot3(cen(1,4),cen(2,4),cen(3,4),'or');
%             plot3(cen(1,5),cen(2,5),cen(3,5),'ok');
%             plot3(cen(1,6),cen(2,6),cen(3,6),'oy');
            m=1;quiver3(cen(1,m),cen(2,m),cen(3,m),cnor(1,m)*10,cnor(2,m)*10,cnor(3,m)*10);
            m=2;quiver3(cen(1,m),cen(2,m),cen(3,m),cnor(1,m)*10,cnor(2,m)*10,cnor(3,m)*10);
            m=3;quiver3(cen(1,m),cen(2,m),cen(3,m),cnor(1,m)*10,cnor(2,m)*10,cnor(3,m)*10);
%             m=4;quiver3(cen(1,m),cen(2,m),cen(3,m),cnor(1,m)*10,cnor(2,m)*10,cnor(3,m)*10);
%             m=5;quiver3(cen(1,m),cen(2,m),cen(3,m),cnor(1,m)*10,cnor(2,m)*10,cnor(3,m)*10);
%             m=6;quiver3(cen(1,m),cen(2,m),cen(3,m),cnor(1,m)*10,cnor(2,m)*10,cnor(3,m)*10);

            axis image
    end
        
    % Index of accepted normals or points
    idxInAngle = logical(idxInAngle)';
    
    % Join clusters
    idxClustersJoined = idxClusters;
    fndOut = 0;
    contOut = 1;
    
    idxs = unique(idxClustersJoined);    
    idxs = uunique(idxClustersJoined)';
    idxs = idxs(idxs ~= 0);
    for i=1:size(idxs)
        clusterCentro(1,i) = median(X(idxClustersJoined == idxs(i)));
        clusterCentro(2,i) = median(Y(idxClustersJoined == idxs(i)));
        clusterCentro(3,i) = median(Z(idxClustersJoined == idxs(i)));
        
        clusterNormals(1,i) = median(Nx(idxClustersJoined == idxs(i)));
        clusterNormals(2,i) = median(Ny(idxClustersJoined == idxs(i)));
        clusterNormals(3,i) = median(Nz(idxClustersJoined == idxs(i)));
    end
  
    for mat = 1:size(clusterNormals,2);
        n1 = sqrt( repmat(clusterNormals(1,mat),1,size(clusterNormals,2)).^2 + repmat(clusterNormals(2,mat),1,size(clusterNormals,2)).^2 + repmat(clusterNormals(3,mat),1,size(clusterNormals,2)).^2 );
        n2 = sqrt( clusterNormals(1,:).^2 + clusterNormals(2,:).^2 + clusterNormals(3,:).^2 );
        norma=n1.*n2;
        ang2=ceil(acos(roundn(dot([clusterNormals(1,:);clusterNormals(2,:);clusterNormals(3,:)] , [repmat(clusterNormals(1,mat),1,size(clusterNormals,2));repmat(clusterNormals(2,mat),1,size(clusterNormals,2));repmat(clusterNormals(3,mat),1,size(clusterNormals,2))]) ./norma,-8))*180/pi);
        angleMatPost(mat,:) = ang2;
    end
    angleMatAux = angleMatPost;
    PossibleSolutions = evaluatePlanes(angleMatPost,angle);

    MaxPoints = 0;
    Candidate = 0;
    if ~isempty(PossibleSolutions)
        for idPosSol = 1:size(PossibleSolutions,2)
            TotalPoints = sum(ismember(idxClustersJoined(idxClustersJoined ~= 0),idxs(PossibleSolutions(~isnan(PossibleSolutions(:,idPosSol)),idPosSol))));
            if TotalPoints > MaxPoints
                Candidate = idPosSol;
                MaxPoints = TotalPoints;
            end
        end
    end

    idxClustersJoined(~ismember(idxClustersJoined,idxs(PossibleSolutions(~isnan(PossibleSolutions(:,Candidate)),Candidate)))) = 0;
    idxModPl = find(~isnan(PossibleSolutions(:,Candidate)));
 
    Solution = PossibleSolutions(:,Candidate);
    if plotting
        figure('Name','After Joining KMeans');
        hold on
        quiver3(clusterCentro(1,:),clusterCentro(2,:),clusterCentro(3,:),clusterNormals(1,:),clusterNormals(2,:),clusterNormals(3,:));
        plot3(X,Y,Z,'.r','markersize',0.1);
        plot3(clusterCentro(1,:),clusterCentro(2,:),clusterCentro(3,:),'ok');
        axis image
    end
end