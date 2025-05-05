function VectorNormalization = UnitVectorFromPoints(Points,CentCalibration)

    dim = size(Points);
    dimOK = find(dim~=3);
    
    aux1 = CentCalibration-mean(Points,dimOK);
    aux2 = 1/sqrt(aux1(1)^2+aux1(2)^2+aux1(3)^2);

    VectorNormalization = aux1*aux2;
end