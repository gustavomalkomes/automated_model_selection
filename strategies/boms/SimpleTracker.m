classdef SimpleTracker < handle

    properties
    end
    
    methods
        function callback(obj, boms_strategy, problem, candidate_models, ...
                selected_models, fitness_scores, ...
                new_candidates_indices, K, all_candidate_indices, ...
                x_train, y_train, acquisition_function_values, ...
                next_model_index)
            
            index = next_model_index;
            name = boms_strategy.active_models.models{index}.covariance.name;
            acq = max(acquisition_function_values);
            if problem.verbose && problem.verbose > 0
                fprintf('Next model model %d %s %f\n', index, name, acq)
            end
            
        end
    end
    
end

