function varargout=info
% FLOOD application information file

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Gyula Simon, gyula.simon@vanderbilt.edu
% Last modified: Sep 19, 2002  by GYS

title1='Application SPANTREE';
str1={  'This application illustrates the building of a spanning tree.'; ...
        '';...
        'The sender mote transmits a message. Each mote receiving the';...
        'message for the first time selects the transmitter of this';...
        'message to be its parent, and retransmits the message.' ;...
        '';...
        'Each child displays its parent''s index, as well as the number';...
        'of hops. The LEDs also show the distance from the root:';...
        'red: hops=1..2, green: hops=3..5, yellow: hops>5.';...
        '';...
        'You may want to switch off the LED display to see the tree ';...
        'structure more clearly.';...
        '';...
        'It''s interesting to compare the radio channel models; the ND';...
        'model provides more collisions, thus different tree structure.';...
        '';...
        'Modify the simulaton parameters to see the effect on the spanning';...
        'tree generation.';...
        ''};
if nargout==0
    helpwin({ title1, str1}, 'Application Info')
else
    varargout={ title1, str1};
end