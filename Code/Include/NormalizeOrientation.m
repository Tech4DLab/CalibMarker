function [XNorm, M] = NormalizeOrientation(X,synthetic)
% This function provides orienation normalization 


% Declare variables
XNorm = X;


  p = X';
  n = zeros(3,1);
  k=size(p,2);
  x = p;
        p_bar = median(x,2);%1/k * sum(x,2); % Centroind
        P = (x - repmat(p_bar,1,k)) * transpose(x - repmat(p_bar,1,k)); %spd matrix P
        %P = 2*cov(x);
        [V,D] = eig(P);
        [~, idx] = min(diag(D)); % choses the smallest eigenvalue
        n = V(:,idx);   % returns the corresponding eigenvector
        n=n/norm(n);
        
        % Change basis to X Y
        if synthetic
            R = vrrotvec(n, [0 0 -1]);
        else
            R = vrrotvec(n, [0 0 1]);
        end
        M = vrrotvec2mat(R);
        XNorm=(M*X')';
    
end