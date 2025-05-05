% Adapted from msaval
% We have to decide if use different color for faces...

function [SegmentedPoints, SegmentedRGB, SegmentedDepth, Indices,imgOut] = segmentationCubeCalibration(PointsIn, RGB, DepthIn, HSVTh, distanceTh)
    imgOut=[];
    % plotting for debug
    Plotting = 0;

    % Color thresholds for segmentation M3x2; First row min values, second
    % row max values
    if( nargin == 3)
  %      HSVTh = [0.32 0.3 0.3; 0.42 1 1]; % Sphere
   %     HSVTh = [0.20 0.23 0.3; 0.46 1 1]; % Cube iluminaciona anterior
        %HSVTh = [0.20 0.13 0.2; 0.4 1 1]; % Cube
        %HSVTh = [0.1 0.05 0; 0.4 0.8 0.8]; % Cube -> Falla Numkinect 7
        %HSVTh = [0.28 0.2 0.1; 0.4 0.65 0.87]; %Cubo anterior
         HSVTh = [0.28 0.50 0.2; 0.4 1 1]; %Cubo nuevo
         HSVTh = [0.28 0.35 0.2; 0.45 1 1]; %Cubo nuevo
         %HSVTh = [0.43 0.35 0.2; 0.51 1 1]; %Cubo Intrinseco R4
         %HSVTh = [0 0 0; 1 1 1]; %Cubo nuevo
        distanceTh = 1500; %(mm) 
%       HSVTh = [0.32 0.3 0.3; 0.42 1 1];
    end
    
    
    for NumKinect = 1:size(RGB,2)
        Maskcase = size(size(RGB,2),size(RGB{1},1));
        MaxFrames = size(RGB{1},1);

 %       NumKinect
 
        for NumFrame = 1:MaxFrames
     %       NumFrame
            Image = RGB{NumKinect}{NumFrame};
            Depth = DepthIn{NumKinect}{NumFrame};
            ImAux = Image.readImage;
            DepthAux = Depth.readImage;
            Points = PointsIn{NumKinect}{NumFrame};
            PointsAux = Points.readXYZ;

            HSV = rgb2hsv(ImAux);

            MaskH = (HSV(:,:,1) >= HSVTh(1,1) & HSV(:,:,1) <= HSVTh(2,1));
            MaskS = (HSV(:,:,2) >= HSVTh(1,2) & HSV(:,:,2) <= HSVTh(2,2));

            MaskPre = MaskH & MaskS;

              % remove distant points
             depthMask = DepthAux;
             depthMask(depthMask > distanceTh) = 0;
             DepthAux=depthMask;
       %      Mask(depthMask == 0) = 0;
             MaskPre = MaskH & MaskS & depthMask;
             
             
             %imagesc(MaskPre)
             
            % extracting largest area/blob
            [LabelImage, ~] = bwlabel(MaskPre);
            props = regionprops(LabelImage, 'Area','Centroid');
            cellprops = struct2cell(props);
            centPos = cat(1,cellprops{2,:});
            if size(centPos,1)==0
                centDepth=[1];
            else
%             NumFrame
%             NumKinect
                centDepth = DepthAux(sub2ind(size(DepthAux),floor(centPos(:,2)),floor(centPos(:,1))));
            end
            validArea = find([props.Area] > (mean([props.Area]) +  (std([props.Area]))));
            if size(validArea,2)<= 10 % Solo 2 blob  # cambiar si va mal
               [~, validArea] = max([props.Area]); % El mas grande
            end    
            [~, indMinDepth] = min(centDepth(validArea));
            
            IndBall = validArea(indMinDepth);
            
            %[~, IndMaxArea] = max([props.Area]);
            Mask = false(size(MaskPre));
%             NumKinect
%             NumFrame
            if size(centPos,1)~=0
                Mask(LabelImage == IndBall) = true;
            end

            % remove boundaries
            BW2 = bwperim(Mask);
            Mask(BW2) = false;
            
          
            
            % apply segmentation to RGB channels 
            aa = ImAux(:,:,1);
            aa(~Mask) = nan;      
            SegmentedRGB{NumKinect}(:,:,1,NumFrame) = aa;
            aa = ImAux(:,:,2);
            aa(~Mask) = nan;      
             SegmentedRGB{NumKinect}(:,:,2,NumFrame) = aa;        
            aa = ImAux(:,:,3);
            aa(~Mask) = nan;      
            SegmentedRGB{NumKinect}(:,:,3,NumFrame) = aa;

            % apply segmentation to depth
            dd = DepthAux;
            dd(~Mask) = nan;
            SegmentedDepth{NumKinect}(:,:,NumFrame) = dd;

            % apply segmentation to point cloud
            ind = (Mask == 1);
            %ind = ind(:) & ~isnan(PointsAux(:,1));
            Indices{NumKinect}{NumFrame} = ind(:)';
            SegmentedPoints{NumKinect}{NumFrame} = PointsAux(ind,:);

            aa = ImAux(:,:,1);
            aa(~Mask) = aa(~Mask)*0.5;      
            imgOut{NumKinect}(:,:,1,NumFrame) = aa;
            aa = ImAux(:,:,2);
            aa(~Mask) = aa(~Mask)*0.5;      
             imgOut{NumKinect}(:,:,2,NumFrame) = aa;        
            aa = ImAux(:,:,3);
            aa(~Mask) = aa(~Mask)*0.5;      
            imgOut{NumKinect}(:,:,3,NumFrame) = aa;
            if Plotting
                   
                figure('Name',sprintf('Comparison Kinect %d Frame %d', NumKinect, NumFrame)); 
                subplot(1,3,1); imshow(ImAux); title('Original Image');
                subplot(1,3,2); imshow(SegmentedRGB{NumKinect}(:,:,:,NumFrame)); title('Segmented Image');
                subplot(1,3,3); imagesc(SegmentedDepth{NumKinect}(:,:,NumFrame)); axis image; axis off; title('Depth Image');
                figure('Name',sprintf('Points Kinect %d  Frame %d', NumKinect, NumFrame));pcshow(pointCloud(PointsAux(ind,:)));

            end
        end
    end

end