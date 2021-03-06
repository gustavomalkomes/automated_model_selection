classdef BayesianOptimizationStrategyTest < matlab.unittest.TestCase
    
    properties
        problems
    end
    
    properties (TestParameter)
        options = {'small_oneD' ...
            'larger_oneD', ...
            'small_multiD' ...
            'larger_multiD' ...
            };
    end
    
    methods(TestMethodSetup)
        function setUp(testCase)
            rng(0);
            
            max_num_hyperparameters = 20;
            num_samples = 5;
            
            num_points = 20;
            num_dimensions = 1;
            base_kernels_names = {'SE', 'RQ', 'PER'};
            max_num_kernels = 100;
            
            [boms_strategy, data_X, grammar] = ...
                BayesianOptimizationStrategyTest.create_boms(...
                num_points, num_dimensions, base_kernels_names, ...
                max_num_kernels, max_num_hyperparameters, num_samples);
            
            testCase.problems.small_oneD.verbose = 0;
            testCase.problems.small_oneD.hyperpriors_lowlevel = Hyperpriors();
            testCase.problems.small_oneD.max_num_kernels = max_num_kernels;
            testCase.problems.small_oneD.boms = boms_strategy;
            testCase.problems.small_oneD.data_X = data_X;
            testCase.problems.small_oneD.grammar = grammar;
            
            num_points = 30;
            num_dimensions = 1;
            base_kernels_names = {'SE', 'RQ', 'LIN', 'M1'};
            max_num_kernels = 200;
            
            [boms_strategy, data_X, grammar] = ...
                BayesianOptimizationStrategyTest.create_boms(...
                num_points, num_dimensions, base_kernels_names, ...
                max_num_kernels, max_num_hyperparameters, num_samples);
            
            testCase.problems.larger_oneD.verbose = 0;
            testCase.problems.larger_oneD.hyperpriors_lowlevel = Hyperpriors();
            testCase.problems.larger_oneD.max_num_kernels = max_num_kernels;
            testCase.problems.larger_oneD.boms = boms_strategy;
            testCase.problems.larger_oneD.data_X = data_X;
            testCase.problems.larger_oneD.grammar = grammar;
            
            
            num_points = 15;
            num_dimensions = 3;
            base_kernels_names = {'SE'};
            max_num_kernels = 200;
            
            [boms_strategy, data_X, grammar] = ...
                BayesianOptimizationStrategyTest.create_boms(...
                num_points, num_dimensions, base_kernels_names, ...
                max_num_kernels, max_num_hyperparameters, num_samples);
            
            testCase.problems.small_multiD.verbose = 0;
            testCase.problems.small_multiD.hyperpriors_lowlevel = Hyperpriors();
            testCase.problems.small_multiD.max_num_kernels = max_num_kernels;
            testCase.problems.small_multiD.boms = boms_strategy;
            testCase.problems.small_multiD.data_X = data_X;
            testCase.problems.small_multiD.grammar = grammar;
            
            num_points = 30;
            num_dimensions = 5;
            base_kernels_names = {'SE', 'RQ'};
            max_num_kernels = 500;
            
            [boms_strategy, data_X, grammar] = ...
                BayesianOptimizationStrategyTest.create_boms(...
                num_points, num_dimensions, base_kernels_names, ...
                max_num_kernels, max_num_hyperparameters, num_samples);
            
            testCase.problems.larger_multiD.verbose = 0;
            testCase.problems.larger_multiD.hyperpriors_lowlevel = Hyperpriors();
            testCase.problems.larger_multiD.max_num_kernels = max_num_kernels;
            testCase.problems.larger_multiD.boms = boms_strategy;
            testCase.problems.larger_multiD.data_X = data_X;
            testCase.problems.larger_multiD.grammar = grammar;
            
        end
    end
    methods (Test)
        function test_create(testCase, options)
            
            problem = ...
                getfield(testCase.problems, options);
            boms_strategy = problem.boms;
            
            testCase.assertClass(boms_strategy.active_models, ...
                'ActiveModels');
            testCase.assertClass(boms_strategy.kernel_builder, ...
                'HellingerDistanceBuilder');
            testCase.assertClass(boms_strategy.model, ...
                'KernelKernelGPModel');
            testCase.assertEqual(boms_strategy.acquisition_function, ...
                @expected_improvement);
            
            for i=1:boms_strategy.active_models.size
                testCase.assertNotEmpty( ...
                    boms_strategy.active_models.models{i}.info ...
                    )
            end
            
        end
        
        function test_query_empty_candidates(testCase, options)
            
            problem = ...
                getfield(testCase.problems, options);
            boms_strategy = problem.boms;
            
            problem.boms.active_models.selected_indices = [1];
            
            candidate_models = [];
            selected_models = [];
            fitness_score = [0.5];
            
            % first call
            next_model = boms_strategy.query(problem, ...
                selected_models, ...
                fitness_score, ...
                candidate_models);
            
            [~,~, id] = ...
                boms_strategy.active_models.get_model_by_covariance(...
                next_model.covariance ...
                );
            
            testCase.assertEqual( ...
                boms_strategy.active_models.selected_indices, ...
                [1, id]);
            
            for i = 1:3

                fitness_score = [fitness_score, rand()];
                next_model = boms_strategy.query(problem, ...
                    selected_models, ...
                    fitness_score, ...
                    candidate_models);
                
                [~,~, id] = ...
                    boms_strategy.active_models.get_model_by_covariance(...
                    next_model.covariance ...
                    );
                
                
                testCase.assertEqual( ...
                    boms_strategy.active_models.selected_indices(end), ...
                    id);
            end
            
        end
        
        function test_query_duplicate_candidates(testCase, options)
            problem = ...
                getfield(testCase.problems, options);
            boms_strategy = problem.boms;
            grammar = problem.grammar;
            problem.boms.active_models.selected_indices = [1];
            
            max_num_kernels = problem.max_num_kernels;
            
            level = 2;
            total_candidates = grammar.full_expand(level+1, ...
                max_num_kernels + 20);
            
            % adding no more than the total maximum of candidates
            candidate_models = total_candidates(1:max_num_kernels);
            selected_models = [];
            fitness_score = [0.5];
            
            next_model = boms_strategy.query(problem, ...
                selected_models, ...
                fitness_score, ...
                candidate_models);
            
            [~,~, id] = ...
                boms_strategy.active_models.get_model_by_covariance(...
                next_model.covariance ...
                );
            
            testCase.assertEqual( ...
                boms_strategy.active_models.size, ...
                max_num_kernels);
            
            testCase.assertEqual( ...
                boms_strategy.active_models.selected_indices, ...
                [1, id]);
            
            testCase.assertNotEmpty( ...
                boms_strategy.active_models.remove_priority)
            
            testCase.assertEqual( ...
                numel(boms_strategy.active_models.remove_priority), ...
                max_num_kernels - 2);
            
            remove_priority = boms_strategy.active_models.remove_priority;
            
            % adding more than the number of candidates
            candidate_models = total_candidates(1:max_num_kernels+10);
            
            fitness_score = [0.5, 0.9];
            next_model = boms_strategy.query(problem, ...
                selected_models, ...
                fitness_score, ...
                candidate_models);
            
            [~,~, id] = ...
                boms_strategy.active_models.get_model_by_covariance(...
                next_model.covariance ...
                );
            
            testCase.assertEqual( ...
                boms_strategy.active_models.selected_indices(end), ...
                id);
            
            removed_indices = remove_priority(1:10);
            index = max_num_kernels + 1;
            for i = removed_indices
                testCase.assertEqual(...
                    boms_strategy.active_models.models{i}.covariance, ...
                    candidate_models{index});
                index = index + 1;
            end
            
            % adding new covariances
            remove_priority = boms_strategy.active_models.remove_priority;
            candidate_models = total_candidates(max_num_kernels+15:end);
            
            fitness_score = [0.5, 0.9, 0.2];
            next_model = boms_strategy.query(problem, ...
                selected_models, ...
                fitness_score, ...
                candidate_models);
            
            [~,~, id] = ...
                boms_strategy.active_models.get_model_by_covariance(...
                next_model.covariance ...
                );
            
            testCase.assertEqual(...
                boms_strategy.active_models.selected_indices(end), ...
                id);
            
            removed_indices = remove_priority(1:numel(candidate_models));
            index = 1;
            for i = removed_indices
                testCase.assertEqual(...
                    boms_strategy.active_models.models{i}.covariance, ...
                    candidate_models{index});
                index = index + 1;
            end
            
            % adding everyone
            candidate_models = total_candidates(1:end);
            
            fitness_score = [0.5, 0.9, 0.2, 0.39];
            next_model = boms_strategy.query(problem, ...
                selected_models, ...
                fitness_score, ...
                candidate_models);
            
            [~,~, id] = ...
                boms_strategy.active_models.get_model_by_covariance(...
                next_model.covariance ...
                );
            
            testCase.assertEqual(...
                boms_strategy.active_models.selected_indices(end), ...
                id);
            
            id_list = [];
            for candidate = candidate_models
                [~, ~, id] = ...
                    boms_strategy.active_models.get_model_by_covariance(candidate{:});
                id_list = [id_list, id];
            end
            
            testCase.assertEqual(sum(isnan(id_list)), 20); % extra number of kernels
            testCase.assertEqual(sum(~isnan(id_list)), max_num_kernels);
        end
    end
    
    methods (Static)
        function [boms_strategy, data_X, grammar] = create_boms(...
                num_points, num_dimensions, base_kernels_names, ...
                max_num_kernels, max_num_hyperparameters, num_samples)
            
            data_X = randn(num_points, num_dimensions);
            hyperpriors = Hyperpriors(); % shared hyperprior for simplicity
            
            grammar = BOMS_GrammarTraversal(...
                base_kernels_names, ...
                num_dimensions, ...
                hyperpriors...
                );
            
            level = 2;
            max_models = max_num_kernels;
            initial_candidates = grammar.full_expand(level, max_models);
            
            active_models = ActiveModels(max_num_kernels);
            initial_candidate_indices = ...
                active_models.update(initial_candidates);
            
            no_duplicates = numel(initial_candidate_indices) ...
                == numel(initial_candidates);
            assert(no_duplicates);
            
            acquisition_function = @expected_improvement;
            
            noise_prior = ...
                {hyperpriors.gaussian_prior('lik_noise_std')};
            
            kernel_builder = HellingerDistanceBuilder(...
                noise_prior, ...
                num_samples, ...
                max_num_hyperparameters, ...
                max_num_kernels, ...
                active_models, ...
                initial_candidate_indices, ...
                data_X ...
                );
            
            tracker = SimpleTracker();
            
            boms_strategy = BayesianOptimizationStrategy(...
                active_models, ...
                acquisition_function, ...
                kernel_builder, ...
                hyperpriors, ...
                tracker);
            
            boms_strategy.model.optimization_options.display = 0;
            
        end
    end
end

