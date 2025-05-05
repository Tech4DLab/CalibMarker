function [ObjectsOut,pView,NumPlanesTot,idxModPlTot,iniPntTot,kmeanPntTot,idxClustersFinal,idReorderFinal,goodViews] = scenePlanesClusteringCube(ObjectsIn,NumFaces,AngleModel,withGT)

    % Model extraction 
    ObjectsOut = ObjectsIn;
    NumPlanes = 0;
    NumPlanesTot = 0;
    timeView = [0 0 0 0];
    numPla = 0;
    thrMinSize = 200;
    RatioPlanesNoExact = [0,0];
    Cont = 1;
    verbose = false;
    goodViews = [];
    for nView = 1:size(ObjectsIn,2) %8
       % disp(['---View Processed number: ' num2str(nView)]);
        clear Obj
        X = ObjectsIn(nView).X;
        Y = ObjectsIn(nView).Y;
        Z = ObjectsIn(nView).Z;
        if size(X,2)==0
            X=1;
            Y=1;
            Z=1;
        end
        
        mask = ObjectsIn(nView).mask;

        N = normalCalculation([X;Y;Z],500,50); %13 100 puntos y 50 milimetros maximo
        % Normalization of normal vectors  
        VectorNormalization = zeros(3,length(X)) - [X;Y;Z];
        for ii = 1:size(VectorNormalization,2)
            VectorNormalization(:,ii) = VectorNormalization(:,ii)/norm(VectorNormalization(:,ii));
        end
        N = normalsNormalization(N,VectorNormalization);
       
        idxClustersFinal{nView} = [];
        
        numObj=1;
        contNumMarkers = 0;
        for nObj=1:numel(numObj)
            if verbose
               disp(['------View ' num2str(nView) ' Object Processed number: ' num2str(nObj)]);
            end
            clear objMask objX objY objZ objN Planes map mapmask

           
       
            objX = X;
            objY = Y;
            objZ = Z;
            
            objN = N;
            VectorNormalizationAux = VectorNormalization;
            
            if size(objN,2) > thrMinSize%100
                contNumMarkers = contNumMarkers +1;
                tt = [];
                ss = [];
                
                Xx = objX;
                Yy = objY;
                Zz = objZ;
                    
              	clear stats clustIds p idxClustersJoined idxSolutionKM idxModPl
              	
                   	tKmeans=tic;
                    [~,idxClustersJoined,idxSolutionKM, idxModPl,~,~,~] = Clusteringkmeans([objX;objY;objZ], objN,NumFaces,AngleModel);
                %     [~,idxClustersJoined, idxInAngle, clusterNormals, clusterCentro] = kmeansPlaneRANSAC(Points, Normals,ThrJoin,ThrDist,NumFaces,AngleMax,VectorNormalization);
                    timeKmeans = toc(tKmeans);

                    clustIds = uunique(idxClustersJoined(idxClustersJoined ~= 0));
                    for i = 1:size(clustIds,2)
                       stats(i).Area = sum(idxClustersJoined == clustIds(i));
                    end
                
                
                    idxSolutionKMAux = idxSolutionKM(~isnan(idxSolutionKM));
                    [~,idReorder] = sort(idxSolutionKMAux);
                    thrArea = 35;
                    idxArea = find([stats(:).Area] > thrArea);
                    idReorder = idReorder(idxArea);
                    
                    
                
                %% RANSAC with constraints
                NumPlanes = [];
                ssAux = 0;
                idxClusterAux = zeros(1,length(idxClustersJoined));
                for nArea = 1: length(idxArea)
                    xx = Xx(idxClustersJoined == clustIds(idxArea(nArea))); %idxInAngle & idxClustersJoined == idxArea(m)

                    ssAux = ssAux + size(xx,2);
                    yy = Yy(idxClustersJoined == clustIds(idxArea(nArea)));
                    zz = Zz(idxClustersJoined == clustIds(idxArea(nArea)));
                    

                    if(size(xx,2) >= 30) & ~withGT
                        idAux = find(idxClustersJoined == clustIds(idxArea(nArea)));
                        idxClusterAux(idAux) = nArea;
                        p{nArea} = [xx' yy' zz'];
                        NumPlanes = [NumPlanes nArea];
                    elseif withGT
                         p{nArea} = [xx' yy' zz'];
                         NumPlanes = [NumPlanes nArea];
                    end
                    
                end
                if ~withGT
                    idReorder = idReorder(NumPlanes);

                    idxModPlTot{nView} = idxModPl(NumPlanes); 
                    idReorderFinal{nView} = idReorder;

                else
                    idxModPlTot{nView} = idxModPlGT{nView};
                end
                
                %%%%%%% REORDER %%%%%%%%%
                p(idReorder) = p; %Reorder the planes to be aligned with the model
                %%%%%%%
                    
                pView{nView} = p;
                idxClustersFinal{nView} = idxClusterAux;
                NumPlanesTot(nView) = size(NumPlanes,2);
                if NumPlanesTot(nView)==3
                    goodViews = [goodViews nView]; % Stores the views that are actually stored
                end
                
                ssTot = ssAux;
                iniPntTot(nView) = size(objX,2);
                kmeanPntTot(nView) = ssTot;
                tt = [tt timeKmeans];
                    

                timeKmeans = mean(tt);
                timeKmenasStd = std(tt);
                
                timeRansac = 0;
                tComplete = 0;
                timeView(nView,:) = [timeKmeans timeKmenasStd size(objX,2) ssTot];
           
            end
        end

        ObjectsOut(nView).Nx = N(1,:);
        ObjectsOut(nView).Ny = N(2,:);
        ObjectsOut(nView).Nz = N(3,:);

    end
    
end