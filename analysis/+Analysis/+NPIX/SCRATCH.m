for rr = 10:20
    xx(rr,:)= mean(shuffleMatrix{jj}(:,:,rr),1);
end

figure
plot(xx')