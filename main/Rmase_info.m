function varargout=info
% generator application information file

% ***	
% ***	 Copyright 2002, Vanderbilt University. All rights reserved.
% ***
% ***    This program is distributed in the hope that it will be useful,
% ***    but WITHOUT ANY WARRANTY; without even the implied warranty of
% ***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% ***
% ***

% Written by Lukas D. Kuhn, lukas.kuhn@parc.com
% Last modified: Nov. 24, 2003  by LK

title1='Application Rmase';
str1={  'This application is for generating network topology and applications'; ...
        'and produces performance metrics for comparing various routing algorithms.'; ...
        'It consists of three components: topology generator, radio parameters and fault model';...
        'and application generator';...
        '';...
        'Network Model';... 
        '';...
        'The network model primarily specifies the topology';...
        'of the network, i.e., the relative placement of nodes.';...
        'The basic topology is a rectangular x-y grid.';...
        'The grid size, spacing, shift, density, and offset parameters';...
        'allows one to specify a variety of topologies,';
        'including triangular grids, long parallel lines,';...
        'and random networks of various kinds.';...
        'It also allows to use any user given topology file.';...
        '';...
        '';...
        '';...
        'Grid Size (Xsize,Ysize)';...
        '';...
        'Numbers of grid points in x and y directions.';...
        '';...
        '';...
        '';...
        'Grid Spacing (Xdist,Ydist)';...
        '';...
        'Spacing (distance) of the grid points in x and y directions.';...
        'The covered area is Xsize*Xdist by Ysize*Ydist.' ;...
        '';...
        '';...
        '';...
        'Grid Offset (Xoffset,Yoffset)';...
        '';...
        'Maximum random offset (distance, positive number) for nodes ';...
        'to be placed away from specified node position. Given node ';...
        'position (px,py) as determined by spacing, shift, and density,';...
        'the actual position is (px+rx*Xoffset,py+ry*Yoffset),';...
        'where rx and ry are random variables in the interval [-1,1] ';...
        'with uniform distribution. Large offset values simulate a ';...
        'network with randomly positioned nodes.';...
        '';...
        '';...
        '';...
        'Grid Density (Xdensity,Ydensity)';...
        '';...
        'Number of nodes per side from grid point to grid point (extending';...
        'out from the last grid point in each row and column). The total';...
        'number of nodes is Xsize*Ysize*(Xdensity+Ydensity-1).';...
        '';...
        '';...
        '';...
        'Grid Shift (Xshift,Yshift,wraparound)';...
        '';...
        'Shift of the grid points from one row/column to the next';...
        'as a percentage of grid spacing. Given one grid point at (i,j),';...
        'its position is shifted by ((j-1)* Xshift, (i-1)* Yshift).';...
        'Grid points shifted at the end of a row or column wrap around,';...
        'so the number of grid points is always the same.';...
        'To be even more general, one may specify Xshift, Yshift,';...
        'where Xshift is a vector of shifts with size Xsize*Xdensity';...
        'and Yshift is a vector of shifts with size Ysize*Ydensity.';...
        'Given one grid point at (i,j), its position is shifted by';...
        '((j-1)* Xsize(i), (i-1)* Ysize(j)). In this case, one may choose ';...
        'either wrap around (=1) or not (=0).';...
        'For example, two non-parallel lines can be modeled by ';...
        'grid size (2, 10), Xshift=[0,0.3], Yshift=[0,0,0,0,0,0,0,0,0,0].';...
        '';...
        '';...
        '';...
        'Alive Probability (AliveProb)';...
        '';...
        'Probability of a mote being alive, (0, 1]';...
        '';...
        '';...
        '';...
        'UseTopologyFile (UseTopologyFile, TopologyFileName)';...
        '';...
        'Use any user defined topology file that outputs [topology, mote_IDs]';...
        '';...
        '';...
        '';...
        'Holes (HPosX,HPosY,HLengthX,HHeigthY,HAngle)';...
        'and/or';...
        'RandHoles(RHNumber,RHLengthX,RHLengthXRand,RHHeigthY,RHHeigthYRand)';...
        '';...
        'A specific position and size for one hole could be specified';...
        '(e.g., center of the network), where (HPosX,HPosY) is the center of';...
        'the rectangular area, HAngle is the orientation of the x axis of';...
        'the rectangular, HLengthX and HHeigthY specify the length and ';...
        'the heigth of the rectangular.';...
        'Furthermore, a number of randomly-centered  holes can be specified.';...
        'In this case, RHNumber is the number of holes, RHLengthXRand,';...
        'RHHeigthYRand are maximum deviation from the nominal values ';...
        'of RHLengthX, RHHeigthY with uniform random distribution.';...
        'Variation: the impacted nodes are moved to the boundary (border=1)';...
        'of the rectangular. This allows one to simulate the dense placement';...
        'of nodes around high-interest areas such as buildings, or specifies';... 
        'the percentage of failed motes in the hole.';...
        '';...
        '';... 
        'HBorder: a real number that bring the motes in the hole to its border'
        '';...
        '';...
        'Radio Parameters and Fault Model';...
        '';...
        'Signal Strength (Strength)';...
        'Unit cost of transmitting a packet'
        '';...
        'Initial Power (InitPower, RandPower)';...
        'Initial power units: InitPower+RandPower*(rand-0.5)*2';...
        '';...
        'Fault Model (FailProb, WakeupProb)';...
        'Fail or wakeup probabilities';...
        '';...
        'Application Model';...
        '';
        'The application model specifies sources and destinations, as well as data rate';...
        'for simulations. It consists of three sets: Source, Destination and Simulation';...
        '';...
        'Application Source';...
        '';...
        'Source Type (SourceType): static mobile dynamic';...
        '';...
        'Source Center Type (SourceCenterType): fixed random';...
        '';...
        'Source Center (SourceCenterX, SourceCenterY): if type is fixed, specifies the center';...
        '';...
        'Source Radius (SourceRadius): specifies the radius from the center';...
        '';...
        'Source Percentage (SourcePercentage): between 0 and 1, the percentage of nodes within the radius';...
        '';...
        'Source Unique (SourceUnique): check for unique source';...
        '';...
        'Source Speed (SourceSpeedX, SourceSpeedY, RandSourceSpeed): if mobile or dynamic, specifies the speed of the center';...
        '';...
        'Application Destination: same as Source, replace Source with Destination';...
        '';...
        'Application Simulation';...
        '';...
        'Source Rate (SourceRate): the number of packets per second';...
        '';...
        'Initialization Time (InitTime): the time that data packets start (in seconds)';...
        '';...
        'Check Source Destination Pair (CheckSourceDest): if source or destination is random, check the distance';...
        'between them';...
        '';...
        'Pair Distance (PairNorminalDist, PairRandDist): if check, make sure the distance between them is between';...
        '(PairNorminalDist-PairRandDist)*maxD and (PairNorminalDist+PairRandDist)*maxD';...
        'where maxD is the maximum distance in the nextwork';...
        '';...
        'Use Trace File (UseTraceFile, TraceFileName';...
        'specifies the user defined file to use, (ID, time) array';...
        '';...
        '';...
        'See the Rmase document for the layered routing architecture and data types in routing.';...
        ''};
if nargout==0
    helpwin({ title1, str1}, 'Application Info')
else
    varargout={ title1, str1};
end
