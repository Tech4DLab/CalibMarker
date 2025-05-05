function pN=deJoinData(XNorm,sizePlanes)
    numPlanes=size(sizePlanes,2);
    pN{1}=XNorm(1:sizePlanes(1),:);
    tam=sizePlanes(1);
    for i=2:numPlanes
         pN{i}=XNorm(tam+1:tam+sizePlanes(i),:);
         tam=tam+sizePlanes(i);
    end
end