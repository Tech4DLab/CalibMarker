function PossibleSolution = evaluatePlanes(ObjectPlanes, ModelPlanes)

    evaluationOK = false;
    model = 1;
    
    ObjAux = ObjectPlanes;
    ModAux = ModelPlanes;
    thr = 30; %20

    clear bestCandidate bestCandidateNoMatch numOccurrences
    for idAux = 1:size(ObjAux,1)
        numOccurrences{1,idAux} = 0;
    end
    for idRO = 1:size(ObjAux,1)
        clear bestCandidateAux bestCandidateNoMatchAux numOccurrencesAux
        numOccurrencesAux{1}= 0;

        %% Choose candidate row
        contRM = 1;
        for idRM = 1:size(ModAux,1)
            rOAux = ObjAux(idRO,:);
            rMAux = ModAux(idRM,:);
            contR = 0;
            notMatch = [];

            rOAux = rOAux(1:end ~= idRO);
            rMAux = rMAux(1:end ~= idRM);
            idxMatch = ones(length(rOAux),1).*2;
            while ismember(2,idxMatch) & sum(~isinf(rMAux)) > 0 & sum(~isinf(rOAux)) > 0

                [Corr,dCorr] = knnsearch(rMAux',rOAux');

                idnan = isnan(dCorr);
                idnan(idxMatch == Inf) = 1;
                idnan(dCorr == Inf) = 1;

                idWrong = zeros(size(dCorr));
                idWrong(~idnan) = dCorr(~idnan) > thr;
                idxMatch(idWrong == 1) = Inf;

                idnan(idWrong == 1) = 1;
                Corr(idnan) = nan;

                [noUnique,~,~,~] = repval(Corr(~isnan(Corr)));
                for iddiff = 1:numel(noUnique)
                    [m,idM] = min(dCorr(Corr == noUnique(iddiff)));
                    idC = find(Corr == noUnique(iddiff));
                    idxMatch(idC(idM)) = 1;
                end
                idxAux = idxMatch == 2 & ~ismember(Corr,noUnique);
                idxAux(idnan) = 0;

                idxMatch(idxAux) = 1;

                idxAux = idxMatch == 1 | idxMatch == 0;
                idxAux(idnan) = 0;

                rMAux(Corr(idxAux)) = Inf;
                rOAux(idxAux) = Inf;
            end


            contR = sum(idxMatch(idxMatch == 1));
            notMatch = find(idxMatch~=1);
            notMatch(notMatch >= idRO) =  notMatch(notMatch >= idRO) +1;
            if contR > numOccurrencesAux{1,1}
                 clear bestCandidateAux bestCandidateNoMatchAux numOccurrencesAux
                numOccurrencesAux{1} = 0;

                bestCandidateAux{1,1} = idRM;
                numOccurrencesAux{1,1} = contR;
                bestCandidateNoMatchAux{1,1} = notMatch;
                contRM = 2;
            elseif contR == numOccurrencesAux{1,1};
                bestCandidateAux{1,contRM} = idRM;
                numOccurrencesAux{1,contRM} = contR;

                bestCandidateNoMatchAux{1,contRM} = notMatch;

                contRM = contRM + 1;
            end
        end
        bestCandidate{idRO} = bestCandidateAux;
        numOccurrences{idRO} = numOccurrencesAux;
        bestCandidateNoMatch{idRO} = bestCandidateNoMatchAux;
    end
    %             planesToEvaluate = zeros(1,size(ObjAux,1));
    planesToEvaluate = zeros(1,size(ModAux,1));
    for ii = 1:size(bestCandidate,2)
        cand = cell2mat(bestCandidate{ii});
        planesToEvaluate(cand) = planesToEvaluate(cand) +1;
    end

    if model == 1
        
        currentLevel = 1;
        maxLevels = size(ModAux,1);
        EndLoop = false;
        MinNans = intmax;
        for idxLevel = 1:maxLevels
            candLev = [];
            for idxAux = 1: size(bestCandidate,2);
                for idxAux2 = 1:size(bestCandidate{idxAux},2)
                    if bestCandidate{idxAux}{idxAux2} == idxLevel
                        candLev = [candLev;idxAux];
                    end
                end
            end
            candidateLevel{idxLevel} = [candLev;nan];
        end
        currentPosInLevel = ones(1,maxLevels);
        currentBranch = [];
        PossibleSolution = [];
        while ~EndLoop %currentLevel == maxLevels & currentCandidate == size(bestCandidate)
            
            currentObjAux = candidateLevel{currentLevel}(currentPosInLevel(currentLevel));
            constraintsOK = true;
            if ismember(currentObjAux,currentBranch);
                constraintsOK = false;
            end
                
           	
            if currentLevel > 1
                if ~isnan(currentObjAux)
                    for idConst = 1:size(currentBranch,1)
                        if ~isnan(currentBranch(idConst));
                            UpBound = ObjAux(currentBranch(idConst),currentObjAux) <= ModAux(idConst,currentLevel) + thr;
                            LowBound = ObjAux(currentBranch(idConst),currentObjAux) >= ModAux(idConst,currentLevel) - thr;
                            if ~UpBound | ~LowBound
                                constraintsOK = false;
                            end
                        end
                    end
                end
                if constraintsOK
                    currentBranch = [currentBranch; currentObjAux];
                end
            else
                currentBranch = currentObjAux;
            end
            if constraintsOK
                if currentLevel <  maxLevels
                    currentLevel = currentLevel + 1;
                    currentPosInLevel(currentLevel) = 1; %restart the index of the new level
                elseif currentLevel == maxLevels
                    
                    
                    if sum(isnan(currentBranch)) <= MinNans
                        PossibleSolution = [PossibleSolution currentBranch];
                        MinNans = sum(isnan(currentBranch));
                    end
                    
                    
                    
                    NewNodeFound = false;
                    cc = currentLevel;

                    while ~NewNodeFound
                        if currentPosInLevel(cc) < size(candidateLevel{cc},1)
                            currentPosInLevel(cc) = currentPosInLevel(cc) +1;
                            currentBranch = currentBranch(1:cc-1);
                            NewNodeFound = true;
                        else
                            cc = cc -1;
                            if cc < 1 %End of the process
                                EndLoop = true;
                                NewNodeFound = true;
                            else
                                currentBranch = currentBranch(1:cc);
                            end
                        end
                    end
                    currentLevel = cc;
                end
            else
                NewNodeFound = false;
                cc = currentLevel;

                while ~NewNodeFound
                    if currentPosInLevel(cc) < size(candidateLevel{cc},1)
                        currentPosInLevel(cc) = currentPosInLevel(cc) +1;
                        currentBranch = currentBranch(1:cc-1);
                        NewNodeFound = true;
                    else
                        cc = cc -1;
                        if cc < 1 %End of the process
                            EndLoop = true;
                            NewNodeFound = true;
                        else
                            currentBranch = currentBranch(1:cc);
                        end
                    end
                end
                currentLevel = cc;
            end
        end

    end
end