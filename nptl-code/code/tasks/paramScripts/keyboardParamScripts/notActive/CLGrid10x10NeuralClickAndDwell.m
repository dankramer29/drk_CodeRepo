gridTask;
gridNeuralClickAndDwellTask;


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_10X10));

addCuedRandomGridSequence(70, 100); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;
