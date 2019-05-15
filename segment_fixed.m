function segment_fixed(srcPath,Thresholdvalue, min,max)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Programa de segmentacio de sinapsis %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clc % Clear command window.
%clearvars; % Get rid of variables from prior run of this m-file.
%clear all;
disp('\n Running synapsis detector with the following parameters...');
fprintf('srcPath is: %s \n',srcPath)
fprintf('Threshold value: %d \n',Thresholdvalue)
fprintf('Object min size: %d \n',min)
fprintf('Object MAX size: %d \n',max)

workspace; % Make sure the workspace panel with all the variables is showing.
imtool close all;  % Close all imtool figures.
format compact;
%format compact;
captionFontSize = 14;
warning off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Read the directory %%%%%%%%%%%
srcFiles = strcat(srcPath,[filesep '*.tif']);  % the folder in which ur images exists
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);
    
mkdir(srcPath,[filesep 'Segmented']);

    %%%%%% Save segmentation paramenters %%%%%%
    fileID = fopen(strcat(srcPath,[filesep 'Segmented' filesep 'parameters.txt']),'w+');
    fprintf(fileID,'SrcPath: %s\r\nThresholdvalue: %s\r\nObject min size: %d\r\nObject MAX size: %d',srcPath,Thresholdvalue,min,max);
    fclose(fileID);
    check = 1;
%%
for jj = 1 : x

    %%% Check if exists segmentation
    seq_name = srcFiles(jj).name;
    seq_name = seq_name(1:(end-4)); % necessari per guardar imatges
    
    if and(exist(strcat(srcPath,[filesep 'Segmented' filesep],seq_name,'.tif'))>0,check == 1)
        choice = questdlg(strcat('It seems that the sequence ',srcFiles(jj).name,'is already processed. Do you want to process it again? And the others?'), ...
        'Do you want to process it again? And the others?', ...
        'Yes','Yes to all','No to all','No to all');
        % Handle response
        switch choice
            case 'Yes'
                answ = questdlg('Do you want to remove the old sequence?', ...
                'Remove old sequences', ...
                'Yes','No','Yes');
                    switch answ
                        case 'Yes'
                            %sprintf('Sequence %s will be rewrited',srcFiles(jj).name)
                            delete(strcat(srcPath,[filesep 'Segmented' filesep],seq_name,'.tif'));
                        case 'No'
                            fprintf('Sequence %s will be stacked into the old file\n',srcFiles(jj).name)
                    end
                fprintf('Processing sequence %s again\n',srcFiles(jj).name)
            case 'Yes to all'
                answ = questdlg('Do you want to remove the old sequences?', ...
                'Remove old sequences?', ...
                'Yes','No','Yes');
                    switch answ
                        case 'Yes'
                            disp('The images will be rewrited.')
                            delete(strcat(srcPath,[filesep 'Segmented' filesep],'*.tif'));
                        case 'No'
                            disp('The images will be stacked into the old file')
                    end
                disp('Processing sequences...')
                check = 0;
            case 'No to all'
                print('DONE')
                check = 0;
                break;
        end
    end
    
    I = read_stackTiff(strcat(srcPath,filesep,srcFiles(jj).name)); % LLEGIM TOT L'STACK DE .TIF
    seq(jj).name = srcFiles(jj).name;
    seq(jj).I = im2uint16(I);
    [f,c,p]=size(I);
    
    %%% Check if I is a bw image (Segmented) 
    
    isBinaryImage = all( I(:)==0 | I(:)==1);
    if isBinaryImage
         fprintf('The image %s is a bw image. It will not be processed\n', seq(jj).name);
    else
        
    %% BW thresholding with fixed threshold value
    Ibw = I>Thresholdvalue;

     join1D = false([f c]);
     join2D =false(size(Ibw));
                %remove small dots in 2D
                for i=1:p
                    CCbwImat(i).CC=bwconncomp(Ibw(:,:,i),4);
                    for ii=1:CCbwImat(i).CC.NumObjects
                            pixId=CCbwImat(i).CC.PixelIdxList{ii};
                                if (length(pixId)>2) 
                                    join1D(CCbwImat(i).CC.PixelIdxList{ii})=true;
                                end
                     end   
                     join2D(:,:,i)=join1D;
                     join1D = false([f c]);
                end 
     
     
    %% Extract connectivity and size information of each object
        CC = bwconncomp(join2D,6);
        props=regionprops(CC, 'PixelList');
        join3D =false(size(join2D));    
      
    for i=1:CC.NumObjects
        object=diff(props(i).PixelList);
        if (sum(object(:,3))>0 && length(object(:,1))+1>min && length(object(:,1))+1<max) % Check the dimensions of this label
                    join3D(CC.PixelIdxList{i})=true;     
        end
    end


    %% Save and print results

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%% Guardem les imatges %%%%%%%%%%%%%%%%%

        for i=1:p
                outputFileName = strcat(srcPath,[filesep 'Segmented' filesep],seq_name,'.tif');
                imwrite(uint16(join3D(:,:,i)),outputFileName, 'WriteMode', 'append',  'Compression','none');
        end

        %%%%%%% i ho treiem per pantalla %%%%%%%%%%%%%%%%
   
          fprintf(seq_name, ' done');
          fprintf('\n');         
    end
end

 fprintf('Done, enjoy!');
end