function [ fitness ] = evidence_fitness_function(problem, model)
    model = model.train(problem.X, problem.y);
    fitness = -model.log_evidence();
end