st = 190000;
yrs = 25;
int = .06;
mnth = 10000;
for ii = 1:yrs
    mnthYear = mnth*12;
    addAmt = st*int;
    st = st + addAmt+mnthYear;
end