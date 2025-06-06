function [TR, TT, ER, t, bestIter] = icpJorge(q,p,varargin)
% Perform the Iterative Closest Point algorithm on three dimensional point
% clouds.
%
% [TR, TT] = icp(q,p)   returns the rotation matrix TR and translation
% vector TT that minimizes the distances from (TR * p + TT) to q.
% p is a 3xm matrix and q is a 3xn matrix.
%
% [TR, TT] = icp(q,p,k)   forces the algorithm to make k iterations
% exactly. The default is 10 iterations.
%
% [TR, TT] = icp(q,p,k)   forces the algorithm to make k iterations
% exactly. The default is 10 iterations.
%
% [TR, TT] = icp(q,p,k,th)   th is the acceptable threshold for leaving the
% algorithm. 
%
% [TR, TT, ER] = icp(q,p,k,th)   also returns the RMS of errors for k
% iterations in a (k+1)x1 vector. ER(0) is the initial error.
%
% [TR, TT, ER, t] = icp(q,p,k,th)   also returns the calculation times per
% iteration in a (k+1)x1 vector. t(0) is the time consumed for preprocessing.
%
% Additional settings may be provided in a parameter list:
%
% Colour
%       {[]} | {3xn,3xm}
%       If Colour is set, a matrix of colour is needed being the three
%       first rows the RGB component of q colour and the last three the p
%       RGB color
%
% Boundary
%       {[]} | 1x? vector
%       If EdgeRejection is set, a vector can be provided that indexes into
%       q and specifies which points of q are on the boundary.
%
% EdgeRejection
%       {false} | true
%       If EdgeRejection is true, point matches to edge vertices of q are
%       ignored. Requires that boundary points of q are specified using
%       Boundary or that a triangulation matrix for q is provided.
%
% Extrapolation
%       {false} | true
%       If Extrapolation is true, the iteration direction will be evaluated
%       and extrapolated if possible using the method outlined by 
%       Besl and McKay 1992.
%
% Matching
%       {bruteForce} | Delaunay | GLtree | kDtree
%       Specifies how point matching should be done. 
%       bruteForce is usually the slowest and kDtree is the fastest.
%       Note that the kDtree option is depends on the Statistics Toolbox
%       v. 7.3 or higher.
%       Note that the GLtree option is depending on the GLtree3DFEX
%       implementation at Matlab Central File ID: #24607.
%
% Minimize
%       {point} | plane | lmaPoint
%       Defines whether point to point or point to plane minimization
%       should be performed. point is based on the SVD approach and is
%       usually the fastest. plane will often yield higher accuracy. It 
%       uses linearized angles and requires surface normals for all points 
%       in q. Calculation of surface normals requires substantial pre
%       proccessing.
%       The option lmaPoint does point to point minimization using the non
%       linear least squares Levenberg Marquardt algorithm. Results are
%       generally the same as in points, but computation time may differ.
%
% Normals
%       {[]} | n x 3 matrix
%       A matrix of normals for the n points in q might be provided.
%       Normals of q are used for point to plane minimization.
%       Else normals will be found through a PCA of the 4 nearest
%       neighbors.
%
% ReturnAll
%       {false} | true
%       Determines whether R and T should be returned for all iterations
%       or only for the last one. If this option is set to true, R will be
%       a 3x3x(k+1) matrix and T will be a 3x1x(k+1) matrix.
%
% Triangulation
%       {[]} | ? x 3 matrix
%       A triangulation matrix for the points in q can be provided,
%       enabling EdgeRejection. The elements should index into q, defining
%       point triples that act together as triangles.
%
% Verbose
%       {false} | true
%       Enables extrapolation output in the Command Window.
%
% Weight
%       {@(match)ones(1,m)} | Function handle
%       For point or plane minimization, a function handle to a weighting 
%       function can be provided. The weighting function will be called 
%       with one argument, a 1xm vector that specifies point pairs by 
%       indexing into q. The weighting function should return a 1xm vector 
%       of weights for every point pair.
%
% WorstRejection
%       {0} | scalar in ]0; 1[
%       Reject a given percentage of the worst point pairs, based on their
%       Euclidean distance.
%
% fitting  
%           {1}: No rejecting points
%           2: Reject correspondences on boundaries (Just reject boundaries)
%           [3, percentGood]: % Best points & Boundaries
%           [4, angle]: Reject points whose normals are below angle &       Boundaries
%           [5,std]: Reject < std*std(distances);
%           [6, angle, percentGood]: Combining 3 & 4 & Boundaries
%           [7, percentGood]: Combining 3 & Boundaries & Colour
%
% Martin Kjer and Jakob Wilm, Technical University of Denmark, 2011

% Use the inputParser class to validate input arguments.
inp = inputParser;

inp.addRequired('q', @(x)isreal(x) && size(x,1) == 3);
inp.addRequired('p', @(x)isreal(x) && size(x,1) == 3);

inp.addOptional('iter', 10, @(x)x > 0 && x < 10^5);

inp.addOptional('th', 2.5, @(x)x > 0 && x < 10^5);

inp.addParamValue('Boundary', [], @(x)size(x,1) == 1);

inp.addParamValue('EdgeRejection', false, @(x)islogical(x));

inp.addParamValue('Extrapolation', false, @(x)islogical(x));

validMatching = {'bruteForce','Delaunay','kDtree','GLtree'};
inp.addParamValue('Matching', 'bruteForce', @(x)any(strcmpi(x,validMatching)));

validMinimize = {'point','plane','lmapoint'};
inp.addParamValue('Minimize', 'point', @(x)any(strcmpi(x,validMinimize)));

inp.addParamValue('Normals', [], @(x)isreal(x) && size(x,1) == 3);

inp.addParamValue('NormalsData', [], @(x)isreal(x) && size(x,1) == 3);

inp.addParamValue('ReturnAll', false, @(x)islogical(x));

inp.addParamValue('Triangulation', [], @(x)isreal(x) && size(x,2) == 3);

inp.addParamValue('Verbose', false, @(x)islogical(x));

inp.addParamValue('Weight', @(x)ones(1,length(x)), @(x)isa(x,'function_handle'));

inp.addParamValue('WorstRejection', 0, @(x)isscalar(x) && x > 0 && x < 1);

inp.addParamValue('Threshold', 0, @(x)isscalar(x) && x > 0 && x < 1);

inp.addParamValue('fitting',1,@(x)isscalar(x(1)) && x{1}(1) > 1 && x{1}(1) < 8);

inp.addParamValue('Colour',[],@(x)size(x{1},1) == 3 && size(x{2},1) == 3 && size(x{1},2) == length(q) && size(x{2},2) == length(p))

inp.parse(q,p,varargin{:});
arg = inp.Results;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Actual implementation
plotting = false;
% Allocate vector for RMS of errors in every iteration.
t = zeros(arg.iter+1,1); 

% Start timer
tic;

Np = size(p,2);

% Transformed data point cloud
pt = p;

% Allocate vector for RMS of errors in every iteration.
ER = zeros(arg.iter+1,1); 

% Initialize temporary transform vector and matrix.
T = zeros(3,1);
R = eye(3,3);

% Initialize total transform vector(s) and rotation matric(es).
TT = zeros(3,1, arg.iter+1);
TR = repmat(eye(3,3), [1,1, arg.iter+1]);
    
% If Minimize == 'plane', normals are needed
if ((strcmp(arg.Minimize, 'plane') || strcmp(arg.Minimize, 'point')) && isempty(arg.Normals))
    arg.Normals = double(lsqnormest(q,4));
end

% If Minimize == 'plane', normals are needed
if ((strcmp(arg.Minimize, 'plane') || strcmp(arg.Minimize, 'point')) && isempty(arg.NormalsData))
    arg.NormalsData = double(lsqnormest(p,4));
end

% If Matching == 'Delaunay', a triangulation is needed
if strcmp(arg.Matching, 'Delaunay')
    DT = DelaunayTri(transpose(q));
end

% If Matching == 'kDtree', a kD tree should be built (req. Stat. TB >= 7.3)
if strcmp(arg.Matching, 'kDtree')
    kdOBJ = KDTreeSearcher(transpose(q));
end

% If Matching == 'GLtree', a GL tree should be built (req. File ID: #24607)
if strcmp(arg.Matching, 'GLtree')
    GLPNTR = BuildGLTree3DFEX(transpose(q));
end

% If edge vertices should be rejected, find edge vertices
if arg.EdgeRejection
    if isempty(arg.Boundary)
        bdr = find_bound(q, arg.Triangulation);
    else
        bdr = arg.Boundary;
    end
end

if arg.Extrapolation
    % Initialize total transform vector (quaternion ; translation vec.)
    qq = [ones(1,arg.iter+1);zeros(6,arg.iter+1)];   
    % Allocate vector for direction change and change angle.
    dq = zeros(7,arg.iter+1);
    theta = zeros(1,arg.iter+1);
end



% Initialize 
thrBetter = arg.th;
% if size(arg.Colour,1) > 0
%     thrBetter = 20;
% end
contbetter = 0;
better = 0;
bestIter = 0;

t(1) = toc;

% figure('Name','ICP JORGE');
% hold on;
% Go into main iteration loop
for k=1:arg.iter
       
    % Do matching
    switch arg.Matching
        case 'bruteForce'
            [match mind] = match_bruteForce(q,pt);
        case 'Delaunay'
            [match mind] = match_Delaunay(q,pt,DT);
        case 'GLtree'
            [match mind] = match_GLtree(q,pt,GLPNTR);
        case 'kDtree'
            [match mind] = match_kDtree(q,pt,kdOBJ);
    end

    % If matches to edge vertices should be rejected
    if arg.EdgeRejection
        p_idx = not(ismember(match, bdr));
        q_idx = match(p_idx);
        mindist = mind(p_idx);
    else
        p_idx = true(1, Np);
        q_idx = match;
        mindist = mind;
    end
    
    % If worst matches should be rejected
    if arg.WorstRejection
%         edge = round((1-arg.WorstRejection)*sum(p_idx)); % The number of points that we will have (numberOfPoints after EdgeRejection * (1-percentOfWorst))
%         pairs = find(p_idx);
%         [~, idx] = sort(mindist);
%         p_idx(pairs(idx(edge:end))) = false;
%         q_idx = match(p_idx);
%         mindist = mind(p_idx);
        if size(arg.Colour,1) > 0
            arg.fitting = {[7,1-arg.WorstRejection]};
        else
            arg.fitting = {[3,1-arg.WorstRejection]};
        end
    end
    
    %p -> DATA
    %q -> MODEL
    p_idx_aux = [1:size(p_idx,2)];
    p_idx_aux = p_idx_aux(p_idx);
    if( p_idx_aux > 0 & q_idx > 0)
        if size(arg.Colour,1) > 0
            [P1f,P2f,disFitt, distTot, ind]=rejectPoints(pt,q,arg.NormalsData,arg.Normals,p_idx_aux,q_idx,R,T,arg.fitting{1},arg.Colour{2},arg.Colour{1});
        else
            [P1f,P2f,disFitt, distTot, ind]=rejectPoints(pt,q,arg.NormalsData,arg.Normals,p_idx_aux,q_idx,R,T,arg.fitting{1},[],[]);
        end
    else
        TR(:,:,k+1) = NaN;
        TT(:,:,k+1) = NaN;
        break
    end
    pairs = find(p_idx);
    indx = false(1,size(pairs,2));
    indx(ind) = true;
    p_idx(pairs(~indx)) = false;
    q_idx = match(p_idx);
    mindist = mind(p_idx);
    if k == 1
        ER(k) = sqrt(sum(mindist.^2)/length(mindist));        
    end
    
    switch arg.Minimize
        case 'point'
            % Determine weight vector
            weights = arg.Weight(match);
            [R,T] = eq_point(q(:,q_idx),pt(:,p_idx), weights(p_idx));
        case 'plane'
            weights = arg.Weight(match);
            [R,T] = eq_plane(q(:,q_idx),pt(:,p_idx),arg.Normals(:,q_idx),weights(p_idx));
        case 'lmaPoint'
            [R,T] = eq_lmaPoint(q(:,q_idx),pt(:,p_idx));
    end
    
    if sum(abs(T)) > 10
        disp('Error Translation in ICP');
    end
    % Add to the total transformation
    TR(:,:,k+1) = R*TR(:,:,k);
    TT(:,:,k+1) = R*TT(:,:,k)+T;

    % Apply last transformation
    pt = TR(:,:,k+1) * p + repmat(TT(:,:,k+1), 1, Np);
    arg.NormalsData = TR(:,:,k+1) * arg.NormalsData;
%     plot3(pt(1,:),pt(2,:),pt(3,:),'.','markersize',0.1);
    % Root mean of objective function 
    
    if plotting && k==arg.iter
        figure;plot3(q(1,:),q(2,:),q(3,:),'.','markersize',0.1)
            hold on;plot3(pt(1,:),pt(2,:),pt(3,:),'r.','markersize',0.1);axis image
            hold on; line([q(1,q_idx);pt(1,p_idx)],[q(2,q_idx); pt(2,p_idx)],[q(3,q_idx);pt(3,p_idx)]);
    end
        
    ER(k+1) = rms_error(q(:,q_idx), pt(:,p_idx));
    
    % If Extrapolation, we might be able to move quicker
    if arg.Extrapolation
        qq(:,k+1) = [rmat2quat(TR(:,:,k+1));TT(:,:,k+1)];
        dq(:,k+1) = qq(:,k+1) - qq(:,k);
        theta(k+1) = (180/pi)*acos(dot(dq(:,k),dq(:,k+1))/(norm(dq(:,k))*norm(dq(:,k+1))));
        if arg.Verbose
            disp(['Direction change ' num2str(theta(k+1)) ' degree in iteration ' num2str(k)]);
        end
        if k>2 && theta(k+1) < 10 && theta(k) < 10
            d = [ER(k+1), ER(k), ER(k-1)];
            v = [0, -norm(dq(:,k+1)), -norm(dq(:,k))-norm(dq(:,k+1))];
            vmax = 25 * norm(dq(:,k+1));
            dv = extrapolate(v,d,vmax);
            if dv ~= 0
                q_mark = qq(:,k+1) + dv * dq(:,k+1)/norm(dq(:,k+1));
                q_mark(1:4) = q_mark(1:4)/norm(q_mark(1:4));
                qq(:,k+1) = q_mark;
                TR(:,:,k+1) = quat2rmat(qq(1:4,k+1));
                TT(:,:,k+1) = qq(5:7,k+1);
                % Reapply total transformation
                pt = TR(:,:,k+1) * p + repmat(TT(:,:,k+1), 1, Np);
                % Recalculate root mean of objective function
                % Note this is costly and only for fun!
                [~, mindist] = match_kDtree(q,pt,kdOBJ);
                ER(k+1) = sqrt(sum(mindist.^2)/length(mindist));
            end
        end
    end
    t(k+1) = toc;
%      if(k > 1)
%          disp(['        Iter.',sprintf('%d',k),'  RMS error: ',sprintf('%0.10g',ER(k)),'   time: ',sprintf('%0.10g',t(k)),' s']);        
%      else
%          disp(['        Initial Iter.',sprintf('%d',k),' Initial RMS error: ',sprintf('%0.10g',ER(k)),'   preprocessing time: ',sprintf('%0.10g',t(k)),' s']);        
%      end
    
    if k > 1
%         if(ER(k) > 50)
%            break; 
%         end    
        if(ER(k+1) >= better)
            contbetter = contbetter +1;
        else
            better = ER(k+1);
            bestIter = k+1;
            contbetter = 0;
        end
        if abs(ER(k)-ER(k-1))<arg.Threshold
            break
        end
    else % first iteration
%         if ER(k)<ER(k+1)
%             better = ER(k);
%             bestIter = k;
%         else
            better = ER(k+1);
            bestIter = k+1;
%         end
%         if better > 10
%             break;
%         end 

        
    end    
    
    if(contbetter > 10)
        break;
    end    
    
end

if not(arg.ReturnAll)
%     if(contbetter > 4)
%         if(better < thrBetter)   
%             disp(['        Best Iter.',sprintf('%d',bestIter), ' of last 6']);
%         else
%           disp(['        NOT GOOD. best RMS error >= ' num2str(thrBetter) ':',sprintf('%0.10g',ER(k))]);
%         end    
%             TR = TR(:,:,bestIter);
%             TT = TT(:,:,bestIter);        
%     else 
%        if k == 1
%           disp(['        RANSAC NOT GOOD. Initial RMS error: ',sprintf('%0.10g',ER(k))]); 
%        else    
          TR = TR(:,:,bestIter);
          TT = TT(:,:,bestIter);
%        end
%     end  
else
    TRFinal = eye(4,4);
    for nR = 1:size(TR,3)
       TRFinal(:,:) = TRFinal * ([TR(:,:,nR) TT(:,:,nR); [0 0 0 1]]);
    end
    
    TR = TRFinal;
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [match mindist] = match_bruteForce(q, p)
    m = size(p,2);
    n = size(q,2);    
    match = zeros(1,m);
    mindist = zeros(1,m);
    for ki=1:m
        d=zeros(1,n);
        for ti=1:3
            d=d+(q(ti,:)-p(ti,ki)).^2;
        end
        [mindist(ki),match(ki)]=min(d);
    end
    
    mindist = sqrt(mindist);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [match mindist] = match_Delaunay(q, p, DT)
	match = transpose(nearestNeighbor(DT, transpose(p)));
	mindist = sqrt(sum((p-q(:,match)).^2,1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [match mindist] = match_GLtree(q, p, GLPNTR)
	[match mindist] = NNSearch3DFEX(transpose(q), transpose(p), GLPNTR);
	match = transpose(match);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [match mindist] = match_kDtree(~, p, kdOBJ)
	[match mindist] = knnsearch(kdOBJ,transpose(p));
    match = transpose(match);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [R,T] = eq_point(q,p,weights)

m = size(p,2);
n = size(q,2);

% normalize weights
weights = weights ./ sum(weights);

% find data centroid and deviations from centroid
q_bar = q * transpose(weights);
q_mark = q - repmat(q_bar, 1, n);
% Apply weights
q_mark = q_mark .* repmat(weights, 3, 1);

% find data centroid and deviations from centroid
p_bar = p * transpose(weights);
p_mark = p - repmat(p_bar, 1, m);
% Apply weights
%p_mark = p_mark .* repmat(weights, 3, 1);

N = p_mark*transpose(q_mark); % taking points of q in matched order

[U,~,V] = svd(N); % singular value decomposition

R = V*transpose(U);

T = q_bar - R*p_bar;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [R,T] = eq_plane(q,p,n,weights)

n = n .* repmat(weights,3,1);

c = cross(p,n);

cn = vertcat(c,n);

C = cn*transpose(cn);

b = - [sum(sum((p-q).*repmat(cn(1,:),3,1).*n));
       sum(sum((p-q).*repmat(cn(2,:),3,1).*n));
       sum(sum((p-q).*repmat(cn(3,:),3,1).*n));
       sum(sum((p-q).*repmat(cn(4,:),3,1).*n));
       sum(sum((p-q).*repmat(cn(5,:),3,1).*n));
       sum(sum((p-q).*repmat(cn(6,:),3,1).*n))];

X = C\b;

cx = cos(X(1)); cy = cos(X(2)); cz = cos(X(3)); 
sx = sin(X(1)); sy = sin(X(2)); sz = sin(X(3)); 

R = [cy*cz cz*sx*sy-cx*sz cx*cz*sy+sx*sz;
     cy*sz cx*cz+sx*sy*sz cx*sy*sz-cz*sx;
     -sy cy*sx cx*cy];
    
T = X(4:6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [R,T] = eq_lmaPoint(q,p)

Rx = @(a)[1     0       0;
          0     cos(a)  -sin(a);
          0     sin(a)  cos(a)];
      
Ry = @(b)[cos(b)    0   sin(b);
          0         1   0;
          -sin(b)   0   cos(b)];
      
Rz = @(g)[cos(g)    -sin(g) 0;
          sin(g)    cos(g)  0;
          0         0       1];

Rot = @(x)Rx(x(1))*Ry(x(2))*Rz(x(3));

myfun = @(x,xdata)Rot(x(1:3))*xdata+repmat(x(4:6),1,length(xdata));


options = optimset('Algorithm', 'levenberg-marquardt');
x = lsqcurvefit(myfun, zeros(6,1), p, q, [], [], options);


R = Rot(x(1:3));
T = x(4:6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extrapolation in quaternion space. Details are found in:
%
% Besl, P., & McKay, N. (1992). A method for registration of 3-D shapes. 
% IEEE Transactions on pattern analysis and machine intelligence, 239?256.

function [dv] = extrapolate(v,d,vmax)

p1 = polyfit(v,d,1); % linear fit
p2 = polyfit(v,d,2); % parabolic fit
v1 = -p1(2)/p1(1); % linear zero crossing
v2 = -p2(2)/(2*p2(1)); % polynomial top point

if issorted([0 v2 v1 vmax]) || issorted([0 v2 vmax v1])
    disp('Parabolic update!');
    dv = v2;
elseif issorted([0 v1 v2 vmax]) || issorted([0 v1 vmax v2])...
        || (v2 < 0 && issorted([0 v1 vmax]))
    disp('Line based update!');
    dv = v1;
elseif v1 > vmax && v2 > vmax
    disp('Maximum update!');
    dv = vmax;
else
    disp('No extrapolation!');
    dv = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine the RMS error between two point equally sized point clouds with
% point correspondance.
% ER = rms_error(p1,p2) where p1 and p2 are 3xn matrices.

function ER = rms_error(p1,p2)
dsq = sum(power(p1 - p2, 2),1);
ER = sqrt(mean(dsq));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Converts (unit) quaternion representations to (orthogonal) rotation matrices R
% 
% Input: A 4xn matrix of n quaternions
% Output: A 3x3xn matrix of corresponding rotation matrices
%
% http://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#From_a_quaternion_to_an_orthogonal_matrix

function R = quat2rmat(quaternion)
q0(1,1,:) = quaternion(1,:);
qx(1,1,:) = quaternion(2,:);
qy(1,1,:) = quaternion(3,:);
qz(1,1,:) = quaternion(4,:);

R = [q0.^2+qx.^2-qy.^2-qz.^2 2*qx.*qy-2*q0.*qz 2*qx.*qz+2*q0.*qy;
     2*qx.*qy+2*q0.*qz q0.^2-qx.^2+qy.^2-qz.^2 2*qy.*qz-2*q0.*qx;
     2*qx.*qz-2*q0.*qy 2*qy.*qz+2*q0.*qx q0.^2-qx.^2-qy.^2+qz.^2];
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Least squares normal estimation from point clouds using PCA
%
% H. Hoppe, T. DeRose, T. Duchamp, J. McDonald, and W. Stuetzle. 
% Surface reconstruction from unorganized points. 
% In Proceedings of ACM Siggraph, pages 71:78, 1992.
%
% p should be a matrix containing the horizontally concatenated column
% vectors with points. k is a scalar indicating how many neighbors the
% normal estimation is based upon.
%
% Note that for large point sets, the function performs significantly
% faster if Statistics Toolbox >= v. 7.3 is installed.
%
% Jakob Wilm 2010

function n = lsqnormest(p, k)
m = size(p,2);
n = zeros(3,m);

v = ver('stats');
if str2double(v.Version) >= 7.3 
    neighbors = transpose(knnsearch(transpose(p), transpose(p), 'k', k+1));
else
    neighbors = kNearestNeighbors(p, p, k+1);
end

for i = 1:m
    x = p(:,neighbors(2:end, i));
    p_bar = 1/k * sum(x,2);
    
    P = (x - repmat(p_bar,1,k)) * transpose(x - repmat(p_bar,1,k)); %spd matrix P
    %P = 2*cov(x);
    
    [V,D] = eig(P);
    
    [~, idx] = min(diag(D)); % choses the smallest eigenvalue
    
    n(:,i) = V(:,idx);   % returns the corresponding eigenvector    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Boundary point determination. Given a set of 3D points and a
% corresponding triangle representation, returns those point indices that
% define the border/edge of the surface.

function bound = find_bound(pts, poly)

%Correcting polygon indices and converting datatype 
poly = double(poly);
pts = double(pts);

%Calculating freeboundary points:
TR = TriRep(poly, pts(1,:)', pts(2,:)', pts(3,:)');
FF = freeBoundary(TR);

%Output
bound = FF(:,1);
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 