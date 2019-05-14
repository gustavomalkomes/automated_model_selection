classdef HellingerDistanceBuilder < DistanceBuilder
    % HellingerDistanceBuilder builds distances based on
    % the Hellinger distance between the model's Gram matrices.
    %   Detailed explanation goes here
    methods
        function obj = HellingerDistanceBuilder(...
                noise_prior, ...
                num_samples, ...
                max_num_hyperparameters, ...
                max_num_kernels, ...
                active_models, ...
                initial_model_indices, ...
                data_X ...
                )
            
            obj@DistanceBuilder(noise_prior, ...
                num_samples, ...
                max_num_hyperparameters, ...
                max_num_kernels, ...
                active_models, ...
                initial_model_indices, ...
                data_X ...
                );
        end
        
        function distance = hellinger_distance(~, data_i, data_j)
            % Squared Hellinger distance for two multivariate
            % Gaussian distributions with means zero.
            % https://en.wikipedia.org/wiki/Hellinger_distance
            %
            tol = 0.02;
            are_different = ...
                abs(data_i.log_determinant - data_j.log_determinant) > tol;
            indices = 1:numel(are_different);
            logdet_p_and_q = data_i.log_determinant;
            for i=indices(are_different)
                p_K = data_i.mini_gram_matrices(:,:,i);
                q_K = data_j.mini_gram_matrices(:,:,i);
                p_and_q_kernels = 0.5 * (p_K + q_K);
                [chol_p_and_q, flag]  = chol(p_and_q_kernels);
                if flag > 0
                    chol_p_and_q = ...
                        obj.fix_numerical_problem(p_and_q_kernels);
                end
                logdet_p_and_q(i) = 2*sum(log(diag(chol_p_and_q)));
            end
            
            % compute log distance
            log_det_sum = data_i.log_determinant + data_j.log_determinant;
            log_hellinger = 0.25 * log_det_sum - 0.5 * logdet_p_and_q;
            
            % exponentiate
            hellinger = 1 - exp(log_hellinger);
            distance = mean(hellinger);
        end
        
        function compute_distance(obj, active_models, indices_i, indices_j)
            for i=indices_i
                for j=indices_j
                    dist = obj.hellinger_distance(...
                        active_models.models{i}.info, ....
                        active_models.models{j}.info ...
                        );
                    obj.average_distance(i,j) = dist;
                    obj.average_distance(j,i) = dist;
                end
            end
        end
        
        function precomputed_info = create_precomputed_info(...
                obj, covariance, data_X ...
                )
            n = size(data_X,1);
            tolerance = 1e-6;
            log_det = NaN(1, obj.num_samples);
            mini_gram_matrices = NaN(n, n, obj.num_samples);
            hyperparameters  = prior_sample(covariance.priors, ...
                obj.probability_samples);
            for i = 1:size(hyperparameters,1)
                hyp = hyperparameters(i,:);
                lambda = obj.hyperparameter_data_noise_samples(i);
                k = feval(covariance.function_handle{:}, hyp,  data_X);
                k = k + lambda*eye(size(k,1));
                mini_gram_matrices(:,:,i) = k;
                [chol_k, flag] = chol(k);
                if flag > 0
                    chol_k = obj.fix_numerical_problem(k);
                end
                log_det(i) = 2*sum(log(diag(chol_k)));
            end
            precomputed_info.log_determinant = log_det;
            precomputed_info.mini_gram_matrices = mini_gram_matrices;
        end
        
        function chol_k = fix_numerical_problem(k)
            [v,d] = eig(k);
            new_diagonal = diag(d);
            new_diagonal(new_diagonal < tolerance) = tolerance;
            new_diagonal = diag(new_diagonal);
            k = v*new_diagonal*v';
            k = (k + k')/2;
            [chol_k, ~] = chol(k); % TODO: raise error here
        end
    end
end
