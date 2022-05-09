function Iobr = imobr(I,se)
% perform opening by reconstruction
% input: image I and structural element se (use strel function to create it)
% output: opened image Iobr;

    Ie = imerode(I,se);%ordfilt2(Imresult,1,ones(33));
    Iobr = imreconstruct(Ie, I);
