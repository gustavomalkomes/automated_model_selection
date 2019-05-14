classdef ActiveModels < handle
    %ACTIVEMODELS manages the active set of models
    properties
        max_number_of_models;
        size;
        models;
        visited_models;
        remove_priority;
        selected_indices;
    end
    
    methods
        function obj = ActiveModels(max_number_of_models)
            obj.max_number_of_models = max_number_of_models;
            obj.models = cell(1, max_number_of_models);
            obj.visited_models = containers.Map();
            obj.remove_priority = [];
            obj.selected_indices = [];
            obj.size = 0;
        end
        
        function indices = update(obj, candidates)
            status = false(1, numel(candidates));
            ids = NaN(1, numel(candidates));
            for i=1:numel(candidates)
                candidate = candidates{i};
                [ids(i), status(i)] = obj.add_model(candidate);
            end
            indices = ids(status);
        end
        
        function [id, status] = add_model(obj, covariance)
            [model, key] = obj.get_model_by_covariance(covariance);
            if ~isempty(model)
                id = NaN;
                status = false;
                return
            end
            
            id = obj.get_index_to_insert();
            
            if obj.size >= obj.max_number_of_models
                obj.remove_from_map(id);
            else
                obj.size = obj.size + 1;
            end
            
            % create node and add to active set of models
            node = CovarianceNode(id, covariance);
            obj.models{id} = node;
            
            % add reference to map
            obj.add_to_map(key, id)            
            status = true;
        end
        
        function index = get_index_to_insert(obj)
            if obj.size < obj.max_number_of_models
                index = obj.size + 1;
                return
            end
            if isempty(obj.remove_priority)
                error('BOMS:ActiveModels:not_removal_index', ...
                    'Must set removal priority when activeModels is full');
            end
            index = obj.remove_priority(1);
            obj.remove_priority(1) = [];
        end
        
        function add_to_map(obj, key, id)
            map = obj.visited_models;
            if map.isKey(key)
                list_nodes = map(key);
                array_of_ids = cell2mat(list_nodes);
                if ~isempty(find(array_of_ids==id, 1))
                    error('BOMS:ActiveModels:DuplicateId', ...
                        'Element already exists');
                end
            else
                list_nodes = {};
            end
            list_nodes{end+1} = id;
            map(key) = list_nodes;
        end
        
        function model = remove_from_map(obj, id, varargin)
            map = obj.visited_models;
            model = obj.models{id};
            if isempty(varargin)
                key = num2str(model.covariance.rnd_code);
            else
                key = varargin{1};
            end
            if ~map.isKey(key)
                error('BOMS:ActiveModels:KeyError', 'Key does not exist');
            end
            list_nodes = map(key);
            index = [];
            for i=1:numel(list_nodes)
                if list_nodes{i} == id
                    index = i;
                    break
                end
            end
            list_nodes(index) = [];
            map(key) = list_nodes;
        end
        
        function [model, key, id] = get_model_by_covariance(...
                obj, ...
                covariance, ...
                varargin ...
            )
            if ~isa(covariance, 'Covariance')
                error('BOMS:ActiveModels:TypeError', ...
                    'Expected Covariance type');
            end
            
            if isempty(varargin)
                key = num2str(covariance.rnd_code);
            else
                key = varargin{1};
            end
            map = obj.visited_models;
            model = [];
            id = NaN;
            if ~map.isKey(key)
                return
            end
            list_nodes = map(key);
            for i=1:numel(list_nodes)
                node_id = list_nodes{i};
                node = obj.models{node_id};
                if node.covariance == covariance
                    model = [obj.models{node_id}];
                    id = node_id;
                    return
                end
            end
            model = [];
        end
    end
end
