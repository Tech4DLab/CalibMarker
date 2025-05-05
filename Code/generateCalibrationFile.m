function generateCalibrationFile(strCalFile,snCams,TR,path,factorFocal)
fileID = fopen(strCalFile,'w');

fprintf(fileID, '## Path calibrado: %s \n', regexprep(path{1,1}, '/[^/]*$', ''));
fprintf(fileID,'## PARAMETROS IMAGEN\n');
fprintf(fileID,'cx 		=			640.0\n');
fprintf(fileID,'cy 		=			360.0\n');
%fprintf(fileID,'cxC					645.382\n');
%fprintf(fileID,'cyC					359.797\n');

fprintf(fileID,'\n## PARAMETROS CALIBRADO\n');
for i=1:size(TR,1)
    fprintf(fileID,'idCam:%d=                          %s\n',i-1,snCams{i});
end
for i=1:size(TR,1)
    tt=TR{i}.T';
    fprintf(fileID,'matCam:%d=                         ',i-1);
    fprintf(fileID,'%7.32f,',tt(1:end-1));
    fprintf(fileID,'%7.32f\n',tt(end));
end


fprintf(fileID,'\n## FACTORES FOCALES\n');
for i=1:size(TR,1)
    fprintf(fileID,'calibFactor:%d=           %.4f %.4f %.4f \n',[i-1,factorFocal(i,1),factorFocal(i,1),factorFocal(i,1)]);
end

fclose(fileID);
end
