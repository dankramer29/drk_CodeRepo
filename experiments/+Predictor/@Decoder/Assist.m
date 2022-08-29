function x_c = Assist(obj,x_c,xIdeal_c,assistType,assistLevel)


% Use assistance
if any(isnan(xIdeal_c)) % No specificed target
    x_c = x_c;
else
    
    switch assistType
        case 'WeightedAverage'
            x_c = (1-assistLevel)*x_c + (assistLevel)*xIdeal_c;
            
        case 'Projection'
            %%
            if size(x_c,2) == 3
                weight = max([(dot(x_c,xIdeal_c))/(norm(x_c')*norm(xIdeal_c')),0]);
            else
                weight = max([((x_c'*xIdeal_c))/(norm(x_c')*norm(xIdeal_c')),0]);
            end
            x_c= (1-assistLevel)*x_c + (assistLevel)*weight*x_c;
            %             x_c=weight*x_c;
            
        case 'DirectionRail'
            if Utilities.mnorm(xIdeal_c) == 0
                x_c=assistLevel*xIdeal_c+(1-assistLevel)*(x_c);
            else
                xIdealNorm = xIdeal_c/norm(xIdeal_c);
                if size(x_c,2) == 3
                    V1 = dot(x_c,xIdealNorm);
                else
                    V1 = x_c'*xIdealNorm;
                end
                
%                 V1(V1<0)=0;
                
                V1True = V1*xIdealNorm;
                
                x_c = V1True + (1-assistLevel)*(x_c-V1True);
            end
        case 'ErrorRail'
            %%
            if Utilities.mnorm(xIdeal_c) == 0
                x_c = assistLevel*xIdeal_c + (1-assistLevel)*(x_c);
            else
                xIdealNorm = xIdeal_c/norm(xIdeal_c);
                if size(x_c,2) == 3
                    V1 = dot(x_c,xIdealNorm);
                else
                    V1 = x_c'*xIdealNorm;
                end
                
                V1(V1<0) = 0;
                
                if any(x_c) ~= 0
                    V1True = V1*xIdealNorm;
                else
                    V1True = xIdeal_c;
                end
                
                x_c = V1True + (1-assistLevel)*(x_c-V1True);
            end
    end
    
end
