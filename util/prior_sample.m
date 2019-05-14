function hyps = prior_sample(priors, probability_samples)
    num_samples = size(probability_samples,1);
    num_hyp = numel(priors);
    prior_mean = zeros(1,numel(priors));
    prior_std  = zeros(1,numel(priors));
    for i=1:num_hyp
        func    = functions(priors{i});
        prior_mean(i) = func.workspace{1}.extra_arguments{1};
        prior_std(i)  = sqrt(func.workspace{1}.extra_arguments{2});
    end
    hyps = norminv(...
        probability_samples(:,1:num_hyp),...
        repmat(prior_mean,[num_samples,1]),...
        repmat(prior_std,[num_samples,1])...
        );
end