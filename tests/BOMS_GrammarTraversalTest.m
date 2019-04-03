classdef BOMS_GrammarTraversalTest < matlab.unittest.TestCase
    
    methods (Test)
        function test_create(testCase)
            base_kernels_names = {'SE', 'RQ'};
            dimension = 1;
            
            % no arguments
            grammar = BOMS_GrammarTraversal(base_kernels_names, dimension, []);
            testCase.assertEqual(base_kernels_names, grammar.base_kernels_names)
            testCase.assertEqual(dimension, grammar.dimension)
            testCase.assertNotEmpty(grammar.hyperpriors)
                        
            testCase.assertNotEmpty(grammar.random_walk_geometric_dist_parameter)
            testCase.assertNotEmpty(grammar.number_of_top_k_best)
            testCase.assertNotEmpty(grammar.number_of_random_walks)
        end
        
        function test_get_candidates_empty(testCase)
            base_kernels_names = {'SE', 'RQ'};
            dimension = 1;
            
            % no arguments
            grammar = BOMS_GrammarTraversal(...
                base_kernels_names, dimension, [] ...
                );
            
            seed = randi(100);
            rng(seed);
            candidates = grammar.get_candidates([], []);
            
            rng(seed);
            total_num_walks = grammar.number_of_random_walks;
            expected_candidates = grammar.expand_random(total_num_walks);
                        
            testCase.assertEqual(numel(candidates), numel(expected_candidates));
            for i=1:numel(expected_candidates)
                testCase.assertEqual(candidates{i}.name, ...
                    expected_candidates{i}.name);
            end
        end
        
        
        function test_get_candidates(testCase)
            base_kernels_names = {'SE', 'RQ'};
            dimension = 1;
            
            grammar = BOMS_GrammarTraversal(...
                base_kernels_names, dimension, [] ...
                );
            
            grammar.number_of_top_k_best = 1;
            num_random_walks = 5;            
            kernels = grammar.expand_random(num_random_walks);
            fitness_score = randperm(numel(kernels));
            
            hyperprior = Hyperpriors();
            for i=1:numel(kernels)
                covariance = kernels{i};
                models(i) = GpModel(covariance, hyperprior);
            end
            
            candidates = grammar.get_candidates(models, fitness_score);
            for candidate = candidates
                testCase.assertClass(candidate{:}, 'Covariance');
            end
            
        end        
        
        function test_expand_random(testCase)
            base_kernels_names = {'SE', 'RQ'};
            dimension = 1;
            num_random_walks = 5;
            
            grammar = BOMS_GrammarTraversal(...
                base_kernels_names, dimension, [] ...
                );
            
            grammar.random_walk_geometric_dist_parameter = 1/3;
            num_random_walks = 1;
            rng(0); % depth is 0 (serendipity)
            new_kernels = grammar.expand_random(num_random_walks);
            testCase.assertEqual(numel(new_kernels), num_random_walks);
            testCase.assertTrue(new_kernels{1}.is_base); % depth is 0
            
            rng(2); % depth is 2
            num_random_walks = 5;
            new_kernels = grammar.expand_random(num_random_walks);
            testCase.assertEqual(numel(new_kernels), num_random_walks);
        end
        
       function test_expand_best(testCase)
            base_kernels_names = {'SE', 'RQ'};
            dimension = 1;
            num_random_walks = 5;
            
            rng(0);
            grammar = BOMS_GrammarTraversal(...
                base_kernels_names, dimension, [] ...
                );
            
            grammar.number_of_top_k_best = 1;
            num_random_walks = 5;            
            kernels = grammar.expand_random(num_random_walks);
            fitness_score = randperm(numel(kernels));
            
            [~, index] = max(fitness_score);
            kernel_to_expand = kernels{index};
            
            hyperprior = Hyperpriors();
            for i=1:numel(kernels)
                covariance = kernels{i};
                models(i) = GpModel(covariance, hyperprior);
            end
            
            new_kernels = grammar.expand_best(models, fitness_score);

            expanded_kernels = grammar.expand(kernel_to_expand);
            for i=1:numel(expanded_kernels)
                testCase.assertEqual(new_kernels{i}, expanded_kernels{i});
            end
       end
        
    end
    
end

