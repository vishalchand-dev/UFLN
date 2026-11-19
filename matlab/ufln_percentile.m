function q=ufln_percentile(x,p)
x=sort(x(isfinite(x)));
if isempty(x),q=nan;return;end
if numel(x)==1,q=x;return;end
r=1+(numel(x)-1)*(p/100);lo=floor(r);hi=ceil(r);
if lo==hi,q=x(lo);else,q=x(lo)+(r-lo)*(x(hi)-x(lo));end
end
