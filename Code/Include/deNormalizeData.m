

function XDN = deNormalizeData(X, mu, stddev)


% Declare variables
XDN = X;

% Calculates mean and std dev for each feature
for i=1:size(mu,2)
    %XDN(:,i) = (X(:,i)*stddev(1,i))+mu(1,i);
        XDN(:,i) = X(:,i)+mu(1,i);
end


end