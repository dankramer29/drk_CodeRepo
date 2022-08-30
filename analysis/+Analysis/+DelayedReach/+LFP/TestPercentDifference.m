%% Testing Percent Difference Equations

%% Setup Example Waves

x = 0.1:0.01:20;
R = sin(x)+cos(2*x./3)+1;
L = (-sin(x)-1+cos(x))+((x.^(1/2)) - 3);

%%
% Plot of original
figure
plot(x, R, 'r', x, L, 'b')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('Original')
legend('Right', 'Left')
%% (R-L) / L with original signs
figure
diff_1 = (R-L) ./ L;
plot(x, R, 'r', x, L, 'b', x, diff_1, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-5 5])
xlim([0 20.5])
title('(R-L) ./ L')
legend('Right', 'Left', 'diff')

% %% Absolute value of denominator
% figure
% diff_2 = (R-L) ./ abs(L);
% plot(x, R, 'r', x, L, 'b', x, diff_2, 'g--')
% grid on
% ax = gca;
% ax.XAxisLocation = 'origin';
% ylim([-10 10])
% xlim([0 20.5])
% title('(R-L) ./ abs(L)')
% legend('Right', 'Left', 'diff_2')
% 
% %% Absolute value of the numerator
% figure
% diff_3 = abs(R-L) ./ L;
% plot(x, R, 'r', x, L, 'b', x, diff_3, 'g--')
% grid on
% ax = gca;
% ax.XAxisLocation = 'origin';
% ylim([-10 10])
% xlim([0 20.5])
% title('abs(R-L) ./ L')
% legend('Right', 'Left', 'diff_3')
% 
% %% Absolute value of both numerator and denominator
% figure
% diff_4 = abs( (R-L) ./ L);
% plot(x, R, 'r', x, L, 'b', x, diff_4, 'g--')
% grid on
% ax = gca;
% ax.XAxisLocation = 'origin';
% ylim([-10 10])
% xlim([0 20.5])
% title('abs( (R-L) ./ L)')
% legend('Right', 'Left', 'diff_4')

%% (R-L) / (R + L)
% My pick. Positive when R > L, negative when R < L. No asymptotes
% as L -> 0
figure
diff_5 = (R-L) ./ (R+L);
plot(x, R, 'r', x, L, 'b', x, diff_5, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('(R-L) ./ (R+L)')
legend('Right', 'Left', 'diff_5')
%% Absolute value of denominator inputs
figure
diff_6 = (R-L) ./ (abs(R)+abs(L));
plot(x, R, 'r', x, L, 'b', x, diff_6, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('(R-L) ./ (abs(R)+abs(L))')
legend('Right', 'Left', 'diff_6')

%% Absolute value of numerator
figure
diff_7 = abs(R-L) ./ (R+L);
plot(x, R, 'r', x, L, 'b', x, diff_7, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('abs(R-L) ./ (R+L)')
legend('Right', 'Left', 'diff_7')

%% Percent Difference from Physics Txt
% I trusted them.
figure
diff_8 = abs(R-L) ./ ((R+L)./2);
plot(x, R, 'r', x, L, 'b', x, diff_8, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('abs(R-L) ./ ((R+L)./2)')
legend('Right', 'Left', 'diff_8')

%% Absolute value of sum of denominator
figure
diff_9 = (R-L) ./ abs(R+L);
plot(x, R, 'r', x, L, 'b', x, diff_9, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('(R-L) ./ abs(R+L)')
legend('Right', 'Left', 'diff_8')

%%
figure
diff_10 = (abs(R)-abs(L)) ./ (abs(R) + abs(L));
plot(x, R, 'r', x, L, 'b', x, diff_10, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('(abs(R)-abs(L)) ./ (abs(R) + abs(L))')
legend('Right', 'Left', 'diff_8')

%%
figure
diff_11 = abs(R) ./ (abs(R)+abs(L));
diff_11 = (diff_11*2) -1;
plot(x, R, 'r', x, L, 'b', x, diff_11, 'g--')
grid on
ax = gca;
ax.XAxisLocation = 'origin';
ylim([-10 10])
xlim([0 20.5])
title('abs(R) ./ (abs(R)+abs(L))')
legend('Right', 'Left', 'diff_11')
