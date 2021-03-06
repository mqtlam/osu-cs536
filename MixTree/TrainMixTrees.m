function [ edgeStructs, nodePots, edgePots, mCoeffs ] = TrainMixTrees( foundTrainObjectsList, trainScenes, objectsVocab, K )
%TRAINMIXTREE Train graphical model of mixture of Chow-Liu trees.
%
%   Each object node comes from counting presence/absence in images.
%  
%   foundTrainObjectsList:  list of object counts
%                           Each cell is a containers.Map
%                           Each map stores the objects found as keys
%                               and the object counts as values
%   scenes:                 map where keys are scenes and values are indices to examples
%   objectsVocab:           list of objects vocabulary (from training and test sets)
%   edgeStructs:            map where keys are scenes and values are
%                               edgeStructs (UGM)
%   nodePots:               map where keys are scenes and values are 
%                               node potentials (UGM)
%   edgePots:               map where keys are scenes and values are 
%                               edge potentials (UGM)
%   mCoeffs:                map where keys are scenes and values are 
%                               mixture coeffients(UGM) of the trees
%   K:                      # of trees to learn for each scene

%% initialization
edgeStructs = containers.Map;
nodePots = containers.Map;
edgePots = containers.Map;
mCoeffs = containers.Map;

nNodes = length(objectsVocab);
nStates = 2;
maxIter = 10; % maximum iteration for EM 

%% for convenience: map object name to index
objectsVocabMap = containers.Map;
for i = 1:length(objectsVocab)
    objectsVocabMap(objectsVocab{i}) = i;
end

%% loop through scenes
for s = keys(trainScenes)
    scene = s{1};
    fprintf('\nLearning trees for scene: %s\n', K, scene);
    %% Initialize the MT model
    MT_lambda = ones(K,1);
    MT_lambda = MT_lambda/sum(MT_lambda); % initial lambda has uniform probability

    %% randomly initialize the tree components
    % preprocess
    examples = trainScenes(scene);
    foundObjectsList = cell(length(examples), 1);
    for ex = 1:length(examples)
        foundObjectsList{ex} = foundTrainObjectsList{examples(ex)};
    end
    samples = PreprocessData(foundObjectsList, objectsVocab);
    
    N = size(samples,2);    
   
    % Generate the Initial Mixture trees
    [MT_edgeStructs, MT_nodePots, MT_edgePots] = GenerateInitMT( nNodes, nStates, K, samples, 2);

    %% Start the EM iterations
    for it = 1:maxIter
        %% E step
        [P, uGamma] = EStep(MT_edgeStructs, MT_nodePots, MT_edgePots, MT_lambda, samples, K);
        %% M step
        parfor k= 1:K
            MT_lambda(k) = uGamma(k)/ N;            
            Pk = P(:,k)';
            [edgeStruct, nodePot, edgePot] = MTChowLiuTree(Pk ,samples);
            MT_edgeStructs{k,1} = edgeStruct;
            MT_nodePots{k,1} = nodePot;
            MT_edgePots{k,1} = edgePot;
        end
    end
    %% updates    
    edgeStructs(scene) = MT_edgeStructs;
    nodePots(scene) = MT_nodePots;
    edgePots(scene) = MT_edgePots;
    mCoeffs(scene) = MT_lambda;

end

end














