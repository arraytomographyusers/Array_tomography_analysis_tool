function [join2D,CC] = segment_connectivity(bwI2, minobj, maxobj)

    CC = bwconncomp(bwI2,6);
    join2D =false(size(bwI2));
    [f,c,p] = size(bwI2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%% Check object connectivity between slides %%%%%%%%%%%
   
    for i=1:CC.NumObjects
        pixId=CC.PixelIdxList{i};
        if and(length(pixId)>minobj,length(pixId)<maxobj) % Check the dimensions of this label
            dim=1;
            for j=1:length(pixId)-1 % if it has more than one dimension, check if it is a 3D object
                if pixId(j,1)+ f*c/1.5 < pixId(j+1,1) % [f,c]=size(I) -- f*(c-2) 
                    dim=dim+1;
                end
                if dim>1 %the object has to be in at least 3 slides
                    join2D(CC.PixelIdxList{i})=true;
                end
            end
        end
    end
    CC=bwconncomp(join2D, 6);
end
