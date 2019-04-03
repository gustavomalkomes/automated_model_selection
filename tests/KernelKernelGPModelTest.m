classdef KernelKernelGPModelTest < matlab.unittest.TestCase
    methods (Test)
        function test_create(testCase)
            model = KernelKernelGPModel(Hyperpriors());
            testCase.assertClass(model, 'KernelKernelGPModel')
            testCase.assertTrue(isa(model, 'GpModel'))
            testCase.assertEqual(model.name, 'KernelKernel');
        end
        
        function test_set_kernel_handle(testCase)
            model = KernelKernelGPModel(Hyperpriors());
            theta.cov = log([1 1]);
            size = 5;
            K = @(i,j) i+j;
            model.set_kernel_kernel(K); 
            cov = @(i,j) feval(model.covariance_function{:}, theta.cov, i, j);
            
            % Using fixed_distance_SEiso_covariance
            expected = @(i,j) exp(-K(i,j)/2);
            
            for i=1:size
                for j=1:size
                    testCase.assertEqual(cov(i,j), expected(i,j));
                end
            end
            
            K = @(i,j) 2*(i*j);
            expected = @(i,j) exp(-K(i,j)/2);
            model.set_kernel_kernel(K); 
            cov = @(i,j) feval(model.covariance_function{:}, theta.cov, i, j);
            for i=1:size
                for j=1:size
                    testCase.assertEqual(cov(i,j), expected(i,j));
                end
            end            
        end
        function test_set_kernel_kernel(testCase)
            model = KernelKernelGPModel(Hyperpriors());
            
            size = 5;
            
            K = rand(size);
            K = ((K'*K)/2)/size;
            
            model.set_kernel_kernel(K);
            testCase.assertEqual(model.covariance_function{1}, ...
                @fixed_distance_SEiso_covariance)
            
            model.theta = model.prior();
            
            ell2 = exp(2*model.theta.cov(1)); % length scale
            sf2 = exp(2*model.theta.cov(2)); % output scale
            kernel = sf2*exp(-(K/(2*ell2))); % expected kernel
            
            covariance = feval(model.covariance_function{:}, ...
                model.theta.cov, 1:size, 1:size);
            
            % kernel matrix
            testCase.assertEqual(covariance, kernel);
            
            % test easy derivatives wrt sf
            expected_d2 = 2*kernel;
            covariance_d2 = feval(model.covariance_function{:}, ...
                model.theta.cov, 1:size, 1:size, 2);
            testCase.assertEqual(covariance_d2, expected_d2);
            
            expected_d22 = 4*kernel;
            covariance_d22 = feval(model.covariance_function{:}, ...
                model.theta.cov, 1:size, 1:size, 2, 2);
            testCase.assertEqual(covariance_d22, expected_d22);
            
            % testing a second matrix
            size = 20;
            
            K = rand(size);
            K = ((K'*K)/2)/size;
            
            model.set_kernel_kernel(K);
            testCase.assertEqual(model.covariance_function{1}, ...
                @fixed_distance_SEiso_covariance)
            
            model.theta = model.prior();
            
            ell2 = exp(2*model.theta.cov(1)); % length scale
            sf2 = exp(2*model.theta.cov(2)); % output scale
            kernel = sf2*exp(-(K/(2*ell2))); % expected kernel
            
            covariance = feval(model.covariance_function{:}, ...
                model.theta.cov, 1:size, 1:size);
            testCase.assertEqual(covariance, kernel);
        end
    end
end

