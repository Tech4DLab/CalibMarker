function out1 = resize2dWithNans(inimg,scale,method)
%this stops nans from propagating (and corrupting) the resulting resized
%image.
%Toby Collins 2008
if nargin<3
    out1=imresize(inimg,scale);
else
    out1=imresize(inimg,scale,method);
    
end

out2=imresize(inimg,scale,'nearest');
out1(find(isnan(out1)))=out2(find(isnan(out1)));

