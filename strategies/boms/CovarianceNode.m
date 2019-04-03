classdef CovarianceNode < handle
    properties
        id;
        covariance;
        info; % precomputed information for this node
    end    
    
    methods
        function obj = CovarianceNode(id, ...
                covariance ...
                )
            obj.id = id;
            obj.covariance = covariance;
        end
        
        function set_precomputed_info(obj, info)
            obj.info = info;
        end
    end
    
end

