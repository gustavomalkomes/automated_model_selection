classdef KernelKernelGPModel < GpModel
    %KERNELKERNELBUILDER Summary of this class goes here
    %   Detailed explanation goes here
  
    methods
        function obj = KernelKernelGPModel(kernel_kernel_hyperpriors)
                        
            % Define covariance 
            name = 'KernelKernel';
            is_base = false;
            rnd_code = [0 0 0];
            function_handle = {};
            covariance_priors = {
                kernel_kernel_hyperpriors.gaussian_prior('length_scale'), ...
                kernel_kernel_hyperpriors.gaussian_prior('output_scale'), ...
                };
            covariance = Covariance(name, is_base, rnd_code, ...
                function_handle, covariance_priors);
            
            % Super class constructor
            obj@GpModel(covariance, kernel_kernel_hyperpriors);  
            
        end
        
        function obj = set_kernel_kernel(obj, K)
            fixed_distance_SEiso_covariance(K);
            obj.covariance_function  = ...
                {@fixed_distance_SEiso_covariance, []};
        end        
    end
    
end

