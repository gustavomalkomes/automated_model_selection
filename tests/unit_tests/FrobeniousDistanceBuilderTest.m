classdef FrobeniousDistanceBuilderTest < DistanceBuilderTest
    properties
        distance_builder
    end
    methods(TestMethodSetup)
        function setUp(testCase)
            testCase = testCase.test_setUp();
            testCase.distance_builder = ...
                FrobeniousDistanceBuilder(...
                testCase.noise_prior, ...
                testCase.num_samples, ...
                testCase.max_num_hyperparameters, ...
                testCase.max_num_kernels, ...
                testCase.active_models, ...
                testCase.initial_model_indices, ...
                testCase.data_X ...
                );
        end
    end
    
    methods (Test)
        
        function test_update(testCase)
            builder = testCase.distance_builder;
            testCase.update_test(builder)
        end
        
        function test_create_precomputed_info(testCase)
            builder = testCase.distance_builder;
            num_points = size(testCase.data_X,1);
            for i = 1:testCase.active_models.size
                covariance = testCase.active_models.models{i}.covariance;
                info = builder.create_precomputed_info(covariance, ...
                    testCase.data_X);
                testCase.active_models.models{i}.set_precomputed_info(info);
                testCase.assertNotEmpty(...
                    testCase.active_models.models{i}.info)
                testCase.assertEqual(...
                    size(testCase.active_models.models{i}.info), ...
                    [num_points*num_points, testCase.num_samples])
            end
        end
        
        function test_distance_builder(testCase)
            className = 'FrobeniousDistanceBuilder';
            builder = testCase.distance_builder;
            testCase.distance_builder_test(builder, className)
        end
        
        function test_compute_distance(testCase)
            builder = testCase.distance_builder;
            num_points = size(testCase.data_X,1);
            n2 = num_points*num_points;
            distance_function = @(i,j) mean(sum((i-j).^2))/n2;
            testCase.compute_distance_test(builder, distance_function)
        end
        
    end
    
end

