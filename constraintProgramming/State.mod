using CP;

int NbResources = ...;
range ResourceIds = 0..NbResources-1; 
int TotalCapacity[r in ResourceIds] = ...;
int StartingCapacity[r in ResourceIds] = ...;

tuple Event {
  key int id;
  int     Length;
  int     ResourceProduction[ResourceIds];
  int     ResourceConsumption[ResourceIds];
  {int}   NextPossibleEvents; 
}
{Event} Events = ...;

dvar interval itvs[e in Events] size e.Length;

// Simplification that the total production/consumption for the interval 
// is added at the start of a interval
cumulFunction resourceUsage[r in ResourceIds] = 
  step(0, StartingCapacity[r])
  + sum (e in Events) stepAtStart(itvs[e], e.ResourceProduction[r])
  - sum(e in Events) stepAtStart(itvs[e], e.ResourceConsumption[r]);

subject to {
  // Resource must stay under it's capacity at any time
  forall (r in ResourceIds)
    resourceUsage[r] <= TotalCapacity[r];
    
  // Previous event must end before succesor event starts
  forall (e1 in Events, e2id in e1.NextPossibleEvents)
    endBeforeStart(itvs[e1], itvs[<e2id>]);
}
