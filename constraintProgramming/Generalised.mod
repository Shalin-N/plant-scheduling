/*********************************************
 * OPL 22.1.1.0 Model
 * Author: shali
 * Creation Date: 24/05/2023 at 8:45:00 AM
 *********************************************/

 /*********************************************
 * OPL 22.1.1.0 Model
 * Author: shali
 * Creation Date: 9/05/2023 at 2:53:01 PM
 *********************************************/
using CP;

int numIntervals = 10;
int maximumDirtyOffIntervals = 2;
int maximumCleaningIntervals = 3;
int maximumRunningIntervals = 8;

int numMachines = 1;
int startingSiloCapacity = 50;
int maximumSiloCapacity = 100;
int machineProductionRate = 10;
int machineConsumptionRate = 5;

range Machines = 1..numMachines;
{string} Activities = { 
   "Running", 
   "Dirty", 
   "Cleaning"
};

dvar interval machineProduce[Machines][Activities] optional size 1..numIntervals;
dvar interval machineConsume[Machines][Activities] optional size 1..numIntervals;

cumulFunction cleanerUse = sum (m in Machines) pulse(machineProduce[m]["Cleaning"], 1);
cumulFunction siloCapacity =  step(0, startingSiloCapacity) 
	+ sum (m in Machines) stepAtEnd(machineProduce[m]["Running"], inferred(lengthOf(machineProduce[1]["Running"]))*machineProductionRate) 
	- sum (m in Machines )stepAtStart(machineConsume[m]["Running"], inferred(lengthOf(machineConsume[1]["Running"]))*machineConsumptionRate);


subject to {
  // Sum of all intervals should equal max
  forall(m in Machines) {
    sum(a in Activities) sizeOf(machineProduce[m][a]) >= numIntervals;
    sum(a in Activities) sizeOf(machineConsume[m][a]) >= numIntervals;
  }

  // Constrain activities individually
  forall(m in Machines) {
     sizeOf(machineProduce[m]["Running"]) <= maximumRunningIntervals;
     sizeOf(machineProduce[m]["Dirty"]) <= maximumDirtyOffIntervals;
     sizeOf(machineProduce[m]["Cleaning"]) <= maximumCleaningIntervals;
     
     sizeOf(machineConsume[m]["Running"]) <= maximumRunningIntervals;
     sizeOf(machineConsume[m]["Dirty"]) <= maximumDirtyOffIntervals;
     sizeOf(machineConsume[m]["Cleaning"]) <= maximumCleaningIntervals;
  }
  

// No overlapping activities
  forall(m in Machines, a1 in Activities, a2 in Activities : a1 < a2) {
    endBeforeStart(machineProduce[m][a1], machineProduce[m][a2]);
    endBeforeStart(machineConsume[m][a1], machineConsume[m][a2]);
  }


  // Resource capacities 
  cleanerUse <= 1;
  siloCapacity <= maximumSiloCapacity;
}