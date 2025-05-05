function [pointsCube,bariCenter,normalsCube,framesOK,errorFrame,ObjectsModelAux] = estimateCubeModel(Objects,sizeEdge,methods,filteringAlways,percentageOutliers)

%  SegmentedPoints -> Debe pasar a Objects...
NumFaces = 3; % Cube
Angle = 90; % Cube
ThrJoin = 35;
ThrDist = 35;
AngleModel =    [0 90 90; 90 0 90 ; 90 90 0];
AngleMin =      [0 89 89; 89 0 89 ; 89 89 0];
AngleMax =      [0 91 91; 91 0 91 ; 91 91 0];
AngleMinTotal = [0 85 85; 85 0 85 ; 85 85 0];
AngleMaxTotal = [0 95 95; 95 0 95 ; 95 95 0];
verbose = false;
        
    
        withGT = 0;
    
        % noises=[0.00010];
        iterMax = 50;%00; % Solo 1 iteracion
        %   methods={0,[6,0],[6,2]}; %,20}; %LSWC LSC LSCC LSGC
        %methods=[6,2]; %,20}; %LSWC LSC LSCC LSGC
       
       % percentageOutliers=0.20; %0.5
        maximumPercentageChange=0.05; %1;
        

      %  scaleReg=0.3;
      %  Objects=samplingTiles(Objects,scaleReg,'nearest');


Objects2 = Objects;

% Cluster faces of cube
if verbose
    disp(['k-Means clustering']);
end
[ObjectsModelAux,pView,NumPlanesTot,idxModPlTot,iniPntTot,kmeanPntTot,idxClustersFinal,~,goodViews] = scenePlanesClusteringCube(Objects2,NumFaces,AngleModel,withGT);
                                                                                    

ObjectsModelInit=ObjectsModelAux;
pViewInit=pView;

ObjectsModelAuxtmp=ObjectsModelAux;
ObjectsModelInittmp=ObjectsModelInit;
pViewtmp=pView;
pViewInittmp=pViewInit;


ObjectsModelAux=ObjectsModelAuxtmp;
ObjectsModelInit=ObjectsModelInittmp;
pView=pViewtmp;
pViewInit=pViewInittmp;






errorAnt=1000*ones(1,size(Objects,2));


ObjectsModelAux=ObjectsModelInit; % Aux is modified for different iterations
pViewResult{1,1}=pViewInit{1,1};

if methods(1)==20 || (methods(1)==6 && methods(2)==0 || methods(1)== 0) || percentageOutliers==0 %MC-RANSAC
    pViewRemovedOutlier=pViewResult;
else
    [ObjectsModelAux,pViewRemovedOutlier,idxClustersRemoved]=removeOutliers(ObjectsModelAux,pViewResult,NumPlanesTot,idxClustersFinal,goodViews,percentageOutliers);
   
end
idxClustersNew=idxClustersFinal;


initialgoodViews=goodViews;
initialViews=[1:size(Objects,2)];
errorFrame=zeros(1,size(Objects,2));
for i=1:iterMax
    % Initial data
    if filteringAlways
        [ObjectsModelAux,pViewRemovedOutlier,idxClustersRemoved]=removeOutliers(ObjectsModelAux,pViewResult,NumPlanesTot,idxClustersNew,goodViews,percentageOutliers);
    end
    constraints = 1;
    synthethic = 1;
    
    if verbose
        disp(['Linear Regression']);
    end
    
    
    
    [ObjectsModelLSEM6,returnTotLSEM6] = LSEMarkers(ObjectsModelAux,pViewRemovedOutlier,NumPlanesTot,idxModPlTot,iniPntTot,kmeanPntTot,1,constraints,synthethic,methods,AngleModel,AngleMax,AngleMin,i*10,goodViews);
    
    
    if verbose
        disp(['Assigning closest planes to points']);
    end
    
    [ObjectsModelAux,pViewResult,errorIt,timeCP,idxClustersNew,perChange,errorLoc,errorNorm] = ClosestPlaneWithIds(ObjectsModelLSEM6,NumPlanesTot,idxClustersNew,goodViews);
    
    
    errorFrame(goodViews)=errorIt(goodViews);
    goodViews=initialViews(perChange>maximumPercentageChange); % Hay que seguir procesando
    
    if abs( sum(perChange)-sum(errorAnt))<0.001 || sum(perChange)==0 || max(perChange)<=maximumPercentageChange
        break;
    end
    if sum((perChange-errorAnt) > 0) > 0 % Aumenta el error y cogemos anterior
        ids=find((perChange-errorAnt) > 0);
        ObjectsModelAux(ids)=ObjectsModelAuxAnt(ids);
        goodViews=initialViews(perChange>maximumPercentageChange & (perChange-errorAnt) < 0 );
        perChange(ids)=0;
        errorAnt(ids)=0;
        if size(goodViews,2)==0
            break;
        end
    end
    errorAnt= perChange;
    ObjectsModelAuxAnt=ObjectsModelAux;
    pViewRemovedOutlier=pViewResult;
end

 [pointsCube,normalsCube,bariCenter]=CalculatePointsInCube(ObjectsModelAux,sizeEdge,initialgoodViews);
 framesOK=initialgoodViews;
end