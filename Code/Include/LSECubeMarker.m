function  [p_best,n_best] = LSECubeMarker(p,NumPlanes,AngleModelAux,idxModPl,synthetic,method,AngleModel,AngleMax,AngleMin,iter)

plotting=0;


switch method(1)
    case 0 % Without constraints 
        for nP = 1:NumPlanes
             [n_best{nP} p_best{nP}]=LSEPlane(p{nP});
         
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
           
        end
    % First in, first plane % Sequential
    case 1 
        for nP = 1:NumPlanes
            if plotting
                plot3(p{nP}(:,1),p{nP}(:,2),p{nP}(:,3),'r.');
                hold on;
            end
            % First plane
                if nP==1
                  [n_best{nP} p_best{nP}]=LSEPlane(p{nP});
                else
                   angle=AngleModelAux(idxModPl(nP),idxModPl(nP-1));
                   if angle==90
                    P1=p_best{nP-1}(10,:);
                    P2=p_best{nP-1}(5,:);
                    vectorinPlane=(P2-P1)/norm(P2-P1);
                    normal2=cross(n_best{nP-1}',vectorinPlane);
                    normal2=normal2/norm(normal2);
                    [n_best{nP} P1 p_best{nP}]=CalculatePerpendicularPlanes(p{nP},normal2,n_best{nP-1}',P1);
                else
                    [n_best{nP} P1 p_best{nP}]=CalculateParallelPlanes(p{nP},n_best{nP-1}');
                    
                end
            end
          
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
           
        end
% Select largest plane
    case 2
        
        for nP = 1:NumPlanes
            numInPlanes(nP)=size(p{nP},1);
        end
 
        % Select biggest
        [~, idx]=sort(numInPlanes,'descend');
        
        for ii = 1:NumPlanes
            nP=idx(ii);
            if plotting
                plot3(p{nP}(:,1),p{nP}(:,2),p{nP}(:,3),'r.');
                hold on;
            end
            % First plane
                if ii==1
                  [n_best{nP} p_best{nP}]=LSEPlane(p{nP});
                else
                   angle=AngleModelAux(idxModPl(nP),idxModPl(idx(ii-1)));
                   if angle==90
                    P1=p_best{idx(ii-1)}(10,:);
                    P2=p_best{idx(ii-1)}(5,:);
                    vectorinPlane=(P2-P1)/norm(P2-P1);
                    normal2=cross(n_best{idx(ii-1)}',vectorinPlane);
                    normal2=normal2/norm(normal2);
                    [n_best{nP} P1 p_best{nP}]=CalculatePerpendicularPlanes(p{nP},normal2,n_best{idx(ii-1)}',P1);
                else
                    [n_best{nP} P1 p_best{nP}]=CalculateParallelPlanes(p{nP},n_best{idx(ii-1)}');
                    
                end
            end
          
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
           
        end
       case 3 % Case 2 with third plane constrained 
           for nP = 1:NumPlanes
            numInPlanes(nP)=size(p{nP},1);
        end
 
        % Select biggest
        [~, idx]=sort(numInPlanes,'descend');
        
        for ii = 1:NumPlanes
            nP=idx(ii);
            if plotting
                plot3(p{nP}(:,1),p{nP}(:,2),p{nP}(:,3),'r.');
                hold on;
            end
            % First plane
                if ii==1
                  [n_best{nP} p_best{nP}]=LSEPlane(p{nP});
                   
                elseif ii==2 % Second plane assume perpendicular to the first
                   angle=AngleModelAux(idxModPl(nP),idxModPl(idx(ii-1)));
                   P1=p_best{idx(ii-1)}(10,:);
                   P2=p_best{idx(ii-1)}(5,:);
                   vectorinPlane=(P2-P1)/norm(P2-P1);
                   normal2=cross(n_best{idx(ii-1)}',vectorinPlane);
                   normal2=normal2/norm(normal2);
                   [n_best{nP} P1 p_best{nP}]=CalculatePerpendicularPlanes(p{nP},normal2,n_best{idx(ii-1)}',P1);
                elseif ii==3 % Third plane perpendicular to both  
                    % Calculate 2 points just to plot the solution
                    P1=p_best{idx(ii-2)}(10,:);
                    P2=p_best{idx(ii-1)}(10,:);
                    [n_best{nP} P1 p_best{nP}]=CalculatePerpendicularTo2Planes(p{nP},n_best{idx(ii-2)}',n_best{idx(ii-1)}',P1,P2);
                end
                if plotting
                        plot3(p_best{nP}(:,1),p_best{nP}(:,2),p_best{nP}(:,3),'b.');
                 end
                      
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
           
        end
        
        case 4 % Case 4 combining different solutions 
           
        idx=perms([1:size(p,2)]);
        error=Inf;
        for ii = 1:size(idx,1)
            [p_bestAux n_bestAux errorAux]=CubeAllConstrained(p,idx(ii,:),NumPlanes,AngleModelAux,idxModPl,synthetic)
            if errorAux<error
                error=errorAux;
                p_best=p_bestAux;
                n_best=n_bestAux;
            end
           
        end
    case 5 % LSE por stochastic gradient descend
        for nP = 1:NumPlanes
            numInPlanes(nP)=size(p{nP},1);
     
            alpha=0.1;
            numIters=10000;
            [n_best{nP} p_best{nP}]=planeGradientDescend(p{nP},alpha, numIters);
        
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
 
            
            
        end
        case 6 % Close form all together
       
             lambda1=0.000001;
             lambda2=0.000001;
             lambda3=0.000001;
               lambda1=100000;
               lambda2=100000;
               lambda3=100000;
              alpha=0.1;
            numIters=10000;
            normalize=[1,1]; %% Normalize datos y normales
            lambda=[0.000001 0.001 0.01 0.1 1 10 20 50 100 1000 10000];
            i=1;
              warning('off','YALMIP:strict');
             % p=balanceData(p);
             
             [n_best,p_best]=LSEConstrainedWithSolverNPlanes(p,lambda(i),lambda(i),lambda(i),normalize,method(2),AngleModel,AngleMax,AngleMin,synthetic);
             
        for nP = 1:NumPlanes
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
        end
            
            
        
           
        
    case 7
      for nP = 1:NumPlanes
             [n_best{nP} p_best{nP}]=LSEPlaneWithSolver(p{nP});
         
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
           
        end
        
end
end
function [p_best n_best error]=CubeAllConstrained(p,idx,NumPlanes,AngleModelAux,idxModPl,synthetic)
 % Select biggest
               error=0;
        for ii = 1:NumPlanes
            nP=idx(ii);
            
            % First plane
                if ii==1
                  [n_best{nP} p_best{nP}]=LSEPlane(p{nP});
                elseif ii==2 % Second plane assume perpendicular to the first
                   angle=AngleModelAux(idxModPl(nP),idxModPl(idx(ii-1)));
                   P1=p_best{idx(ii-1)}(10,:);
                   P2=p_best{idx(ii-1)}(5,:);
                   vectorinPlane=(P2-P1)/norm(P2-P1);
                   normal2=cross(n_best{idx(ii-1)}',vectorinPlane);
                   normal2=normal2/norm(normal2);
                   [n_best{nP} P1 p_best{nP}]=CalculatePerpendicularPlanes(p{nP},normal2,n_best{idx(ii-1)}',P1);
                elseif ii==3 % Third plane perpendicular to both  
                    P1=p_best{idx(ii-2)}(10,:);
                    P2=p_best{idx(ii-1)}(10,:);
                    [n_best{nP} P1 p_best{nP}]=CalculatePerpendicularTo2Planes(p{nP},n_best{idx(ii-2)}',n_best{idx(ii-1)}',P1,P2);
                end
                
                      
            if synthetic
                VectorNormalization = UnitVectorFromPoints(p_best{nP},[0 0 0]);
                n_best{nP} = normalsNormalization(n_best{nP}',VectorNormalization);
            else
                n_best{nP} = normalsNormalization(n_best{nP}',[0 0 -1]);
            end
           [~,eT]=CalculateError(p{nP},p_best{nP});
           error=error+eT;
        end
end

function [errorIn errorTot]=CalculateError(p,p_best)


errorIn=sqrt(sum((p-p_best).^2,2));
errorTot=sum(errorIn)/size(p,1);
end