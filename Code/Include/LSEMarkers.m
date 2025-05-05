function[ObjectsOut,returnTot] = LSEMarkers(ObjectsIn,pView,NumPlanesTot,idxModPlTot,iniPntTot,kmeanPntTot,object,constraints,synthetic,method,AngleModel,AngleMax,AngleMin,iter,goodViews)

plotting=0;
verbose = false;
% constraints -> 0, RANSAC no constraints
% constraints -> 1, RANSAC with constraints, 
% constraints -> 2, original RANSAC 

    ObjectsOut = ObjectsIn;
    k=5;%number of iterations
    t=10;%threshold used to id a point that fits well
    firstMean = 0;%whether to use or not the mean value of x2,y2,z2 for the seed or not.

    factorMinAcceptedData = 0.3; 
    factorInitialRequiredData = 0.1; 

    if object == 1
%         AngleModel =    [0 90 90; 90 0 90 ; 90 90 0];
%         AngleMin =      [0 80 80; 80 0 80 ; 80 80 0];
%         AngleMax =      [0 100 100; 100 0 100 ; 100 100 0];
%         AngleMinTotal = [0 70 70; 70 0 70 ; 70 70 0];
%         AngleMaxTotal = [0 110 110; 110 0 110 ; 110 110 0];
        
%         AngleModel =    [0 90 90; 90 0 90 ; 90 90 0];
%         AngleMin =      [0 85 85; 85 0 85 ; 85 85 0];
%         AngleMax =      [0 95 95; 95 0 95 ; 95 95 0];
%         AngleMinTotal = [0 80 80; 80 0 80 ; 80 80 0];
%         AngleMaxTotal = [0 100 100; 100 0 100 ; 100 100 0];
        if size(method,2)>2
            angvar=method(3);
        else
            angvar=0;
        end
        angmin=90-angvar;
        angmax=90+angvar;
        AngleModel =    [0 90 90; 90 0 90 ; 90 90 0];
        AngleMin =      [0 angmin angmin; angmin 0 angmin ; angmin angmin 0];
        AngleMax =      [0 angmax angmax; angmax 0 angmax ; angmax angmax 0];
        AngleMinTotal = [0 85 85; 85 0 85 ; 85 85 0];
        AngleMaxTotal = [0 95 95; 95 0 95 ; 95 95 0];
    elseif object == 2

       	AngleModel =    [0 80; 80 0];
        AngleMin =      [0 79; 79 0];
        AngleMax =      [0 81; 81 0];
        AngleMinTotal = [0 75; 75 0];
        AngleMaxTotal = [0 85; 85 0];
    else
        
        AngleModel =        [0 135 135 45 45; 135 0 60 90 120 ; 135 60 0 120 90; 45 90 120 0 60; 45 120 90 60 0];
        AngleMin =          [0 134 134 44 44; 134 0 59 89 119 ; 134 59 0 119 89; 44 89 119 0 59; 44 119 89 59 0];
        AngleMax =          [0 136 136 46 46; 136 0 61 91 121 ; 136 61 0 121 91; 46 91 121 0 61; 46 121 91 61 0];
        AngleMinTotal =     [0 130 130 40 40; 130 0 55 85 115 ; 130 55 0 115 85; 40 85 115 0 55; 40 115 85 55 0];
        AngleMaxTotal =     [0 140 140 50 50; 140 0 65 95 125 ; 140 65 0 125 95; 50 95 125 0 65; 50 125 95 65 0];
    end

    for nViewAux = 1:size(goodViews,2)
        idxP = goodViews(nViewAux);
           
            if verbose
                disp(['------View ' num2str(idxP)]);
            end
            AngleModelAux = AngleModel;
            AngleMinAux = AngleMin;
            AngleMaxAux = AngleMax;
            AngleMinTotalAux = AngleMinTotal;
            AngleMaxTotalAux = AngleMaxTotal;
            NumPlanes = NumPlanesTot(idxP);
            idxModPl = idxModPlTot{idxP};
            totalPnt = 0;
            p = pView{idxP};
   
                AngleModelAux = AngleModelAux(idxModPl,idxModPl);
                AngleMinAux = AngleMinAux(idxModPl,idxModPl);
                AngleMaxAux = AngleMaxAux(idxModPl,idxModPl);
                AngleMinTotalAux = AngleMinTotalAux(idxModPl,idxModPl);
                AngleMaxTotalAux = AngleMaxTotalAux(idxModPl,idxModPl);
           
             if plotting
                 figure;
             end
             tLSE=tic;
             [p_best,n_best]=LSECubeMarker(p,NumPlanes,AngleModelAux,idxModPl,synthetic,method,AngleModel,AngleMax,AngleMin,iter);
             timeLSE=toc(tLSE);
             for nP=1:NumPlanes
                 totalPnt = totalPnt + size(p_best{nP},1);
                Planes{nP}.plane = p_best{nP};
                Planes{nP}.nplane = n_best{nP};
                Planes{nP}.roplane = NaN;
                Planes{nP}.xplane = p_best{nP}(:,1);
                Planes{nP}.yplane = p_best{nP}(:,2);
                Planes{nP}.zplane = p_best{nP}(:,3);
                Planes{nP}.points = p{nP};
                normsReturn(:,nP) = n_best{nP};

             end
              
             if NumPlanes~=0
                ObjectsOut(idxP).Objec{1} = Planes;
                clear Planes;
             end

             % Calculate Angle Error
              for mat = 1:size(normsReturn,2)
                 n1 = sqrt( repmat(normsReturn(1,mat),1,size(normsReturn,2)).^2 + repmat(normsReturn(2,mat),1,size(normsReturn,2)).^2 + repmat(normsReturn(3,mat),1,size(normsReturn,2)).^2 );
                 n2 = sqrt( normsReturn(1,:).^2 + normsReturn(2,:).^2 + normsReturn(3,:).^2 );
                 norma=n1.*n2;
                 ang2=acos(roundn(dot([normsReturn(1,:);normsReturn(2,:);normsReturn(3,:)] , [repmat(normsReturn(1,mat),1,size(normsReturn,2));repmat(normsReturn(2,mat),1,size(normsReturn,2));repmat(normsReturn(3,mat),1,size(normsReturn,2))]) ./norma,-8))*180/pi;
                 angleMat(mat,:) = ang2;
              end
                clear normsReturn;
                angRes = abs(AngleModelAux - angleMat);
                clear angleMat;
                returnTot(idxP,1) = timeLSE;
                returnTot(idxP,2) = iniPntTot(idxP);
                returnTot(idxP,3) = kmeanPntTot(idxP);
                returnTot(idxP,4) = totalPnt;
                if sum(sum(angRes,2),1)==0
                    returnTot(idxP,5) = 0;
                returnTot(idxP,6) = 0;
                else
                returnTot(idxP,5) = mean(angRes(angRes~=0));
                returnTot(idxP,6) = std(angRes(angRes~=0));
                end
                returnTot(idxP,7) = NumPlanes;

            end
        end
