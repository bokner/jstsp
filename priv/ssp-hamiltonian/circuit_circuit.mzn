include "circuitpreds.mzn";
int: numlocations;      % number of locations
set of int: Locations = 1..numlocations; 
int: maxLegLen;     % length of longest edge in network

% travel times between locations 
% -1 means no direct connection exists
array[Locations,Locations] of int: travelTime; 

% successor variables
array[Locations] of var Locations: succ;

% only use allowed legs
constraint forall(loc1, loc2 in Locations) 
  ( travelTime[loc1,loc2] < 0 -> succ[loc1] != loc2 );

% successors must form a circuit
constraint circuit(succ);

% variable for the length of the longest leg
var 1..maxLegLen: maxleg;
constraint forall(loc1, loc2 in Locations) 
  ( succ[loc1] == loc2 -> maxleg >= travelTime[loc1,loc2] );

solve minimize maxleg;
