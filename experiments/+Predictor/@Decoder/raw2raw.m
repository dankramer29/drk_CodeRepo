function x=raw2raw(obj,x)

% convert input x into the state representation of x.  If x is already in
% state form it should staty the same.  
x=obj.position2state(x);
x=obj.model2raw(obj.raw2model(x,[]));