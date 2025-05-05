function [points, rgb, depth] = getDataFromFiles(path,snCams, numCams, FramesToProcess,factorFocal,rawData)
   
    colorFilesName = 'serial-Color-*.png';
    depthFilesName = 'serial-Depth-*.txt';
    pointcloudFilesName = 'serial-PointCloud-*.pcd';
    
     
    if nargin == 1        
        snCams = {'733512070455', '829212072262', '831612070293',  '829212071391'};
        numCams = size(snCams,2);
        
        a = dir( strcat(path, strrep(colorFilesName,'serial', snCams{1})));
        n = numel(a); 
        FramesToProcess = 1:n;
    elseif nargin == 2 
        numCams = size(snCams,2);
        
       	a = dir( strcat(path, strrep(colorFilesName,'serial', snCams{1})));
        n = numel(a);       
        FramesToProcess = 1:n;
    elseif nargin == 3
        a = dir( strcat(path, strrep(colorFilesName,'serial', snCams{1})));
        n = numel(a);       
        FramesToProcess = 1:n;
    end
    
    if nargin==6 && rawData
        pointcloudFilesName = 'serial-RAWPointCloud-*.pcd';
    end

    i=1;
    readFiles = true;
    disp(['Reading files directory:',path,'...']);
    
    points = {};
    rgb = {};
    depth = {};
    
    for k = 1:numCams
       points{1,k} = {};
       rgb{1,k} = {};
       depth{1,k} = {};
    end
    
    if path(end) ~= '/'
        path = strcat(path, '/');
    end

    
    for i = FramesToProcess
          
        for k = 1:numCams
            
            % Color
            colorFile = strcat( path, strrep(strrep(colorFilesName, '*', int2str(i)), 'serial', snCams{k}));
            if(exist(colorFile, 'file'))
                rgb{1,k}{i,1} = rosmessage('sensor_msgs/Image');
                rgb{1,k}{i,1}.Encoding = 'RGB8';
                writeImage(rgb{1,k}{i,1}, imread(colorFile));
            else
                rgb{1,k}{i,1} = [];
            end
            
           
            
            
            % Point Cloud
            pcFile = strcat( path, strrep(strrep(pointcloudFilesName, '*', int2str(i)), 'serial', snCams{k}));
            if(exist(pcFile, 'file'))
                ptCloud=pcread(pcFile);
                %pXYZor=permute(ptCloud.Location,[2 1 3]); 
                pXYZor=ptCloud.Location;
                pXYZ=reshape(pXYZor,ptCloud.Count,3);
             %   if size(factorFocal,1)>
            % centAnt=nanmedian(pXYZ);
                    pXYZ(:,1)=pXYZ(:,1).*factorFocal(k,1);
                    pXYZ(:,2)=pXYZ(:,2).*factorFocal(k,2);
                    pXYZ(:,3)=pXYZ(:,3).*factorFocal(k,3);
              %      centPost=nanmedian(pXYZ);          
              %          pXYZ=pXYZ-(centPost-centAnt);
             %   end
                points{1,k}{i,1} = MyPointCloudClass(pXYZ, size(pXYZor,2), size(pXYZor,1));
            else % ply
                pcFile = strrep(pcFile, 'pcd', 'ply');
                if(exist(pcFile, 'file'))
                     ptCloud=pcread(pcFile);
                    %pXYZor=permute(ptCloud.Location,[2 1 3]); 
                    pXYZor=ptCloud.Location;
                    pXYZ=reshape(pXYZor,ptCloud.Count,3);
              %      if size(factorFocal,1)>1
               %         centAnt=median(pXYZ);          
                        pXYZ(:,1)=pXYZ(:,1).*factorFocal(k,1);
                        pXYZ(:,2)=pXYZ(:,2).*factorFocal(k,2);
                        pXYZ(:,3)=pXYZ(:,3).*factorFocal(k,3);
                %        centPost=median(pXYZ);          
                %        pXYZ=pXYZ-(centPost-centAnt);
               %     end
                    points{1,k}{i,1} = MyPointCloudClass(pXYZ, size(pXYZor,2), size(pXYZor,1));
                 else
                    
                    points{1,k}{i,1} = []; 
                end
            end
            
             % Depth
            depthFile = strcat( path, strrep(strrep(depthFilesName, '*', int2str(i)), 'serial', snCams{k}));
            if(exist(depthFile, 'file'))
                depth{1,k}{i,1} = rosmessage('sensor_msgs/Image');
                depth{1,k}{i,1}.Encoding = '16UC1';
                writeImage(depth{1,k}{i,1}, uint16(vec2mat(dlmread(depthFile,' ',1,0), 1280)*1000));
            else
                depth{1,k}{i,1} = rosmessage('sensor_msgs/Image');
                depth{1,k}{i,1}.Encoding = '16UC1';
               % pXYZor=permute(ptCloud.Location,[2 1 3]);    
              pXYZor=ptCloud.Location;
              if size(size(ptCloud.Location),2)==2 % Viene de ply
                writeImage(depth{1,k}{i,1}, uint16(ptCloud.Location(:,3)*1000));
              else
                writeImage(depth{1,k}{i,1}, uint16(ptCloud.Location(:,:,3)*1000));
              end
            end
        end
        
        i = i + 1;
    end
end

