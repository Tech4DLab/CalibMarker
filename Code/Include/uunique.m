function [unsorteduniques ia ib] = uunique(vec) 
    vec = vec(:)'; 
    [v a b] = unique(vec, 'first'); 
    if nargout > 2 
        [ia v] = sort(a); 
        [v ib] = ismember(b, v); 
    else 
       ia = sort(a); 
    end 
    unsorteduniques = vec(ia); 
end