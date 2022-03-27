function Vout = HGW(Vin,diam,switch_item)

[hei,wid] = size(Vin);
Vout = zeros(hei,wid);
PSA = mod(diam-(wid-1),diam)-1;
gs = zeros(1,wid);
hs = zeros(1,wid);
if switch_item == 0 % 1-D minimum filter
    for y = 0 : 1 : hei-1
        for x = 0 : 1 : wid-1
            if mod(x,diam) == 0
                gs(x+1) = Vin(y+1,x+1);
            else
                gs(x+1) = min(gs(x),Vin(y+1,x+1));
            end
        end
        for x = wid-1 : -1 : 0
            if x == wid-1 || mod(x+1,diam) == 0
                hs(x+1) = Vin(y+1,x+1);
            else
                hs(x+1) = min(hs(x+2),Vin(y+1,x+1));
            end
        end
        for x = 0 : 1 : wid-1
            if x-(diam-1)/2 < 0
                Vout(y+1,x+1) = gs(x+1+(diam-1)/2);
            elseif x+(diam-1)/2 >= wid
                if x+(diam-1)/2 < wid+PSA
                    Vout(y+1,x+1) = min(gs(wid),hs(x+1-(diam-1)/2));
                else
                    Vout(y+1,x+1) = hs(x+1-(diam-1)/2);
                end
            else
                Vout(y+1,x+1) = min(gs(x+1+(diam-1)/2),hs(x+1-(diam-1)/2));
            end
        end
    end
elseif switch_item == 1 % 1-D maximum filter
    for y = 0 : 1 : hei-1
        for x = 0 : 1 : wid-1
            if mod(x,diam) == 0
                gs(x+1) = Vin(y+1,x+1);
            else
                gs(x+1) = max(gs(x),Vin(y+1,x+1));
            end
        end
        for x = wid-1 : -1 : 0
            if x == wid-1 || mod(x+1,diam) == 0
                hs(x+1) = Vin(y+1,x+1);
            else
                hs(x+1) = max(hs(x+2),Vin(y+1,x+1));
            end
        end
        for x = 0 : 1 : wid-1
            if x-(diam-1)/2 < 0
                Vout(y+1,x+1) = gs(x+1+(diam-1)/2);
            elseif x+(diam-1)/2 >= wid
                if x+(diam-1)/2 < wid+PSA
                    Vout(y+1,x+1) = max(gs(wid),hs(x+1-(diam-1)/2));
                else
                    Vout(y+1,x+1) = hs(x+1-(diam-1)/2);
                end
            else
                Vout(y+1,x+1) = max(gs(x+1+(diam-1)/2),hs(x+1-(diam-1)/2));
            end
        end
    end
else
    Vout = Vin;
end

end