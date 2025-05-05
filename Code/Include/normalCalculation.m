function normals = normalCalculation(points,k,distance)
    if nargin<3
        distance=100000;
    end
    p = points;
    m = size(p,2);
    n = zeros(3,m);
    v = ver('stats');
    aux=ver;
    v = aux(1);
    if str2double(v.Version) >= 7.3
        [neighborsTmp,dstTmp] = knnsearch(transpose(p), transpose(p), 'k', k+1);
        neighbors=transpose(neighborsTmp);
        dst=transpose(dstTmp);
    else
        neighbors = kNearestNeighbors(p, p, k+1);
    end
    for i = 1:m
        xTemp = p(:,neighbors(2:end, i));
        % Select only distances < distance
        ids=dst(2:end, i) < distance;
        x=xTemp(:,ids);
        k=size(x,2);
        p_bar = 1/k * sum(x,2);
        P = (x - repmat(p_bar,1,k)) * transpose(x - repmat(p_bar,1,k)); %spd matrix P
        %P = 2*cov(x);
        [V,D] = eig(P);
        [~, idx] = min(diag(D)); % choses the smallest eigenvalue
        n(:,i) = V(:,idx);   % returns the corresponding eigenvector
    end
    
    normals = n;
end