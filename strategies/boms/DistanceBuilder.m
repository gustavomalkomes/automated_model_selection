classdef DistanceBuilder < handle
    %DistanceBuilder Build distance matrix between models
    
    properties
        hyperparameter_data_noise_samples;
        probability_samples;
        num_samples;
        max_num_hyperparameters;
        max_num_kernels;
    end
    
    properties (SetAccess = protected)
        average_distance;
    end
    
    methods
        function obj = DistanceBuilder(...
                noise_prior, ...
                num_samples, ...
                max_num_hyperparameters, ...
                max_num_kernels, ...
                active_models, ...
                initial_model_indices, ...
                data_X ...
                )
            obj.num_samples = num_samples;
            obj.max_num_hyperparameters = max_num_hyperparameters;
            obj.max_num_kernels = max_num_kernels;
            p = sobolset(obj.max_num_hyperparameters, ...
                'Skip',1e3, ...
                'Leap',1e2 ...
                );
            p = scramble(p,'MatousekAffineOwen');
            obj.probability_samples = net(p,num_samples);
            noise_samples = prior_sample( ...
                noise_prior, obj.probability_samples);
            obj.hyperparameter_data_noise_samples = exp(noise_samples);
            obj.average_distance = ...
                NaN(obj.max_num_kernels, obj.max_num_kernels);
            obj.average_distance(1:1+obj.max_num_kernels:end) = 0;
            
            obj.precompute_information(...
                active_models, initial_model_indices, data_X);            
        end
        
        function precompute_information(obj, active_models, ...
                new_candidates_indices, data_X)
            
            for i=new_candidates_indices
                covariance = active_models.models{i}.covariance;
                precomputed_info = obj.create_precomputed_info(...
                    covariance, data_X...
                    );
                active_models.models{i}.set_precomputed_info(...
                    precomputed_info...
                    );
            end
            
        end
        function update(obj, ...
                active_models, ...
                new_candidates_indices, ...
                all_candidates_indices, ...
                selected_indices, ...
                data_X)
            % UPDATE average distance between models
            %
            % First step is to precompute information for the new
            % candidate models
            obj.precompute_information(active_models, ...
                new_candidates_indices, data_X);
            
            % Second step is to compute the distance between
            % the trained models vs candidate models.
            new_evaluated_models = selected_indices(end);
            all_old_candidates_indices = ...
                setdiff(all_candidates_indices, new_candidates_indices);
            
            % i) new evaluated models vs all old candidates
            obj.compute_distance(active_models, ...
                new_evaluated_models, all_old_candidates_indices)
            
            % ii) new candidate models vs all trained models
            obj.compute_distance(active_models, ...
                selected_indices, new_candidates_indices)
        end
        
        function K = get_kernel(obj, index)
            K = obj.average_distance(1:index, 1:index);
        end
        
    end
    
    methods (Abstract)
        compute_distance(obj, active_models, indices_i, indices_j)
        create_precomputed_info(obj, covariance, data_X)
    end
    
end
