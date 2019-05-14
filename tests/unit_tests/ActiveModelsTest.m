classdef ActiveModelsTest < matlab.unittest.TestCase
    properties
        candidates
        expected_candidates
        expected_status
    end
    
    properties (TestParameter)
        candidate_options = {'small', 'repeated', 'multi'};
        active_set_options = {'empty', 'collision'};
    end
    
    methods(TestMethodSetup)
        function setUp(testCase)
            base_kernels_names = {'SE', 'RQ', 'M1'};
            dimension = 1;
            grammar = CovarianceGrammar(base_kernels_names, dimension, []);
            base_kernels = grammar.base_kernels;
            first_expansion = grammar.expand(base_kernels{1});
            second_expansion = grammar.expand(base_kernels{2});
            
            candidate_list = [base_kernels, first_expansion];
            testCase.candidates.small = candidate_list;
            testCase.expected_candidates.small = candidate_list;
            testCase.expected_status.small = ...
                true(numel(candidate_list),1);
            
            candidate_list = [base_kernels, first_expansion, second_expansion];
            testCase.candidates.repeated = candidate_list;
            testCase.expected_candidates.repeated = ...
                [base_kernels, first_expansion, second_expansion(3:end)];
            testCase.expected_status.repeated = ...
                true(numel(candidate_list),1);
            testCase.expected_status.repeated(10:11) = false;
            
            base_kernels_names = {'SE', 'RQ', 'M1'};
            dimension = 3;
            grammar = CovarianceGrammar(base_kernels_names, dimension, []);
            base_kernels = grammar.base_kernels;
            first_expansion = grammar.expand(base_kernels{1});
            
            candidate_list = [base_kernels, first_expansion, first_expansion];
            testCase.candidates.multi = candidate_list;
            testCase.expected_candidates.multi = ...
                [base_kernels, first_expansion];
            testCase.expected_status.multi = false(numel(candidate_list),1);
            indices = 1:(numel(base_kernels)+numel(first_expansion));
            testCase.expected_status.multi(indices) = true;
        end
    end
    
    methods (Test)
        function test_create_active_models(testCase)
            max_number = 100;
            active_models = ActiveModels(max_number);
            
            testCase.assertEmpty(active_models.remove_priority);
            testCase.assertEqual(active_models.size, 0);
            testCase.assertEqual(active_models.visited_models.Count, uint64(0));
            testCase.assertEqual(numel(active_models.models), max_number);
        end
        
        function test_update(testCase, candidate_options)
            candidates_list = ...
                getfield(testCase.candidates, candidate_options);
            expected_candidates_list = ...
                getfield(testCase.expected_candidates, candidate_options);            

            max_number = 50;
            active_models = ActiveModels(max_number);
            expected_total = numel(expected_candidates_list);
            expected_indices = 1:expected_total;
            indices = active_models.update(candidates_list);
            testCase.assertEqual(indices, expected_indices);
            
            for i=1:expected_total
                candidate = expected_candidates_list{i};
                covariance = active_models.models{i}.covariance;
                testCase.assertEqual(covariance, candidate);
            end
        end
        function testGetIndexToInsert(testCase)
            max_number = 5;
            active_models = ActiveModels(max_number);
            for i = 1:max_number
                index = active_models.get_index_to_insert();
                testCase.assertEqual(index, i)
                % mock increment
                active_models.size = active_models.size + 1;
            end
            
            verifyError(testCase, ...
                @() active_models.get_index_to_insert(), ...
                'BOMS:ActiveModels:not_removal_index');
            
            active_models.remove_priority = [9,3,5];
            for i = [9,3,5]
                index = active_models.get_index_to_insert();
                testCase.assertEqual(index, i)
            end
        end
        
        function test_add_model(testCase, candidate_options)
            max_number = 50;
            active_models = ActiveModels(max_number);
            candidates_list = ...
                getfield(testCase.candidates, candidate_options);
            expected_candidates_list = ...
                getfield(testCase.expected_candidates, candidate_options);
            expected_status_list = ...
                getfield(testCase.expected_status, candidate_options);
            
            expected_id = 1;
            for i=1:numel(candidates_list)
                candidate = candidates_list{i};
                [id, status] = active_models.add_model(candidate);
                expected = expected_status_list(i);
                testCase.assertEqual(status, expected);
                if status
                    testCase.assertEqual(id, expected_id);
                    expected_id = expected_id + 1;
                end
            end
            
            for i=1:numel(expected_candidates_list)
                expected = expected_candidates_list{i};
                testCase.assertEqual(...
                    active_models.models{i}.covariance, expected)
            end
            
        end
        
        function test_remove_from_map(testCase, candidate_options)
            candidates_list = getfield(testCase.expected_candidates, ...
                candidate_options);
            max_number = numel(candidates_list);
            active_models = ActiveModels(max_number);
            
            for i=1:max_number
                candidate = candidates_list{i};
                [id, status] = active_models.add_model(candidate);
                testCase.assertEqual(...
                    active_models.models{id}.covariance, candidate)
                testCase.assertEqual(id, i);
                testCase.assertEqual(status, true);
            end
            
            indices = randperm(max_number);
            for i=indices
                % remove
                candidate = candidates_list{i};
                [~, key, id] = ...
                    active_models.get_model_by_covariance(candidate);
                model = active_models.remove_from_map(id);
                testCase.assertEqual(candidate, model.covariance);
                testCase.assertEqual(id,i);
                
                % double check
                [model, ~, id] = ...
                    active_models.get_model_by_covariance(candidate);
                testCase.assertEqual(model, []);
                testCase.assertEqual(id, NaN);
                testCase.assertTrue(isempty(active_models.visited_models(key)))
            end
            
            % test failure
            candidate = candidates_list{1};
            verifyError(testCase, ...
                @() active_models.add_model(candidate), ...
                'BOMS:ActiveModels:not_removal_index');
            
            active_models.remove_priority = indices;
            for i=1:numel(candidates_list)
                candidate = candidates_list{i};
                [id, status] = active_models.add_model(candidate);
                testCase.assertEqual(id, indices(i));
                testCase.assertEqual(status, true);
            end
            
        end
        
        
        function test_get_model_by_covariance(testCase, candidate_options)
            candidates_list = ...
                getfield(testCase.candidates, candidate_options);
            max_number = numel(candidates_list);
            active_models = ActiveModels(max_number);
            
            for i=1:max_number
                candidate = candidates_list{i};
                active_models.add_model(candidate);
            end
            
            indices = randperm(max_number);
            for i=indices
                candidate = candidates_list{i};
                model = ...
                    active_models.get_model_by_covariance(candidate);
                testCase.assertTrue(model.covariance == candidate);
            end
            
        end
        
        function test_collision(testCase, candidate_options)
            % here we will mock the behavior of a hash collision
            % same key isn't enough because we use rnd_code to say
            % if two covariances are the same
            
            bucket_size = 3;
            candidates_list = ...
                getfield(testCase.expected_candidates, candidate_options);
            max_number = numel(candidates_list);
            active_models = ActiveModels(max_number);
            
            for i=1:max_number
                candidate = candidates_list{i};
                node = CovarianceNode(i, candidate);
                active_models.models{i} = node;
                expected_key = num2str(mod(i, bucket_size));
                active_models.add_to_map(expected_key, i)
                active_models.size = active_models.size + 1;
                [model, key, id] = ...
                    active_models.get_model_by_covariance(candidate, expected_key);
                testCase.assertTrue(model.covariance == candidate);
                testCase.assertEqual(key, expected_key);
                testCase.assertEqual(id, i);
            end
            
            indices = randperm(max_number);
            active_models.remove_priority = indices;
            for i=indices
                candidate = candidates_list{i};
                expected_key = num2str(mod(i, bucket_size));
                model = active_models.remove_from_map(i, expected_key);
                testCase.assertEqual(model.covariance, candidate)
            end
            
            for i=1:bucket_size-1
                key = num2str(i);
                testCase.assertEmpty(active_models.visited_models(key));
            end
            
            for i=indices
                id = active_models.get_index_to_insert();
                testCase.assertEqual(id, i);
            end
        end
        
    end
    
end

