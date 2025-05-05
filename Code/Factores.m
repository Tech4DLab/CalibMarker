function factorFocal = Factores(default, snCams)
    
    if default
        sizesperCam=ones(size(snCams,2),3)*250; 
        factorFocal=250./sizesperCam; 
    else
%          factorFocal = [1.03 ; 0.95; 1.00 ; 1.00;...
%                         1.00 ; 1.00; ...
%                         1.00 ; 1.00; ...  
%                         0.98088; 1.08; 1.0314; 1.00];
          factorFocal = [1.03 ; 0.98; 0.99 ; 1.00;... % 150
                         1.035 ; 1.00; ...
                         0.99 ; 1.03; 1.00 ; 1.00; ...  
                         0.99; 1.09; 1.05; 1.003];
          factorFocal = [1.03; 0.945; 1.00; 0.98;...  % Good
                         1.00; 1.00;  0.99; 1.03; ...   % Good
                         0.99; 1.09;  1.05; 1.003];
        %factorFocal = [1.00 ; 1.00; 0.99 ; 1.03; ...
        %               0.99;1.09;1.05;1.003] % Factores R4

        
        %factorFocal = [1.03 ; 0.95; 1.00]; ok primera fila
        %factorFocal = [0.98088; 0.99; 1.0314; 1.0055];
        factorFocal = repmat(factorFocal, 1, 3);
        %disp('Factores: ');
        %disp(factorFocal);
    end
end
% Camera 831612070293 Factor X: 1.0364 Factor Y: 1.0364 Factor Z: 1.0364
% Camera 829212071391 Factor X: 0.95981 Factor Y: 0.95981 Factor Z: 0.95981
% Camera 829212072264 Factor X: 1.0103 Factor Y: 1.0103 Factor Z: 1.0103
% Camera 728312070655 Factor X: 1.0007 Factor Y: 1.0007 Factor Z: 1.0007
% 
% Camera 733512070455 Factor X: 1.0028 Factor Y: 1.0028 Factor Z: 1.0028
% Camera 740112070465 Factor X: 1.013 Factor Y: 1.013 Factor Z: 1.013
% 
% Camera 829212072262 Factor X: 0.9763 Factor Y: 0.9763 Factor Z: 0.9763
% 
% Camera 836612071402 Factor X: 1.006 Factor Y: 1.006 Factor Z: 1.006
% Camera 848312070429 Factor X: 1.0266 Factor Y: 1.0266 Factor Z: 1.0266
% 
% Camera 846112070086 Factor X: 0.98316 Factor Y: 0.98316 Factor Z: 0.98316
% Camera 728312070946 Factor X: 1.0756 Factor Y: 1.0756 Factor Z: 1.0756
% Camera 848312070416 Factor X: 1.0822 Factor Y: 1.0822 Factor Z: 1.0822
% Camera 848312070090 Factor X: 1.0098 Factor Y: 1.0098 Factor Z: 1.0098

%factorFocal = [1.0364; 0.95981; 1.0103; 1.0007; 1.0028; 1.013; 0.9763;...
%               1.006; 1.0266; 0.98316; 1.0756; 1.0822; 1.0098];
%            
% factorFocal = [1.0426; 0.96515; 1.022; 1.0143; 0.99934; 1.0181 ; 0.9763;...
%             1.006; 1.0266; 0.98316; 1.0756; 1.0822; 1.0098];
%         
% factorFocal = [1.0426; 0.96515; 1.022; 1.0143; 0.99934; 1.0181; 0.99896;...
%         1.0111; 1.0296; 0.98255; 1.0949; 1.0289; 1.0166];

%factorFocal = [1.042; 0.96375; 1.0197; 1.0089; 0.99976; 1.0051];  % Buenas capturas  0.99976
%factorFocal = [1.0346 ; 0.9683; 1.0136 ; 1.0079 ; 0.9995; 1.0053];  % Buenas capturas  0.99976
%factorFocal = [1.03 ; 0.97; 1.00 ; 1.00 ; 1.00; 1.00]; % OKKKKKKK TOP - SUPER TOP
%factorFocal = [1.0012 ; 1.0096]; % HORIZONTAL
%factorFocal = [0.98687; 1.0132; 0.99735; 1.006];  % BOTTOM 
%factorFocal = [0.99; 1.01; 1.00; 1.00];  % BOTTOM OKK


% factorFocal = [1.03 ; 0.97; 1.00 ; 1.00 ;...
%                1.00; 1.00;...
%                1.00;...
%                1.00 ; 1.00;...
%                0.99; 1.05; 1.00; 1.00];

%factorFocal = [1.03 ; 0.97; 1.00 ; 1.00]; %TOP
%factorFocal = [0.99 ; 1.02; 0.99 ; 1.00];

%factorFocal = [1.0364; 0.95981; 1.0103; 1.0007];
%factorFocal = repmat(factorFocal, 1, 3);
% 


%factorFocal = [1.0502; 0.96921; 1.0232; 1.0125; 1.0031; 1.0108];
% Recalculado
%factorFocal = [1.0426/1.0364; 0.96515/0.95981; 1.022/1.0103; 1.0143/1.0007; 0.99934/1.0028; 1.0181/1.013];


%factorFocal = [1.00000/1.0364; 1.00000/0.95981; 1.00000/1.0103; 1.00000/1.0007; 1.00000/1.0028; 1.00000/1.013];
%factorFocal = [1.065563395/1.0364; 0.960707508/0.95981; 1.023110238/1.0103; 1.0125/1.0007; 1.016985938/1.0028; 1.0108/1.013];