function [ObjectsOut,pViewOut,idxClustersRemoved] = removeOutliers(ObjectsIn,pViewIn,NumPlanesTot,idxClustersFinal,goodViews,percentageOutliersIn)
plotting = false;
  ObjectsOut = ObjectsIn;
percentageOutliers=1-percentageOutliersIn;
idxClustersRemoved=idxClustersFinal;
pView=extractPointsFromCubeperView(ObjectsIn,idxClustersFinal,goodViews);
for nViewAux = 1:size(goodViews,2)
    
        idxP = goodViews(nViewAux);
 
         NumPlanes = NumPlanesTot(idxP);
         p = pView{idxP};
         pViewOutTemp=cell(1,NumPlanes);
         errorTemp=0;
         numPoints=0;
          tCplane=tic;
             
             
         for nP=1:NumPlanes
             if nP>size(p,2)
                 disp('kkkk');
             end
            points=p{nP}; % Planes according kmeans
            % Recalcular normales
            X=points(:,1);
            Y=points(:,2);
            Z=points(:,3);
         %   plot3(X,Y,Z,'r.');
         %   hold on;
            centroid=median([X Y Z]);
         %   plot3(centroid(1),centroid(2),centroid(3),'g.');
            %distances=sum(abs(repmat(centroid,size(X,1),1)-[X Y Z]),2);
            distances=sqrt(sum((repmat(centroid,size(X,1),1)-[X Y Z]).^2,2));
            
            [distanceOrdered,ids]=sort(distances,'ascend');
            numElementsOutlier=floor(size(X,1)*percentageOutliers);
            potential_outlier = ids(1:numElementsOutlier);
            pViewOutTemp{nP}=[pViewOutTemp{nP}; p{nP}(potential_outlier,:)];
            idxNP=[1:size(idxClustersFinal{idxP},2)];
            idxidxNP=idxNP(idxClustersFinal{idxP}==nP);
            idxToRemove=idxidxNP(ids(numElementsOutlier+1:end));
            idxClustersRemoved{idxP}(idxToRemove)=0;
         %   plot3(X(potential_outlier),Y(potential_outlier),Z(potential_outlier),'b.');
         end


         pViewOut{idxP}=pViewOutTemp;
 
   end
%  pViewOutComparative=extractPointsFromObjectperView(ObjectsIn,idxClustersRemoved);
end