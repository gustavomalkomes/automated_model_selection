Automated model selection
===

This repository provides tools for performing model selection for
Gaussian process models. Specifically, we view model selection as
an active learning (or active optimization) problem, where
training each candidate kernel is considered an expensive process.

### Bayesian Optimization for automated model selection

Our main tool is the method "Bayesian optimization for
automated model selection" (BOMS) presented in: 

> Gustavo Malkomes, Charles Schaff, and Roman Garnett.
> Bayesian optimization for automated model selection
> Advances in Neural Information Processing Systems 29
> (NeurIPS 2016)

## Dependencies
------------

* Functions from the `active_gp_learning` repository
 <https://github.com/gustavomalkomes/active_gp_learning>


## Getting Started
------------

If the `active_gp_learning` folder is in a parent folder, you
should be able to execute the following lines of code:

```
    automated_model_selection_startup
    active_gp_learning_starup
    active_gp_learning_tests
    automated_model_selection_tests
```
