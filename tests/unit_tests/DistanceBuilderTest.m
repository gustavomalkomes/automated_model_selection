classdef DistanceBuilderTest < matlab.unittest.TestCase
    properties
        active_models
        candidates
        model_space
        noise_prior
        initial_model_indices
        data_X
        max_num_kernels = 20;
        max_num_hyperparameters = 10;
        num_samples = 10
        num_dimensions = 1;
    end
    
    methods
        function testCase = test_setUp(testCase)
            
            num_points = 20;
            
            base_kernels_names = {'SE', 'RQ', 'PER'};
            grammar = CovarianceGrammar(base_kernels_names, ...
                testCase.num_dimensions, []);
            base_kernels = grammar.base_kernels;
            first_expansion = grammar.expand(base_kernels{1});
            candidates_list = [base_kernels, first_expansion];
            
            testCase.model_space = grammar;
            testCase.candidates = candidates_list;
            testCase.active_models = ActiveModels(testCase.max_num_kernels);
            testCase.active_models.selected_indices = ...
                testCase.initial_model_indices;
            testCase.active_models.update(candidates_list);
            
            testCase.initial_model_indices = ...
                [1:testCase.active_models.size];
            
            testCase.data_X = randn(num_points, testCase.num_dimensions);
            
            hyperpriors = Hyperpriors();
            testCase.noise_prior = ...
                {hyperpriors.gaussian_prior('lik_noise_std')};
        end
        
        function update_test(testCase, builder)
            
            selected_index = ...
                randi(testCase.active_models.size-1, 1) + 1; % avoid one
            
            selected_model = testCase.active_models.models{selected_index};
            new_candidates = testCase.model_space.expand(...
                selected_model.covariance);
            new_candidates_indices = ...
                testCase.active_models.update(new_candidates);
            
            selected_indices = ...
                [testCase.active_models.selected_indices, selected_index];
            all_candidate_indices = 1:testCase.active_models.size;
            all_candidate_indices = ...
                setdiff(all_candidate_indices, selected_indices);
                        
            % update builder
            builder.update(testCase.active_models, ...
                new_candidates_indices, ...
                all_candidate_indices, ...
                selected_indices, ...
                testCase.data_X);
            
            % test matrix values
            
            computed_matrix_train_vs_all = builder.average_distance(...
                selected_indices, ...
                all_candidate_indices);
            
            testCase.assertFalse(...
                any(isnan(computed_matrix_train_vs_all(:)))...
                )

            computed_matrix_train_vs_all = builder.average_distance(...
                all_candidate_indices, ...
                selected_indices ...
                );
            
            testCase.assertFalse(...
                any(isnan(computed_matrix_train_vs_all(:)))...
                )
            
            computed_matrix_train_vs_train = builder.average_distance(...
                selected_indices, ...
                selected_indices);
            
            testCase.assertFalse(...
                any(isnan(computed_matrix_train_vs_train(:)))...
                )
            
        end
        
        function distance_builder_test(testCase, builder, className)
            
            testCase.assertClass(builder, className);
            testCase.assertEqual(builder.num_samples, ...
                testCase.num_samples);
            testCase.assertEqual(builder.max_num_hyperparameters, ...
                testCase.max_num_hyperparameters);
            testCase.assertEqual(builder.max_num_kernels, ...
                testCase.max_num_kernels);
            testCase.assertEqual(...
                size(builder.average_distance), ...
                [testCase.max_num_kernels, testCase.max_num_kernels]);
            testCase.assertEqual(size(builder.probability_samples), ...
                [testCase.num_samples, testCase.max_num_hyperparameters]);
            
        end
        function compute_distance_test(testCase, builder, distance_function)
            info = {};
            for i = 1:testCase.active_models.size
                covariance = testCase.active_models.models{i}.covariance;
                info{i} = builder.create_precomputed_info(covariance, testCase.data_X);
                testCase.active_models.models{i}.set_precomputed_info(info{i});
            end
            indices_i = [1,2,3];
            indices_j = [4,5,6];
            builder.compute_distance(...
                testCase.active_models, indices_i, indices_j ...
                )
            for i = indices_i
                for j = indices_j
                    distance = distance_function(info{i}, info{j});
                    testCase.assertEqual(builder.average_distance(i,j), ...
                        distance);
                end
            end
        end

    end
end
