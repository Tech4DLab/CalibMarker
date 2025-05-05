function newVector = changeRange(vector,minOld,maxOld,minNew,maxNew)

%changeRange function returns a vector in a new range of values.
% INPUT
%   vector: a vertor with values
%   minOld: min value in range of vector
%   maxOld: max value in range of vector
%   minNew: min value in the new vector
%   maxNew: max value in the new vector
%
% OUTPUT
%   newVector: the values of vector transformed to the new range
%

if minOld < 0
    maxOld = maxOld + abs(minOld);
    vector = vector + abs(minOld);
    minOld = 0;
    
else
    if minOld > 0;
        maxOld = maxOld - abs(minOld);
        vector = vector - abs(minOld);
        minOld = 0;
    end
end

auxMinNew = minNew;
if minNew < 0
    maxNew = maxNew + abs(auxMinNew);
    minNew = 0;
else
    if minNew > 0;
        maxNew = maxNew - abs(auxMinNew);
        minNew = 0;
    end
end

ratio = maxNew/maxOld;

newVector = single(vector) * ratio;
newVector = newVector + auxMinNew;
