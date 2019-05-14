% This function computes the 't' transform for the image 'ref' and applies
% this transform to the other markers of the same sequence

function alignment()

srcPath = uigetdir('Select the sequence path'); 
mkdir(srcPath, [filesep 'Aligned']);
srcFiles = strcat(srcPath,[filesep '*.tif']); 
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);
tic

% Input dialog for channels. 6e10 can not be used as name.
prompt = {'Enter space-separed channel names', 'Which is the reference channel?'};
title = 'Alignment';
definput = {'abeta syph psd tmem97', 'syph', };
answer = inputdlg(prompt,title,[1 50],definput);
channels= strsplit(answer{1});
referencechannel=answer{2};% Will be aligned and the transforms used for the other channels.


for Files=1:x
    
    
        % Load all channels in the folder (Similar que a Coloc module).
        if  strfind(srcFiles(Files).name, channels(1))~=0
            disp(strcat ('loading',{' '}, srcFiles(Files).name))            
            Channels{1}.image = read_stackTiff(strcat(srcPath,filesep,srcFiles(Files).name));
            Channels{1}.name=srcFiles(Files).name;
                    
           for iii=2:length(channels)
                Channels{iii}.image = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, channels(1), channels(iii))))));
                Channels{iii}.name=char(strrep(srcFiles(Files).name, channels(1), channels(iii)));
                disp(strcat ('loading',{' '}, Channels{iii}.name)) 
           end
           
           %% REFERENCE CHANNEL FINDING AND PROCESSING
           
            for iii=1:length(channels)
                if  strfind(Channels{iii}.name, referencechannel)~=0
                    reference = Channels{iii}.image;
                    referencename=Channels{iii}.name;
                end
            end
            disp(strcat ('aligning',{' '}, referencename)) 
            [X,Y,z]=size(reference);

            I2=mat2gray(reference);
            meanI2=zeros(size(I2));
            sI2=meanI2;
            bwI2=meanI2;
            join1D = false([X Y]);
            join2D =false(size(bwI2));

            for i=1:z
            %     stret = stretchlim(I2(:,:,i));
                C=-median(median(I2(:,:,i)))/1.5; %%%valor modificable (median,stretch, bins,...)
                meanI2(:,:,i)=imfilter(I2(:,:,i),fspecial('average',10),'replicate');

                sI2(:,: ,i)=meanI2(:,:,i)-I2(:,:,i)-C;
                bwI2(:,:,i)=im2bw(sI2(:,:,i),0);
                bwI2(:,:,i)=imcomplement(bwI2(:,:,i));

                %remove small dots in 2D
                CCbwI2(i).CC=bwconncomp(bwI2(:,:,i),4);
                for ii=1:CCbwI2(i).CC.NumObjects
                        pixId=CCbwI2(i).CC.PixelIdxList{ii};
                            if (length(pixId)>2) 
                                join1D(CCbwI2(i).CC.PixelIdxList{ii})=true;
                            end
                 end   
                 join2D(:,:,i)=join1D;
                 join1D = false([X Y]);
            end 

            I = join2D.*I2;

            optimizer = registration.optimizer.OnePlusOneEvolutionary;
            metric = registration.metric.MattesMutualInformation;

            %[optimizer, metric]  = imregconfig('monomodal'); % for optical microscopy you need the 'monomodal' configuration.
            optimizer.InitialRadius=1e-4;
            optimizer.Epsilon=1.5e-8;
            optimizer.MaximumIterations = 300;

            iref = round(z/2);

            RegisteredRigid = zeros(size(reference));
            RegisteredRigid(:,:,iref) = I(:,:,iref);
            RegisteredAffine = RegisteredRigid;


            tform_ref = affine2d([1 0 0; 0 1 0; 0 0 1]);
            t(iref).rigid = tform_ref;

            % Rigid Body
            for p = iref+1:z
               moving = I(:,:,p); % the image you want to register
               fixed = I(:,:,p-1); % the image you are registering with

               scaleFactorDown = 1/6;
               moving = imresize(moving,scaleFactorDown);
               fixed  = imresize(fixed,scaleFactorDown);

               tform = imregtform(moving,fixed,'rigid',optimizer,metric,'DisplayOptimization',false,'PyramidLevels',3);                   
               tform.T(3,1:2) = tform.T(3,1:2) .* 1/scaleFactorDown;
               t(p).rigid = affine2d(tform.T);
            end

            for p = iref-1:-1:1
               moving = I(:,:,p); % the image you want to register
               fixed = I(:,:,p+1); % the image you are registering with

               scaleFactorDown = 1/6;
               moving = imresize(moving,scaleFactorDown);
               fixed  = imresize(fixed,scaleFactorDown);

               tform = imregtform(moving,fixed,'rigid',optimizer,metric,'DisplayOptimization',false,'PyramidLevels',3);                   
               tform.T(3,1:2) = tform.T(3,1:2) .* 1/scaleFactorDown;
               t(p).rigid = affine2d(tform.T);
            end

            t(iref).T = t(iref).rigid.T;

            for i=iref+1:z
                t(i).T = t(i-1).T*t(i).rigid.T;
            end
            for i=iref-1:-1:1
                t(i).T = t(i+1).T*t(i).rigid.T;
            end

            for i=1:z
                moving = I(:,:,i); % the image you want to register
                tform = affine2d(t(i).T);
                RegisteredRigid(:,:,i) = imwarp(moving,tform,'OutputView',imref2d(size(I(:,:,1))));
            end

            % Affine
            for p = 2:z
               moving = RegisteredRigid(:,:,p); % the image you want to register
               fixed = RegisteredRigid(:,:,p-1); % the image you are registering with

               scaleFactorDown = 1/6;
               moving = imresize(moving,scaleFactorDown);
               fixed  = imresize(fixed,scaleFactorDown);

               tform = imregtform(moving,fixed,'affine',optimizer,metric,'DisplayOptimization',false,'PyramidLevels',3);                   
               tform.T(3,1:2) = tform.T(3,1:2) .* 1/scaleFactorDown;
               t(p).affine = affine2d(tform.T);

            end

            t(1).Taf = t(1).rigid.T;
            for i=2:z
                t(i).Taf = t(i-1).Taf*t(i).affine.T;
            end

            for i=1:z
                moving = RegisteredRigid(:,:,i); % the image you want to register
                tform = affine2d(t(i).Taf);
                RegisteredAffine(:,:,i) = imwarp(moving,tform,'OutputView',imref2d(size(I(:,:,1))));
            end

            % Extract final TFORM to apply it to other channels
            for i=1:z
                t(i).Tdef = t(i).T*t(i).Taf;
                t(i).tformfin = affine2d(t(i).Tdef);
            end
        
            %% APPLY THE TRANSFORM TO THE OTHER CHANNELS
            for iii=1:length(channels)
                disp(strcat ('processing',{' '}, Channels{iii}.name)) 
                for i=1:z
                   moving=Channels{iii}.image(:,:,i);
                   tform = t(i).tformfin;
                   image_reg(:,:,i) = imwarp(moving,tform,'OutputView',imref2d(size(Channels{iii}.image(:,:,1))));
                   outputFileName = strcat(srcPath, [filesep 'Aligned' filesep],Channels{iii}.name, '.tif');
                   imwrite(image_reg(:,:,i),outputFileName,'WriteMode', 'append',  'Compression','none');
                end    
            end 
              
        end
     
        clear Channels
        
end
     toc
    disp('Doner! enjoy! :)')