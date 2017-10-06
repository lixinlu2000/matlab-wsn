load('ngh_en1.mat')
load('ph1.mat')
alfa_coefficient = 0.7;
bata_coefficient = 1.0 - alfa_coefficient;
for i=1:12
    tmp = ph(i).^alfa_coefficient * ngh_en(i).^bata_coefficient;
    tmp_2 = dot(ph.^alfa_coefficient,ngh_en.^bata_coefficient);
    new(i) = tmp / tmp_2;
end
if(a>0)
    b=1;
else
    b=-1;
end