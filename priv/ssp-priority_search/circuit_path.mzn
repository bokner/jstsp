include "circuitpreds.mzn";
int: numlocations = 4;       % number of locations
set of int: Locations = 1..numlocations; 
int: maxLegLen = 9;     % length of longest edge in network

% travel times between locations 
% -1 means no direct connection exists
array[Locations,Locations] of int: travelTime = array2d(1..numlocations, 1..numlocations, [1,2,3,5, 4,2,3,5, 3,9,8,2, 7,7,3,2]); 

% successor variables
array[Locations] of var 1..numlocations+1: succ;

% only use allowed legs
constraint forall(loc1, loc2 in Locations) 
  ( travelTime[loc1,loc2] < 0 -> succ[loc1] != loc2 );

% successors must form a path
var Locations: start;
var Locations: end;
constraint path(succ, start, end);

% variable for the length of the longest leg
var 1..maxLegLen: maxleg;
constraint forall(loc1, loc2 in Locations) 
  ( succ[loc1] == loc2 -> maxleg >= travelTime[loc1,loc2] );

solve minimize maxleg;