% script to load paths, assuming they are in a parent folder
if ~exist('agpl.m', 'file')
    addpath(genpath('../active_gp_learning'));
end

% add boms files
addpath(genpath('./'));
