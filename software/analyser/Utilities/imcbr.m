function Icbr = imcbr(I,se)
% perform closing by reconstruction
% input: image I and structural element se (use strel function to create it)
% output: closed image Icbr;

    Ie = imdilate(I, se);
    Icbr = imcomplement(imreconstruct(imcomplement(Ie), imcomplement(I)));