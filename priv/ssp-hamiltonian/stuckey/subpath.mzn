include "circuitpreds.mzn";
int: numlocations;      % number of locations
set of int: Locations = 1..numlocations; 
int: numactivities;     % number of activities
set of int: Activities = 1..numactivities;
int: maxLegLen;     % length of longest edge in network

% travel times between locations 
% -1 means no direct connection exists
array[Locations,Locations] of int: travelTime; 

% activity locations
array[Activities,Locations] of bool: activityAvailable;

% successor variables
array[Locations] of var 1..numlocations+1: succ;

% only use allowed legs
constraint forall(loc1, loc2 in Locations) 
  ( travelTime[loc1,loc2] < 0 -> succ[loc1] != loc2 );

% visit at least one location with every activity
constraint forall(act in Activities)
  ( exists(loc in Locations where activityAvailable[act,loc]) 
          (succ[loc] != loc) );

% successors must form a path
var Locations: start;
var Locations: end;
constraint subpath(succ, start, end);

% variable for the length of the longest leg
var 1..maxLegLen: maxleg;
constraint forall(loc1, loc2 in Locations) 
  ( succ[loc1] == loc2 -> maxleg >= travelTime[loc1,loc2] );

solve minimize maxleg;
