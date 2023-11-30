// --------------------------------------------------------------------------
// Licensed Materials - Property of IBM
//
// 5725-A06 5725-A29 5724-Y48 5724-Y49 5724-Y54 5724-Y55
// Copyright IBM Corporation 1998, 2022. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
// --------------------------------------------------------------------------

using CP;

int NbResources = ...;
range ResourceIds = 0..NbResources-1; 
int TotalCapacity [ResourceIds] = ...;
int StartingCapacity [ResourceIds] = ...;

tuple Event {
  key int eventId;
  string machineId;
  {int}   NextPossibleEvents;
}
{Event} Events = ...;

tuple State {
  key string machineId;
  key string stateId;
  int Length;
  int ResourceProduction   [ResourceIds];
  int ResourceConsumption[ResourceIds];
}
{State} States = ...;

dvar interval event[e in Events];
dvar interval state[s in States] optional size s.Length;

// Simplification that the total production/consumption for the interval 
// is added at the start of a interval
cumulFunction ResourceUsage[r in ResourceIds] = 
  step(0, StartingCapacity[r])
  + sum (s in States) stepAtStart(state[s], s.ResourceProduction[r])
  - sum(s in States) stepAtStart(state[s], s.ResourceConsumption[r]);
  
subject to {
  // model the event interval based one of many possible states intervals
  forall (e in Events)
    alternative(event[e], all(s in States: s.machineId==e.machineId) state[s]);
    
  // Resource must stay under it's capacity at any time
  forall (r in ResourceIds)
    ResourceUsage[r] <= TotalCapacity[r];
    
  // Previous event must end before succesor event starts    
  forall (e1 in Events, e2id in e1.NextPossibleEvents)
    endBeforeStart(event[e1], event[<e2id>]);
   
}
