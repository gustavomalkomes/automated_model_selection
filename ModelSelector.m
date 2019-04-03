classdef ModelSelector < handle
    properties
        problem;
        model_space; 
        fitness_function;
        strategy;
        callback;
        time;
    end
    
    methods
        function obj = ModelSelector(...
                problem, ...
                model_space, ...
                fitness_function, ...
                strategy, ...
                callback ...
            )
            obj.problem = problem;
            obj.model_space = model_space;
            obj.fitness_function = fitness_function;
            obj.strategy = strategy;     
            obj.callback = callback; 
        end
                
        function [selected_models, fitness_scores, time] = run(obj)           

        verbose  = isfield(obj.problem, 'verbose') && obj.problem.verbose;
        obj.problem.verbose = verbose;
                
        % save the wall-clock time of each operation
        total_time_model_space = NaN(obj.problem.budget, 1);
        total_time_strategy = NaN(obj.problem.budget,1);
        total_time_fitness = NaN(obj.problem.budget,1);

        [selected_models, fitness_scores] = obj.initialization();
        
        for i = 1:obj.problem.budget
            % get list of candidate models
            tstart_model_space = tic;
            candidate_models = obj.model_space.get_candidates(...
                selected_models, ...
                fitness_scores ...
            );
            time_model_space = toc(tstart_model_space);
            total_time_model_space(i) = time_model_space;
            
            % select next model to evaluate
            tstart_strategy = tic;
            chosen_model = obj.strategy.query(...
                obj.problem, ...
                selected_models, ...
                fitness_scores, ...
                candidate_models ...
             );
            time_strategy = toc(tstart_strategy);
            total_time_strategy(i) = time_strategy;

            % observe the fitness score of the chosen model
            tstart_fitness = tic;
            chosen_model_fitness = obj.fitness_function(...
                obj.problem, ...
                chosen_model ...
            );
            time_fitness = toc(tstart_fitness);
            total_time_fitness(i) = time_fitness;

            % update data    
            selected_models = [selected_models, chosen_model];
            fitness_scores = [fitness_scores, chosen_model_fitness];
            
            if ~isempty(obj.callback)
                obj.callback(obj, selected_models, fitness_scores, i);
            end
        end
        
        time.total_time_model_space = total_time_model_space;
        time.total_time_strategy = total_time_strategy;
        time.total_time_oracle = total_time_fitness;
        end
    end
    
    methods (Abstract)
        initialization(obj)
    end    
    
end

