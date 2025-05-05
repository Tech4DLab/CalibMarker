classdef MyPointCloudClass

    properties
        Data
        Height
        Width
    end
    
    methods
        function obj = MyPointCloudClass(points, height, width)      
            if size(points,1) > size(points,2)
                obj.Data = points;
                obj.Height = height;
                obj.Width = width;
            else
                error('The input points should be in Nx3 matrix');
            end
        end
        
        function outputArg = readXYZ(obj)
            outputArg = obj.Data;
        end
    end
end

