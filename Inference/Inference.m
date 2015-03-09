function [ probs, scenes, bestScene ] = Inference( foundObjects, objectsVocab, edgeStructs, nodePots, edgePots)
%INFERENCE Perform inference by finding the scene that maximizes probability.
%   foundObjects:   list of object counts
%                           Each cell is a containers.Map
%                           Each map stores the objects found as keys
%                               and the object counts as values
%   objectsVocab:   list of objects vocabulary (from training and test sets)
%   edgeStructs:            map where keys are scenes and values are
%                               edgeStructs (UGM)
%   nodePots:               map where keys are scenes and values are 
%                               node potentials (UGM)
%   edgePots:               map where keys are scenes and values are 
%                               edge potentials (UGM)
%   probs:          probabilities for each scene
%   scenes:         list of scenes (in order for probs)
%   bestScene:      scene with maximum probability

nNodes = length(objectsVocab);

%% for convenience: map object name to index
objectsVocabMap = containers.Map;
for i = 1:nNodes
    objectsVocabMap(objectsVocab{i}) = i;
end

%% loop through all scenes
scenes = keys(nodePots);
probs = zeros(length(scenes), 1);
sceneIndex = 1;
for s = scenes
    scene = s{1};
    nodePot = nodePots(scene);
    edgePot = edgePots(scene);
    edgeStruct = edgeStructs(scene);

    %% compute partition function
    [~, ~, logZ] = UGM_Infer_Tree(nodePot,edgePot,edgeStruct);

    %% compute configuration
    configuration = zeros(nNodes, 1);
    objects = keys(foundObjects);
    presentIndices = [];

    %% loop through all objects found in example
    for o = objects
        obj = o{1};
        index = objectsVocabMap(obj);
        presentIndices = union(presentIndices, index);
        configuration(index) = 1;
    end

    %% set all non found objects as absent
    for index = setdiff(1:nNodes, presentIndices)
        configuration(index) = 2;
    end

    %% compute probability
    prob = 0;
    for i = 1:nNodes
       prob = prob + log(nodePot(i, configuration(i)));
    end
    prob = prob - logZ;
    prob = exp(prob);

    probs(sceneIndex) = prob;
    sceneIndex = sceneIndex + 1;
end

%% set the best scene
[~, index] = max(probs);
bestScene = scenes(index);

scenes = scenes';

end
