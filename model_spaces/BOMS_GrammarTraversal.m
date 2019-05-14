classdef BOMS_GrammarTraversal < CovarianceGrammar
    properties
        random_walk_geometric_dist_parameter = 1/3;
        number_of_top_k_best = 3;
        number_of_random_walks = 15;
    end
    methods
        % Constructor
        function obj = BOMS_GrammarTraversal(...
                base_kernels_names, ...
                dimension, ...
                hyperprior...
                )
            obj@CovarianceGrammar(base_kernels_names, ...
                dimension, ...
                hyperprior...
                );
        end
        
        function candidates = get_candidates(obj, ...
                selected_models, ...
                fitness_score...
                )
            
            % exploration
            total_num_walks = obj.number_of_random_walks;
            candidates_random = obj.expand_random(total_num_walks);
            
            % exploitation
            candidates_best = ...
                obj.expand_best( ...
                selected_models, ...
                fitness_score...
                );
            
            % concatenate
            candidates = [candidates_best, candidates_random];
        end
        
        function new_kernels = expand_random(obj, total_num_walks)
            parameter = obj.random_walk_geometric_dist_parameter;
            new_kernels = cell(1,total_num_walks);
            for i=1:total_num_walks
                fronteir = obj.base_kernels(:);
                depth = geornd(parameter);
                while depth >= 0
                    random_index = randi(numel(fronteir));
                    new_kernel = fronteir{random_index};
                    fronteir = obj.expand(new_kernel);
                    depth = depth - 1;
                end
                new_kernels{i} = new_kernel;
            end
        end
        
        function new_kernels = expand_best(obj, ...
                selected_models, ...
                fitness_score...
                )
            new_kernels = [];
            num_exploit_top = obj.number_of_top_k_best;
            if numel(fitness_score) < 2
                return
            end
            [~, indices] = sort(fitness_score, 'descend');
            last_index = min(num_exploit_top, numel(fitness_score));
            indices = indices(1:last_index);

            models_with_highest_score = selected_models(indices);
            for i=1:numel(models_with_highest_score)
                kernel_to_expand = models_with_highest_score(i).covariance;
                new_kernel_list = obj.expand(kernel_to_expand);
                new_kernels = [new_kernels, new_kernel_list];
            end
        end
        
    end
end

