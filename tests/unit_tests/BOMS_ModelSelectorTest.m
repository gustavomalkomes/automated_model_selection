classdef BOMS_ModelSelectorTest < matlab.unittest.TestCase
    methods (Test)
        
        function test_create_error(testCase)

            fitness_score = @log_evidence_fitness_function;            
            callback = [];
            
            problem = [];
            problem.num_dimensions = 1;
            testCase.assertError(...
                @()BOMS_ModelSelector(problem, fitness_score, callback), ...
                'BOMS:BOMS_ModelSelector:input_error')
            
            problem = [];            
            problem.data_X = randn(10,5);
            testCase.assertError(...
                @()BOMS_ModelSelector(problem, fitness_score, callback), ...
                'BOMS:BOMS_ModelSelector:input_error')
            
            problem = [];            
            problem.base_kernels_names = {'SE', 'RQ', 'PER'};
            testCase.assertError(...
                @()BOMS_ModelSelector(problem, fitness_score, callback), ...
                'BOMS:BOMS_ModelSelector:input_error')
        end

        
        function test_create_one_d(testCase)

            num_points = 20;
            problem.num_dimensions = 1;
            problem.base_kernels_names = {'SE', 'RQ', 'PER'};
            problem.data_X = randn(num_points, problem.num_dimensions);
            
            fitness_score = @log_evidence_fitness_function;
            
            callback = [];
            boms = BOMS_ModelSelector(problem, fitness_score, callback);
            
            for i = 1:boms.strategy.active_models.size
                testCase.assertNotEmpty( ...
                    boms.strategy.active_models.models{i}.info ...
                    )
            end
        end

        function test_run_one_d(testCase)
            num_points = 300;
            num_dimensions = 2;
            budget = 5;
            
            rng(0);
            
            X = randn(num_points, num_dimensions);
            w = randn(num_dimensions, 1);
            y = X*w;
            indices = randperm(num_points, 10);

            problem.num_dimensions = num_dimensions;
            problem.base_kernels_names = {'SE'};
            problem.data_X = X(indices, :);
            
            problem.budget = budget;
            problem.verbose = 0;
            problem.X = X;
            problem.y = y; 
            fitness_score = @evidence_fitness_function;
            
            callback = [];
            boms = BOMS_ModelSelector(problem, fitness_score, callback);
            [selected_models, fitness_scores, time] = boms.run();
            
            testCase.assertEqual(numel(selected_models), budget + 1)
            testCase.assertEqual(numel(fitness_scores), budget + 1)
            testCase.assertNotEmpty(time);
        end
              
    end
end