function segment_previsualize(srcPath,name,ws,sf,method,min,max) 

srcFiles = strcat(srcPath,[filesep '*.tif']);  % the folder in which ur images exists
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);

I = read_stackTiff(strcat(srcPath,filesep,name)); % read tiff stack
[f,c,p]=size(I);

Imat = mat2gray(I);

%% Cropping image
if and(f>251,c>151) %set random crop of the image
    Icropp=zeros(151,251);
    for i=1:p
        Icropp(:,:,i) = imcrop(Imat(:,:,i),[round(f/3) round(c/3) 250 150]);
    end
else
    Icropp = Imat;
end
%% BW thresholding with mean or median local filter

meanI2=zeros(size(Icropp));
medianI2=meanI2;
sI2=meanI2;
bwI2=meanI2;

switch method
    % Local mean filter  (a triar entre aquest i el median filter)
    case 'mean'
        for i=1:p
        %     stret = stretchlim(I2(:,:,i));
            C=-mean(mean(Icropp(:,:,i)))/sf; %%%modificable value(median, bins,...)
            meanI2(:,:,i)=imfilter(Icropp(:,:,i),fspecial('average',ws),'replicate');

            sI2(:,:,i)=meanI2(:,:,i)-Icropp(:,:,i)-C;
            bwI2(:,:,i)=im2bw(sI2(:,:,i),0);
            bwI2(:,:,i)=imcomplement(bwI2(:,:,i));
        end

        % Local median filter 
    case 'median'
        for i=1:p
        %     stret = stretchlim(I2(:,:,i));
            C=-median(median(Icropp(:,:,i)))/sf; %%% modificable value (median, bins,...)
            medianI2(:,:,i)=medfilt2(Icropp(:,:,i),[ws ws]);

            sI2(:,:,i)=medianI2(:,:,i)-Icropp(:,:,i)-C;
            bwI2(:,:,i)=im2bw(sI2(:,:,i),0);
            bwI2(:,:,i)=imcomplement(bwI2(:,:,i));
        end 

    otherwise 
        fprintf('\n The method %s is not implemented yet...\n', method);
end
    
%% Extract connectivity and size information of each object

[join, CC] = segment_connectivity(bwI2,min,max);

implay(join)
implay(Icropp*5)

end
