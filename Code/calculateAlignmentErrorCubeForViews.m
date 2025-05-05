
function [errorTotal,errorPerCam] = calculateAlignmentErrorCubeForViews(idsAll,CubeBCenterAux,CubeNormalsAux,betterTR,mode,method)
        errorTotal=[];
        errorPerCam=[];
for nidsAll=1:size(idsAll,2)
    
    if method == 0 % Baricenter
        [CubeBCenter,CubeBNormals]=selectFrames(CubeBCenterAux,CubeNormalsAux,idsAll(nidsAll));
        [errorTotal(nidsAll),errorPerCam(nidsAll,:)]=calculateAlignmentErrorCube(CubeBCenter,CubeBNormals,betterTR,mode);
    else
        [CubePoints,CubeNormals]=selectFrames(CubePointsAux,CubeNormalsAux,idsAll(nidsAll));
        [errorTotal(nidsAll),errorPerCam(nidsAll,:)]=calculateAlignmentErrorCube(CubePoints,CubeNormals,betterTR,mode);
    end
end
end