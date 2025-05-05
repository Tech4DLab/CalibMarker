function [dataS modelS distS distT, ind]=rejectPoints(DATAi,MODELi,DATANORMALSi,MODELNORMALSi,idxP1,iclosest,R,t,fitting,DATACOLOURi,MODELCOLOURi)

 % Selecting points
 if ~isempty(DATACOLOURi) & ~isempty(MODELCOLOURi)
    DATACOLOUR=DATACOLOURi(:,idxP1);     
    MODELCOLOUR=MODELCOLOURi(:,iclosest);
 else
     DATACOLOUR=DATACOLOURi;
     MODELCOLOUR=MODELCOLOURi;
 end
DATA=DATAi(:,idxP1);

MODEL=MODELi(:,iclosest);

if size(DATANORMALSi,2)>0
DATANORMALS=DATANORMALSi(:,idxP1);
MODELNORMALS=MODELNORMALSi(:,iclosest);
DATANORMALSTransformed=R*DATANORMALS; % Transform the normals
end

% Transforming points
DATATransformed=(R*DATA)+repmat(t,1,size(DATA,2));

% Calculate distance
V=sqrt(sum((DATATransformed-MODEL).^2,1));
distT=V;
if fitting(1)==1 || fitting(1)==2 % No rejecting points or Reject boundaries is made in the matching, So we do not anything.
    ind=[1:size(DATA,2)];
end

if fitting(1)==3 % The best fitting(2) points
    fittingAbsolute=floor(size(DATA,2)*fitting(2));
    [soV,in]=sort(V);
    ind=in(1:fittingAbsolute);
end

if fitting(1)==4 % Normal
    normasModel=sqrt(MODELNORMALS(1,:).^2+MODELNORMALS(2,:).^2+MODELNORMALS(3,:).^2);
    normasData=sqrt(DATANORMALSTransformed(1,:).^2+DATANORMALSTransformed(2,:).^2+DATANORMALSTransformed(3,:).^2);
    normas=normasModel.*normasData;
    angles=(acos(dot(DATANORMALSTransformed,MODELNORMALS)./normas)*180/pi);
    
    [soVAng,inAng]=sort(angles);
    fittingAng=floor(size(DATA,2)*fitting(2));
    ind = inAng(1:fittingAng);
    
%     ind=angles<fitting(2); % We only use the data whose normal is below 45
end

if fitting(1)==5 % Reject 2.5 standard deviation
    stdV=std(V);
    ind=V<=fitting(2)*stdV;
end

if fitting(1)==6 % fitting(2)< Normals and Best fitting(2) points 
    normasModel=sqrt(MODELNORMALS(1,:).^2+MODELNORMALS(2,:).^2+MODELNORMALS(3,:).^2);
    normasData=sqrt(DATANORMALSTransformed(1,:).^2+DATANORMALSTransformed(2,:).^2+DATANORMALSTransformed(3,:).^2);
    normas=normasModel.*normasData;
    angles=ceil(acos(dot(DATANORMALSTransformed,MODELNORMALS)./normas)*180/pi);
    ind=angles<fitting(2); % We only use the data whose normal is below 45
%     ind = angles < median(angles) + std(angles) & angles > median(angles) - std(angles);
    
    V=sqrt(sum((DATATransformed(:,ind)-MODEL(:,ind)).^2,1));
    fittingAbsolute=floor(size(DATA,2)*fitting(3));
    [soV,in]=sort(V);
    if fittingAbsolute>size(in)
        ind=in;
    else
    ind=in(1:fittingAbsolute);
    end
    
end

if fitting(1)==7 % Colour + 3D distance
    % Color space is from 0 to 255, and distances model-data are in a
    % different range. changeRange function transform color range.
    dataColorNew(1,:) = changeRange(DATACOLOUR(1,:),0,255,min(min(DATATransformed,[],2)),max(max(DATATransformed,[],2)));
    dataColorNew(2,:) = changeRange(DATACOLOUR(2,:),0,255,min(min(DATATransformed,[],2)),max(max(DATATransformed,[],2)));
    dataColorNew(3,:) = changeRange(DATACOLOUR(3,:),0,255,min(min(DATATransformed,[],2)),max(max(DATATransformed,[],2)));
    
    modelColorNew(1,:) = changeRange(MODELCOLOUR(1,:),0,255,min(min(MODEL,[],2)),max(max(MODEL,[],2)));
    modelColorNew(2,:) = changeRange(MODELCOLOUR(2,:),0,255,min(min(MODEL,[],2)),max(max(MODEL,[],2)));
    modelColorNew(3,:) = changeRange(MODELCOLOUR(3,:),0,255,min(min(MODEL,[],2)),max(max(MODEL,[],2)));
    
    V=sqrt(sum(([DATATransformed;dataColorNew]-[MODEL;modelColorNew]).^2,1));
    distT=V;
    fittingAbsolute=floor(size(DATA,2)*fitting(2));
    [soV,in]=sort(V);
    ind=in(1:fittingAbsolute);
end

if fitting(1)==8 %  best fitting(2) Normals and Best fitting(2) points 
    normasModel=sqrt(MODELNORMALS(1,:).^2+MODELNORMALS(2,:).^2+MODELNORMALS(3,:).^2);
    normasData=sqrt(DATANORMALSTransformed(1,:).^2+DATANORMALSTransformed(2,:).^2+DATANORMALSTransformed(3,:).^2);
    normas=normasModel.*normasData;
    angles=ceil(acos(dot(DATANORMALSTransformed,MODELNORMALS)./normas)*180/pi);
    [soVAng,inAng]=sort(angles);
    fittingAng=floor(size(DATA,2)*fitting(2));
    ind = inAng(1:fittingAng);
%     

    V=sqrt(sum((DATATransformed(:,ind)-MODEL(:,ind)).^2,1));
    
    [soV,in]=sort(V);
    fittingAbsolute=floor(size(DATA(:,ind),2)*fitting(3));
    if fittingAbsolute>size(in)
        ind=in;
    else
        ind=in(1:fittingAbsolute);
    end
    
end

distS=V(ind);
dataS=DATA(:,ind);
modelS=MODEL(:,ind);
end