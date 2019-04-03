function [ log_model_evidence ] = log_evidence_fitness_function(problem, model)
    
    model = model.train(problem.X, problem.y);
    log_model_evidence = model.log_evidence();
end