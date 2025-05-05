function TR = mk_transform_cube(Points,Normals,T1)
plotting=false;    

%T1 = [eye(3) [0 0 0]'; 0 0 0 1];
    %nV1 & nV2
    nCams=size(Points,2);
    viewFix = 1;
    TR = cell(nCams,1);
    TR{viewFix}.T = T1; % Identity for the first camera
    TR{viewFix}.s = eye(4,4);
    TR{1}.c = ['cam',num2str(viewFix)];
    TRlocal=cell(1,1);
    for viewMove=2:nCams % for all cameras
        % Calculation correspondences and first alignment
        [~,~,tr{viewMove}] = procrustes(Points{viewFix}',Points{viewMove}','reflection',false,'scaling',false);
        TRlocal{1}.T = T1* [inv(tr{viewMove}.T) mean(tr{viewMove}.c,1)'; 0 0 0 1];
        TRlocal{1}.s = eye(4,4);
        TRlocal{1}.s = TRlocal{1}.s * tr{viewMove}.b;
        TRlocal{1}.s(4,4) = 1;
        centers{1}=Points{viewMove};
        normalFix{1}=Normals{viewFix};
        normals{1}=Normals{viewMove};
        [centersAligned] = mk_applyTransform_calib(TRlocal,centers);
        n{1}=reshape(normals{1},3,[]);
        nd = mk_applyTransform_calibNormal(TRlocal,n);
        normalsAligned{1}=reshape(nd{1},3,6,[]);
        corr=calculateCorrespondences(normalsAligned,normalFix);
        
        %Reorganize Normals
        if plotting
            NormalMoved=reorganize(normalsAligned{1},corr);
            plotCube(['Before normals'],Points{viewFix},Normals{viewFix},centersAligned{1},NormalMoved);
            plotCube('Before Only normals',zeros(size(Points{viewFix})),Normals{viewFix},zeros(size(Points{viewFix})),NormalMoved)
        end
        % Only rotation
        %Los trasladados
        normalsFix=reshape(Normals{viewFix},3,[]);
        normalsMoveReorganized=reorganize(Normals{viewMove},corr);
        normalsMove=reshape(normalsMoveReorganized,3,[]);
        % A�adimos las normales a los puntos
        puntosConNormalesFixed=addNormalsToPoints(Points{viewFix},Normals{viewFix});
        puntosConNormalesMoved=addNormalsToPoints(Points{viewMove},normalsMoveReorganized);
       % puntosConNormalesFixed=addNormalsToPoints(zeros(size(Points{viewFix})),Normals{viewFix});
       % puntosConNormalesMoved=addNormalsToPoints(zeros(size(Points{viewFix})),normalsMoveReorganized);
        
        puntosConNormalesMoved=reshape(puntosConNormalesMoved,3,[]);
        puntosConNormalesFixed=reshape(puntosConNormalesFixed,3,[]);
        [~,~,tr{viewMove}] = procrustes([Points{viewFix},puntosConNormalesFixed]',[Points{viewMove},puntosConNormalesMoved]','reflection',false,'scaling',false);
       % [~,~,tr{viewMove}] = procrustes([zeros(size(Points{viewFix})),puntosConNormalesFixed]',[zeros(size(Points{viewFix})),puntosConNormalesMoved]','reflection',false,'scaling',false);
       
       % create transforms
%        rotation=inv(tr{viewMove}.T);
%        centFix=mean(Points{viewFix},2);
%        pFix=Points{viewFix}-centFix; %Desplazamos centro
%        pFixRot=rotation*pFix;
%        centFix=pFixRot+centFix;
%        
%        centMove=mean(Points{viewMove},2);
%        pMove=Points{viewMove}-centMove; %Desplazamos centro
%        pMoveRot=rotation*pMove;
%        centMove=pMoveRot+centMove;
%        
%        
%         % Traslation
%         trans=mean(centFix-centMove,2);
       
           TR{viewMove}.T = T1* [inv(tr{viewMove}.T) mean(tr{viewMove}.c,1)'; 0 0 0 1];
           % TR{viewMove}.T = T1* [inv(tr{viewMove}.T) trans; 0 0 0 1];
           TR{viewMove}.s = eye(4,4);
           TR{viewMove}.s = TR{viewMove}.s * tr{viewMove}.b;
           TR{viewMove}.s(4,4) = 1;
           TR{viewMove}.c = ['cam',num2str(viewFix),'<-cam',num2str(viewMove)];
          
           
           if plotting 
            TRlocal2=cell(1,1);
            TRlocal2{1}=TR{viewMove};
            centers{1}=Points{viewMove};
            normals{1}=Normals{viewMove};
            [centersAligned] = mk_applyTransform_calib(TRlocal2,centers);
            n{1}=reshape(normals{1},3,[]);
            nd = mk_applyTransform_calibNormal(TRlocal2,n);
            normalsAligned{1}=reshape(nd{1},3,6,[]);

            plotCube('After normals',Points{viewFix},Normals{viewFix},centersAligned{1},normalsAligned{1});
            plotCube('After Only normals',zeros(size(Points{viewFix})),Normals{viewFix},zeros(size(Points{viewFix})),normalsAligned{1});
           end  
    end
end


function corr=calculateCorrespondences(NormalsFix,NormalsMove)
nCam=1;
for numFrame=1:size(NormalsFix{1},3)
    for nNormalsCamOne=1:6
     for nNormalsCamTwo=1:6
        ang=acos(dot(NormalsFix{nCam}(:,nNormalsCamOne,numFrame)',NormalsMove{nCam}(:,nNormalsCamTwo,numFrame)'))*180/pi;
        if imag(ang)>0
            ang=real(ang);
        end
        angleError(nNormalsCamOne,nNormalsCamTwo)=ang;
     end
    end
    [~,ids]=min(angleError);     
    corr(numFrame,:)=ids;
end
end

function NormalReorganized=reorganize(NormalsMove,corr)
    for i=1:size(corr,1)
        NormalReorganized(:,:,i)=NormalsMove(:,corr(i,:),i);
    end
end

function plotCube(str,Fixed,NormalFixed,Moved,NormalMoved)
cm=colormap;
            figure('Name',str)

        plot3(Fixed(1,:),Fixed(2,:),Fixed(3,:),'r.','markersize',10);
        hold on
        plot3(Moved(1,:),Moved(2,:),Moved(3,:),'b.','markersize',10);
        hold on
        for nnormal=1:6
            quiver3(Fixed(1,:),Fixed(2,:),Fixed(3,:),reshape(NormalFixed(1,nnormal,:),1,[]),reshape(NormalFixed(2,nnormal,:),1,[]),reshape(NormalFixed(3,nnormal,:),1,[]),'color',cm(nnormal*10,:));
            quiver3(Moved(1,:),Moved(2,:),Moved(3,:),reshape(NormalMoved(1,nnormal,:),1,[]),reshape(NormalMoved(2,nnormal,:),1,[]),reshape(NormalMoved(3,nnormal,:),1,[]),'color',cm(nnormal*10,:));
        end

end

function puntosConNormales=addNormalsToPoints(Points,Normals)

for i=1:size(Points,2)
    for j=1:6
        puntosConNormales(:,j,i)=Points(:,i)+Normals(:,j,i);
    end
end

end