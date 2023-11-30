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
  key int eventId;
  key string stateId;
  int Length;
  int ResourceProduction   [ResourceIds];
  int ResourceConsumption[ResourceIds];
}
{State} States = ...;

dvar interval event[e in Events];
dvar interval state[s in States] optional size s.Length;

// Simplification that the total production/consumption for the interval 
// is added at the start of each interval
cumulFunction ResourceUsage[r in ResourceIds] = 
  step(0, StartingCapacity[r])
  + sum (s in States) stepAtEnd(state[s], s.ResourceProduction[r])
  - sum(s in States) stepAtStart(state[s], s.ResourceConsumption[r]);
//  + sum (s in States) pulse(state[s], s.ResourceProduction[r])
//  - sum(s in States) pulse(state[s], s.ResourceConsumption[r]);
  
  
// TODO: Figure out how to implement a objective function equiv to 
//       maximise final value of output resource this would solve the idle bug
subject to {
  // model the event interval based one of many possible states intervals
  forall (e in Events)
    alternative(event[e], all(s in States: s.eventId==e.eventId) state[s]);
    
  // Resource must stay under it's capacity at any time
  forall (r in ResourceIds)
    ResourceUsage[r] <= TotalCapacity[r];
    
  // Previous event must end before succesor event starts    
  forall (e1 in Events, e2id in e1.NextPossibleEvents)
    endBeforeStart(event[e1], event[<e2id>]);
}
