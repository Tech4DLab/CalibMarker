function [normals,points]= LSEConstrainedWithSolverNPlanes(p,lambda1,lambda2,lambda3,normalize,mode,AngleModel,AngleMax,AngleMin,synthetic)

plotting = false;

%  p{1}=datasample(p{1},min([size(p{1},1) size(p{2},1) size(p{3},1)]));
%  p{2}=datasample(p{2},min([size(p{1},1) size(p{2},1) size(p{3},1)]));
%  p{3}=datasample(p{3},min([size(p{1},1) size(p{2},1) size(p{3},1)]));
numPlanes=size(p,2);

if normalize(1)
     
    [pJoined,sizePlanes]=JoinData(p);
     
    % Spatial normalization
     
     
    [XNorm, mu, stddev] = NormalizeData(pJoined);
       
         % Orientation normalization
 
 % [CNO,TM]=NormalizeOrientationPerPlane(XNorm,sizePlanes,synthetic,4);
 if normalize(2)
     [CNO,TM]=NormalizeOrientation(XNorm,synthetic); % OK
     ITM=inv(TM);
     DO=ITM*CNO';
 else
    CNO=XNorm;
    TM=eye(3);
 end
  %
  %  CalculateAnglesAccordingZ(CNO,sizePlanes);
    pN=deJoinData(CNO,sizePlanes);
    
    if plotting
         plot3(pN{1}(:,1),pN{1}(:,2),pN{1}(:,3),'rx')
         hold on
         plot3(pN{2}(:,1),pN{2}(:,2),pN{2}(:,3),'gx')
         plot3(pN{3}(:,1),pN{3}(:,2),pN{3}(:,3),'bx')
        % plot3(pN{4}(:,1),pN{4}(:,2),pN{4}(:,3),'cx')
%         plot3(pN{5}(:,1),pN{5}(:,2),pN{5}(:,3),'y.')
   %      plot3(pN{6}(:,1),pN{6}(:,2),pN{6}(:,3),'m.')
    end
else
    pN=p;
end

for i=1:numPlanes
    X{i}=double([ones(size(pN{i},1),1) pN{i}(:,1) pN{i}(:,2)]);
    Z{i}=double(pN{i}(:,3));
end
   


bM=[0 0 0;
    0 -1 0;
    0 0 -1];

L=bM*bM;

for i=1:numPlanes
    
theta_hat{i} = sdpvar(3,1);
theta_hatZ{i} = sdpvar(1,1);
residuals{i} = (Z{i} - ((X{i}*theta_hat{i})/theta_hatZ{i}));

end

%ops = sdpsettings('solver',['mosek,fmincon'],'verbose',3);%,'showprogress',0,'warning',0);


switch mode
    % 
    case 0
         Objective = residuals{1}'*residuals{1}/size(X{1},1);
        for i=2:numPlanes
           Objective = Objective + (residuals{i}'*residuals{i}/size(X{i},1));
        end
        Constraints=[];
    case 1 % No parece valido
        Objective = residuals{1}'*residuals{1} /size(X{1},1);
        for i=2:numPlanes
           Objective = Objective + residuals{i}'*residuals{i} /size(X{i},1);
        end
        
        Constraints = [(lambda1*theta_hat{2}'*theta_hat{3}) <= beta,
               (lambda2*theta_hat{1}'*theta_hat{3}) <= beta, 
              lambda3*theta_hat{1}'*theta_hat{2}  <= beta,
              beta >= 0];
    case 2 % OK
         Objective = residuals{1}'*residuals{1}/size(X{1},1);
        for i=2:numPlanes
           Objective = Objective + (residuals{i}'*residuals{i}/size(X{i},1));
        end
        first=true;
        Constraints=[];
        for i=1:numPlanes
           for j=i:numPlanes % Sólo se recorre la mitad
                if AngleModel(i,j)==90
                    if first
                        Constraints = [((theta_hat{i}'*L*theta_hat{j}) + theta_hatZ{i}*theta_hatZ{j}) == 0 ];
                      
                        first=false;
                    else
                     Constraints = [ Constraints, ((theta_hat{i}'*L*theta_hat{j}) + theta_hatZ{i}*theta_hatZ{j}) == 0];
                     
                    end
                end
           end
            Constraints = [ Constraints, theta_hatZ{i} >0];%, theta_hatZ{i} <=1]; % Z puede variar
        end
        
                   

    case 3 % No funciona con ruido
        Objective = sum(abs(residuals{1})) /size(X{1},1) + sum(abs(residuals{2})) /size(X{2},1) + sum(abs(residuals{3})) /size(X{3},1) ;
        Constraints = [(theta_hat{2}'*L*theta_hat{3}) + 1 == 0,
                       (theta_hat{1}'*L*theta_hat{3}) + 1 == 0, 
                       (theta_hat{1}'*L*theta_hat{2}) + 1 == 0];
        
%         epsilon = sdpvar(1,1);
%         Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1) ;
%         Constraints = [(theta_hat{2}'*L*theta_hat{3} + 1)^2 / ((theta_hat{2}'*L*theta_hat{2} + 1) * (theta_hat{3}'*L*theta_hat{3} + 1)) <= 1 - epsilon,
%                        (theta_hat{1}'*L*theta_hat{3} + 1)^2 / ((theta_hat{1}'*L*theta_hat{1} + 1) * (theta_hat{3}'*L*theta_hat{3} + 1)) <= 1 - epsilon, 
%                        (theta_hat{1}'*L*theta_hat{2} + 1)^2 / ((theta_hat{1}'*L*theta_hat{1} + 1) * (theta_hat{2}'*L*theta_hat{2} + 1)) <= 1 - epsilon,
%                        epsilon > 0];
    case 4
        epsilon1 = sdpvar(1,1);
        epsilon2 = sdpvar(1,1);
        epsilon3 = sdpvar(1,1);

        boundInf=(AngleModel-AngleMin)*pi/180;
        boundSup=(AngleMax-AngleModel)*pi/180;
        bounde1 = max(cos(boundInf(2,3))^2,cos(boundSup(2,3))^2);
        bounde2 = max(cos(boundInf(1,3))^2,cos(boundSup(1,3))^2);
        bounde3 = max(cos(boundInf(1,2))^2,cos(boundSup(1,2))^2);
        disp(['Bounds: ',num2str(bounde1),' ',num2str(bounde2),' ',num2str(bounde3)]);
        Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1) ;
        Constraints = [((theta_hat{2}'*L*theta_hat{3}) + 1) / (norm([theta_hat{2}'*bM 1]) * norm([theta_hat{3}'*bM 1])) <= epsilon1,
                       ((theta_hat{1}'*L*theta_hat{3}) + 1) / (norm([theta_hat{1}'*bM 1]) * norm([theta_hat{3}'*bM 1])) <= epsilon2, 
                       ((theta_hat{1}'*L*theta_hat{2}) + 1) / (norm([theta_hat{1}'*bM 1]) * norm([theta_hat{2}'*bM 1])) <= epsilon3,
                       ((theta_hat{2}'*L*theta_hat{3}) + 1) / (norm([theta_hat{2}'*bM 1]) * norm([theta_hat{3}'*bM 1])) >= -epsilon1,
                       ((theta_hat{1}'*L*theta_hat{3}) + 1) / (norm([theta_hat{1}'*bM 1]) * norm([theta_hat{3}'*bM 1])) >= -epsilon2, 
                       ((theta_hat{1}'*L*theta_hat{2}) + 1) / (norm([theta_hat{1}'*bM 1]) * norm([theta_hat{2}'*bM 1])) >= -epsilon3,
                       0 <= epsilon1 < bounde1,
                       0 <= epsilon2 < bounde2,
                        0 <= epsilon3 < bounde3];
%                     case 5
%         epsilon1 = sdpvar(1,1);
%         epsilon2 = sdpvar(1,1);
%         epsilon3 = sdpvar(1,1);
%         epsilon4 = sdpvar(1,1);
%         boundInf=(AngleModel-AngleMin)*pi/180;
%         boundSup=(AngleMax-AngleModel)*pi/180;
%         % Los bounds pueden ser grandes y luego decreciendo segun vamos
%         % iterando para ser cada vez más estricto...
%         bounde1 = max(cos(boundInf(2,3))^2,cos(boundSup(2,3))^2);
%         bounde2 = max(cos(boundInf(1,3))^2,cos(boundSup(1,3))^2);
%         bounde3 = max(cos(boundInf(1,2))^2,cos(boundSup(1,2))^2);
%         disp(['Bounds: ',num2str(bounde1),' ',num2str(bounde2),' ',num2str(bounde3)]);
%         Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1) ;
%         Constraints = [((theta_hat{2}'*L*theta_hat{3}) + 1)  <= epsilon1,
%                        ((theta_hat{1}'*L*theta_hat{3}) + 1)  <= epsilon2, 
%                        ((theta_hat{1}'*L*theta_hat{2}) + 1)  <= epsilon3,
%                        ((theta_hat{2}'*L*theta_hat{3}) + 1)  >= -epsilon1,
%                        ((theta_hat{1}'*L*theta_hat{3}) + 1)  >= -epsilon2, 
%                        ((theta_hat{1}'*L*theta_hat{2}) + 1)  >= -epsilon3,
%                        0 <= epsilon1 < bounde1,
%                        0 <= epsilon2 < bounde2,
%                        0 <= epsilon3 < bounde3,
%                        [theta_hat{1}'*L 1]'*[theta_hat{1}'*L 1] == 1,
%                        [theta_hat{2}'*L 1]'*[theta_hat{2}'*L 1] == 1,
%                        [theta_hat{3}'*L 1]'*[theta_hat{3}'*L 1] == 1];
    case 5
        epsilon1 = sdpvar(1,1);
        epsilon2 = sdpvar(1,1);
        epsilon3 = sdpvar(1,1);
        epsilon4 = sdpvar(1,1);
        epsilon5 = sdpvar(1,1);
        epsilon6 = sdpvar(1,1);
               
        boundInf=(AngleModel-AngleMin)*pi/180;
        boundSup=(AngleMax-AngleModel)*pi/180;
        % Los bounds pueden ser grandes y luego decreciendo segun vamos
        % iterando para ser cada vez más estricto...
        bounde1 = max(cos(boundInf(2,3))^2,cos(boundSup(2,3))^2)/lambda1;
        bounde2 = max(cos(boundInf(1,3))^2,cos(boundSup(1,3))^2)/lambda2;
        bounde3 = max(cos(boundInf(1,2))^2,cos(boundSup(1,2))^2)/lambda3;
        bounde1 = 1 - bounde1;
        bounde2 = 1 - bounde2;
        bounde3 = 1 - bounde3;
        disp(['Bounds: ',num2str(bounde1),' ',num2str(bounde2),' ',num2str(bounde3)]);
        Objective = norm(residuals{1},1)/(2*size(X{1},1)) + norm(residuals{2},1) /(2*size(X{2},1)) + norm(residuals{3},1) /(2*size(X{3},1));
        %Objective = residuals{1}'*residuals{1} /(2*size(X{1},1)) + residuals{2}'*residuals{2} /(2*size(X{2},1)) + residuals{3}'*residuals{3} /(2*size(X{3},1)) ;
        Constraints = [((theta_hat{2}'*L*theta_hat{3}) + 1)  <= epsilon1,
                       ((theta_hat{1}'*L*theta_hat{3}) + 1)  <= epsilon2, 
                       ((theta_hat{1}'*L*theta_hat{2}) + 1)  <= epsilon3,
                       ((theta_hat{2}'*L*theta_hat{3}) + 1)  >= -epsilon1,
                       ((theta_hat{1}'*L*theta_hat{3}) + 1)  >= -epsilon2,
                       ((theta_hat{1}'*L*theta_hat{2}) + 1)  >= -epsilon3,
                       0 <= epsilon1 < bounde1,
                       0 <= epsilon2 < bounde2,
                       0 <= epsilon3 < bounde3];%,
%                        [theta_hat{1}'*L 1]*[theta_hat{1}'*L 1]' - 1 <= epsilon4,
%                        [theta_hat{2}'*L 1]*[theta_hat{2}'*L 1]' - 1 <= epsilon5,
%                        [theta_hat{3}'*L 1]*[theta_hat{3}'*L 1]' - 1 <= epsilon6,
%                        [theta_hat{1}'*L 1]*[theta_hat{1}'*L 1]' - 1 >= -epsilon4,
%                        [theta_hat{2}'*L 1]*[theta_hat{2}'*L 1]' - 1 >= -epsilon5,
%                        [theta_hat{3}'*L 1]*[theta_hat{3}'*L 1]' - 1 >= -epsilon6,
%                        0 <= epsilon4 < 0.001,
%                        0 <= epsilon5 < 0.001,
%                        0 <= epsilon6 < 0.001];
case 6
        epsilon1 = sdpvar(1,1);
        epsilon2 = sdpvar(1,1);
        epsilon3 = sdpvar(1,1);
        epsilon4 = sdpvar(1,1);
        epsilon5 = sdpvar(1,1);
        epsilon6 = sdpvar(1,1);
               
        boundInf=(AngleModel-AngleMin)*pi/180;
        boundSup=(AngleMax-AngleModel)*pi/180;
        % Los bounds pueden ser grandes y luego decreciendo segun vamos
        % iterando para ser cada vez más estricto...
        bounde1 = max(sin(boundInf(2,3)),sin(boundSup(2,3)))/lambda1;
        bounde2 = max(sin(boundInf(1,3)),sin(boundSup(1,3)))/lambda2;
        bounde3 = max(sin(boundInf(1,2)),sin(boundSup(1,2)))/lambda3;
        disp(['Bounds: ',num2str(bounde1),' ',num2str(bounde2),' ',num2str(bounde3)]);
        Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1) ;
       % Objective =residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1);
        %Objective = residuals{1}'*residuals{1} /(2*size(X{1},1)) + residuals{2}'*residuals{2} /(2*size(X{2},1)) + residuals{3}'*residuals{3} /(2*size(X{3},1)) ;
%         Constraints = [((theta_hat{2}'*L*theta_hat{3}) + 1)  <= bounde1,
%                        ((theta_hat{1}'*L*theta_hat{3}) + 1)  <= bounde2, 
%                        ((theta_hat{1}'*L*theta_hat{2}) + 1)  <= bounde3,
%                        ((theta_hat{2}'*L*theta_hat{3}) + 1)  >= -bounde1,
%                        ((theta_hat{1}'*L*theta_hat{3}) + 1)  >= -bounde2,
%                        ((theta_hat{1}'*L*theta_hat{2}) + 1)  >= -bounde3,
         Constraints = [((theta_hat{2}'*L*theta_hat{3}) + 1)  <= bounde1,
                        ((theta_hat{1}'*L*theta_hat{3}) + 1)  <= bounde2, 
                        ((theta_hat{1}'*L*theta_hat{2}) + 1)  <= bounde3,
                       [theta_hat{1}'*L 1]*[theta_hat{1}'*L 1]' == 1,
                       [theta_hat{2}'*L 1]*[theta_hat{2}'*L 1]' == 1,
                       [theta_hat{3}'*L 1]*[theta_hat{3}'*L 1]' == 1];
                  
%                        [theta_hat{1}'*L 1]*[theta_hat{1}'*L 1]' - 1 <= epsilon4,
%                        [theta_hat{2}'*L 1]*[theta_hat{2}'*L 1]' - 1 <= epsilon5,
%                        [theta_hat{3}'*L 1]*[theta_hat{3}'*L 1]' - 1 <= epsilon6,
%                        [theta_hat{1}'*L 1]*[theta_hat{1}'*L 1]' - 1 >= -epsilon4,
%                        [theta_hat{2}'*L 1]*[theta_hat{2}'*L 1]' - 1 >= -epsilon5,
%                        [theta_hat{3}'*L 1]*[theta_hat{3}'*L 1]' - 1 >= -epsilon6,
%                        0 <= epsilon4 < 0.001,
%                        0 <= epsilon5 < 0.001,
%                        0 <= epsilon6 < 0.001];
   
case 7
        epsilon1 = sdpvar(1,1);
        epsilon2 = sdpvar(1,1);
        epsilon3 = sdpvar(1,1);
        epsilon4 = sdpvar(1,1);
        epsilon5 = sdpvar(1,1);
        epsilon6 = sdpvar(1,1);
               
        boundInf=(AngleModel-AngleMin)*pi/180;
        boundSup=(AngleMax-AngleModel)*pi/180;
        % Los bounds pueden ser grandes y luego decreciendo segun vamos
        % iterando para ser cada vez más estricto...
        bounde1 = max(sin(boundInf(2,3)),sin(boundSup(2,3)))/lambda1;
        bounde2 = max(sin(boundInf(1,3)),sin(boundSup(1,3)))/lambda2;
        bounde3 = max(sin(boundInf(1,2)),sin(boundSup(1,2)))/lambda3;
        disp(['Bounds: ',num2str(bounde1),' ',num2str(bounde2),' ',num2str(bounde3)]);
      %  Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1);
      %  Objective = residuals{1}'*residuals{1}  + residuals{2}'*residuals{2}  + residuals{3}'*residuals{3};
       % Objective = sum(abs(residuals{1})) + sum(abs(residuals{2})) + sum(abs(residuals{3}));
         Objective = norm(residuals{1},1) + norm(residuals{2},1) + norm(residuals{3},1);
       % Objective =residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1);
        %Objective = residuals{1}'*residuals{1} /(2*size(X{1},1)) + residuals{2}'*residuals{2} /(2*size(X{2},1)) + residuals{3}'*residuals{3} /(2*size(X{3},1)) ;

         Constraints = [((theta_hat{2}'*L*theta_hat{3}) + 1)  == 0,
                        ((theta_hat{1}'*L*theta_hat{3}) + 1)  == 0, 
                        ((theta_hat{1}'*L*theta_hat{2}) + 1)  == 0];
                    
%                      Constraints = [((theta_hat{2}'*L*theta_hat{3}) + 1)  == 0,
%                         ((theta_hat{1}'*L*theta_hat{3}) + 1)  == 0, 
%                         ((theta_hat{1}'*L*theta_hat{2}) + 1)  == 0];
%                     ,
%                         [theta_hat{1}'*L 1]*[theta_hat{1}'*L 1]' == 1,
%                        [theta_hat{2}'*L 1]*[theta_hat{2}'*L 1]' == 1,
%                        [theta_hat{3}'*L 1]*[theta_hat{3}'*L 1]' == 1];
%                    
        
case 8
        
               
        boundInf=(AngleModel-AngleMin)*pi/180;
        boundSup=(AngleMax-AngleModel)*pi/180;
        % Los bounds pueden ser grandes y luego decreciendo segun vamos
        % iterando para ser cada vez más estricto...
        bounde1 = max(sin(boundInf(2,3)),sin(boundSup(2,3)))/lambda1;
        bounde2 = max(sin(boundInf(1,3)),sin(boundSup(1,3)))/lambda2;
        bounde3 = max(sin(boundInf(1,2)),sin(boundSup(1,2)))/lambda3;
        bound1 = sdpvar(length(residuals{1}),1);
        bound2 = sdpvar(length(residuals{2}),1);
        bound3 = sdpvar(length(residuals{3}),1);
        bounde1 = sdpvar(1,1);
        bounde2 = sdpvar(1,1);
        bounde3 = sdpvar(1,1);
        
        theta_hatN{2}=((theta_hat{2}'*L*theta_hat{3}) + 1);
        theta_hatN{1}=((theta_hat{1}'*L*theta_hat{3}) + 1);
        theta_hatN{3}=((theta_hat{1}'*L*theta_hat{2}) + 1);
        
%        disp(['Bounds: ',num2str(bounde1),' ',num2str(bounde2),' ',num2str(bounde3)]);
      %  Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1);
         Objective = sum(bound1) + sum(bound2) + sum(bound3) + sum(bounde1) + sum(bounde2) + sum(bounde3);
% 
%          Constraints = [-bound1 <= residuals{1} <= bound1,
%              -bound2 <= residuals{2} <= bound2,
%              -bound3 <= residuals{3} <= bound3,
%              -bounde1 <= theta_hatN{2}/(norm([theta_hat{2}'*L 1],1)*norm([theta_hat{3}'*L 1],1)) <= bounde1,
%              -bounde2 <= theta_hatN{1}/(norm([theta_hat{1}'*L 1],1)*norm([theta_hat{3}'*L 1],1))  <= bounde2, 
%              -bounde3 <= theta_hatN{3}/(norm([theta_hat{1}'*L 1],1)*norm([theta_hat{2}'*L 1],1)) <= bounde3];
         
                 Constraints = [ -bound1<= residuals{1} <= bound1,
             -bound2<= residuals{2} <= bound2,
             -bound3 <= residuals{3} <= bound3,
             -bounde1 <= theta_hatN{2} <= bounde1,
              -bounde1 <= theta_hatN{1} <= bounde2,
               -bounde1 <=  theta_hatN{3} <= bounde3,
               bounde1>=0,
               bounde2>=0,
               bounde3>=0];
%              0 <= norm(theta_hatN{2}/(norm([theta_hat{2}'*L 1],1)*norm([theta_hat{3}'*L 1],1)),1) <= bounde1,
%              0 <= norm(theta_hatN{1}/(norm([theta_hat{1}'*L 1],1)*norm([theta_hat{3}'*L 1],1)),1)  <= bounde2, 
%              0 <= norm(theta_hatN{3}/(norm([theta_hat{1}'*L 1],1)*norm([theta_hat{2}'*L 1],1)),1) <= bounde3];
         
%                     ,
%                         ;
%                    
        case 9 % OK
        Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1) ;
    
        Constraints = [(((theta_hat{2}'*L*theta_hat{3}) + 1) / (norm([theta_hat{2}'*bM 1],1) * norm([theta_hat{3}'*bM 1],1))) == 0,
                       (((theta_hat{1}'*L*theta_hat{3}) + 1) / (norm([theta_hat{1}'*bM 1],1) * norm([theta_hat{3}'*bM 1],1))) == 0, 
                       (((theta_hat{1}'*L*theta_hat{2}) + 1) / (norm([theta_hat{1}'*bM 1],1) * norm([theta_hat{2}'*bM 1],1))) == 0];
         
          case 10 % Probamos con relajacion
              
        boundSup=cos((AngleMin)*pi/180);
        boundInf=cos((AngleMax)*pi/180);
              
     
        
          Objective = residuals{1}'*residuals{1} /(size(X{1},1));
        for i=2:numPlanes
           Objective = Objective + (residuals{i}'*residuals{i} /(size(X{i},1)));
        end
        %   Objective = residuals{1}'*residuals{1} /size(X{1},1) + residuals{5}'*residuals{5} /size(X{5},1) + residuals{2}'*residuals{2} /size(X{2},1) + residuals{4}'*residuals{4} /size(X{4},1) + residuals{3}'*residuals{3} /size(X{3},1);
       %  Objective = residuals{2}'*residuals{2} /size(X{2},1) + residuals{3}'*residuals{3} /size(X{3},1) ;
        first=true;
        Constraints=[];
        for i=1:numPlanes
           for j=i:numPlanes % Sólo se recorre la mitad
                if AngleModel(i,j)~=0
                   %     if AngleModel(i,j) == 0 % Coplanar
                    %        Constraints = [Constraints,((theta_hat{i}'*L*theta_hat{j}) + theta_hatZ{i}*theta_hatZ{j}) >= boundInf(i,j)];
                         %   Constraints = [Constraints, sum([theta_hat{i}'*L theta_hatZ{i}].^2)^(1/2)==1];
                         %   Constraints = [Constraints, sum([theta_hat{j}'*L theta_hatZ{j}].^2)^(1/2)==1];
                         %   Constraints = [Constraints, (sum([theta_hat{i}'*L theta_hatZ{i}].^2)^(1/2))*(sum([theta_hat{j}'*L theta_hatZ{j}].^2)^(1/2))==1];
                    %    else    % orthogonal
                           Constraints = [Constraints,boundInf(i,j) <= ((theta_hat{i}'*L*theta_hat{j}) + theta_hatZ{i}*theta_hatZ{j}) <= boundSup(i,j)];
                           Constraints = [Constraints,(sum([theta_hat{i}'*L theta_hatZ{i}].^2)^(1/2))*(sum([theta_hat{j}'*L theta_hatZ{j}].^2)^(1/2))==1];
                        %   Constraints = [Constraints, ((theta_hat{i}'*L*theta_hat{j}) + theta_hatZ{i}*theta_hatZ{j})/(sum([theta_hat{i}'*L theta_hatZ{i}].^2)^(1/2))*(sum([theta_hat{j}'*L theta_hatZ{j}].^2)^(1/2)) < boundSup(i,j)];
                        %   Constraints = [Constraints, ((theta_hat{i}'*L*theta_hat{j}) + theta_hatZ{i}*theta_hatZ{j})/(sum([theta_hat{i}'*L theta_hatZ{i}].^2)^(1/2))*(sum([theta_hat{j}'*L theta_hatZ{j}].^2)^(1/2)) >= boundInf(i,j)];
                       
                        %    Constraints = [Constraints, sum([theta_hat{i}'*L theta_hatZ{i}].^2)^(1/2)==1];
                        %    Constraints = [Constraints, sum([theta_hat{j}'*L theta_hatZ{j}].^2)^(1/2)==1];
                         %  Constraints = [Constraints, (sum([theta_hat{i}'*L theta_hatZ{i}].^2)^(1/2))*(sum([theta_hat{j}'*L theta_hatZ{j}].^2)^(1/2))==1];
                 %       end
                       
                 end
           end
            Constraints = [ Constraints, theta_hatZ{i} >0];%, theta_hatZ{i} <=1]; % Z puede variar
        end
        
        
        
              
              
        
   
end



%Objective = residuals{1}'*residuals{1} + residuals{2}'*residuals{2} + residuals{3}'*residuals{3} + lambda1*theta_hat{1}'*theta_hat{2} +  lambda2*theta_hat{1}'*theta_hat{3} +   lambda3*theta_hat{2}'*theta_hat{3};
% Constraints = [];

% Objective = residuals{1}'*residuals{1} + residuals{2}'*residuals{2} + residuals{3}'*residuals{3} ;
% Constraints = [lambda1*theta_hat{1}'*theta_hat{2} +  lambda2*theta_hat{1}'*theta_hat{3} +   lambda3*theta_hat{2}'*theta_hat{3} <= beta];

% /(norm(theta_hat{1})*norm(theta_hat{2}))
% /(norm(theta_hat{1})*norm(theta_hat{3}))
% /(norm(theta_hat{2})*norm(theta_hat{3}))

     
 %ops = sdpsettings('solver','mosek','verbose',3,'showprogress',1,'warning',1);      
% ops = sdpsettings('verbose',3,'showprogress',1,'warning',1);      
 ops = sdpsettings('solver',['mosek,fmincon'],'verbose',0,'showprogress',0,'warning',0,'fmincon.MaxIter',10000,'fmincon.MaxFunEvals',5000);
 %ops = sdpsettings('solver','mosek','verbose',1,'showprogress',0,'warning',0);
 warning('off','YALMIP:strict');
% [Frobust,robust_objective] = robustify(Constraints ,Objective);
% solution=optimize(Frobust,robust_objective,ops);
solution=optimize(Constraints ,Objective,ops);

for i=1:numPlanes
theta{i}=value(theta_hat{i});
thetaZ{i}=value(theta_hatZ{i});
end


% if  plotting
% disp(['Theta 1: [',tD1(1,:),',',tD1(2,:),',',tD1(3,:),'] Norma: ',num2str(norm([-theta{1}(2) -theta{1}(3) 1]))]);
% disp(['Theta 2: [',tD2(1,:),' ',tD2(2,:),' ',tD2(3,:),'] Norma: ',num2str(norm([-theta{2}(2) -theta{2}(3) 1]))]);
% disp(['Theta 3: [',tD3(1,:),' ',tD3(2,:),' ',tD3(3,:),'] Norma: ',num2str(norm([-theta{3}(2) -theta{3}(3) 1]))]);
% tD1=num2str(value(theta{1}));
% tD2=num2str(value(theta{2}));
% tD3=num2str(value(theta{3}));
% end
if normalize(1)
    
     ITM=inv(TM);
    
     
     for i=1:numPlanes
     
     ZN=(X{i}*theta{i})/(thetaZ{i});
     DOT{i}=[X{i}(:,2) X{i}(:,3) ZN];
     end
     
      [DOTJ,sizePlanes]=JoinData(DOT);
  
      DOTJROT=ITM*DOTJ';
      
      DO=deJoinData(DOTJROT',sizePlanes);
  %  DO{i}=ITM*[X{i}(:,2) X{i}(:,3) ZN]';
         for i=1:numPlanes
   % DO{i}=deNormalizeOrientation([X{i}(:,2) X{i}(:,3) ZN]',ITM,synthetic); % OK
    
  %  ZDN{i} = deNormalizeData(DO{i},mu,stddev);
    points{i} = deNormalizeData(DO{i},mu,stddev);
    
  %  points{i}=[p{i}(:,1) p{i}(:,2) ZDN{i}(:,3)];
   
    %normals{i}=ITM*[-theta{i}(2) -theta{i}(3) thetaZ{i}]';
    normals{i}=ITM*[-theta{i}(2) -theta{i}(3) thetaZ{i}]';

    
   normals{i}=normals{i}';
       
%     for ii = 1:length(normals)
%               
%    normals{i}(ii) = normals{i}(ii)/norm(normals{i});
%      end
     end
else
 
for i=1:numPlanes
    points{i}=[X{i}(:,2) X{i}(:,3) X{i}*theta{i}/thetaZ{i}];
   % points{i}=[X{i}(:,2) X{i}(:,3) Z{i}];
    normals{i}=[-theta{i}(2) -theta{i}(3) thetaZ{i}];
     end
end




if plotting
    for kki=1:3
        for kkj=1:3
             if AngleMin(kki,kkj)~=0
             angleDetNum=((theta{kki}'*L*theta{kkj}) + thetaZ{kki}*thetaZ{kkj});
             angleDetDen=(sum([theta{kki}'*L thetaZ{kki}].^2)^(1/2))*(sum([theta{kkj}'*L thetaZ{kkj}].^2)^(1/2));
             angleDet=acos(angleDetNum/angleDetDen);
             disp(['Ang ',num2str(kki), ' Ang ',num2str(kkj),' Value: ',num2str(angleDet*180/pi),' V2 ',num2str(angleDetNum/angleDetDen)]);
             end
        end
          end
               
               
   
    
    cent1=mean(points{1});
    cent2=mean(points{2});
    cent3=mean(points{3});
  %      cent4=mean(points{4});
%    cent5=mean(points{5});
 figure
 plot3(points{1}(:,1),points{1}(:,2),points{1}(:,3),'r.')
 hold on
 plot3(points{2}(:,1),points{2}(:,2),points{2}(:,3),'g.')
 plot3(points{3}(:,1),points{3}(:,2),points{3}(:,3),'b.')
%  plot3(points{4}(:,1),points{4}(:,2),points{4}(:,3),'y.')
%   plot3(points{5}(:,1),points{5}(:,2),points{5}(:,3),'c.')
 plot3(cent1(1),cent1(2),cent1(3),'r.','markersize',10)
 plot3(cent2(1),cent2(2),cent2(3),'g.','markersize',10)
 plot3(cent3(1),cent3(2),cent3(3),'b.','markersize',10)
%  plot3(cent4(1),cent4(2),cent4(3),'y.','markersize',10)
% plot3(cent5(1),cent5(2),cent5(3),'c.','markersize',10)
 quiver3(cent1(1),cent1(2),cent1(3),normals{1}(1),normals{1}(2),normals{1}(3),100);
 quiver3(cent2(1),cent2(2),cent2(3),normals{2}(1),normals{2}(2),normals{2}(3),100);
 quiver3(cent3(1),cent3(2),cent3(3),normals{3}(1),normals{3}(2),normals{3}(3),100);
%  quiver3(cent4(1),cent4(2),cent4(3),normals{4}(1),normals{4}(2),normals{4}(3),10000);
% quiver3(cent5(1),cent5(2),cent5(3),normals{5}(1),normals{5}(2),normals{5}(3),1000);
if normalize(1)
 plot3(points{1}(:,1),points{1}(:,2),p{1}(:,3),'r.')
 plot3(points{2}(:,1),points{2}(:,2),p{2}(:,3),'g.')
 plot3(points{3}(:,1),points{3}(:,2),p{3}(:,3),'b.')
 hold off
else
 plot3(points{1}(:,1),points{1}(:,2),Z{1},'r.')
 plot3(points{2}(:,1),points{2}(:,2),Z{2},'g.')
 plot3(points{3}(:,1),points{3}(:,2),Z{3},'b.')
 hold off
end
end
 



end




function [anglesN prodesc norms] = CalculateAngles(t1,t2,t3)
    norms(1)=norm(t1);  
    norms(2)=norm(t2);  
    norms(3)=norm(t3);
    
    t1N=t1/norms(1);
    t2N=t2/norms(2);
    t3N=t3/norms(3);
    

    prodesc(1)=dot(t1N,t2N);
    prodesc(2)=dot(t1N,t3N);
    prodesc(3)=dot(t2N,t3N);
    
    anglesN(1)=acos(roundn(prodesc(1),-8))*180/pi;
    anglesN(2)=acos(roundn(prodesc(2),-8))*180/pi;
    anglesN(3)=acos(roundn(prodesc(3),-8))*180/pi;
    
    
    
end

function [pJoined,sizePlanes]=JoinData(p)
numPlanes=size(p,2);
    pJoined=p{1};
     sizePlanes(1)=size(p{1},1);
     for i=2:numPlanes
         pJoined=[pJoined;p{i}];
         sizePlanes(i)=size(p{i},1);
     end
end



