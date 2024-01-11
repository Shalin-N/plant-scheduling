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
 // Produce -> Silo -> Consume
 //     \                 /
 //           cleaner
 
 // 1 running
 // 2 cleaning
 // 3 running
 // ....
 
using CP;

int numIntervals = 60;
int intervalLength = 60; // 1 interval is a minute
int eightHours = ftoi(60/intervalLength*8);
int twoHours = ftoi(60/intervalLength*2);

int maximumCleaningIntervals = 2;
int maximumRunningIntervals = 8;

int numMachines = 1;
int startingSiloCapacity = 100;
int maximumSiloCapacity = 1000;
int machineProductionRate = 10;
int machineConsumptionRate = 9;

range Machines = 1..numMachines;
range Activities = 1..numIntervals;

//{int} Running = {a | a in Activities : ((a - 1) % (eightHours + twoHours)) < eightHours};
//{int} Cleaning = {i | i in Activities : !(i in Running)};

{int} Running = {a | a in Activities : a % 2 == 1};
{int} Cleaning = {a | a in Activities : a % 2 == 0};

dvar interval machineProduce[Machines][Activities] optional size 1..8;
dvar interval machineConsume[Machines][Activities] optional size 1..8;

cumulFunction cleanerUse = 
	sum (m in Machines, c in Cleaning) pulse(machineProduce[m][c], 1) 
	+ sum (m in Machines, c in Cleaning) pulse(machineConsume[m][c], 1);
	
cumulFunction siloCapacity =  
	step(0, startingSiloCapacity) 
	+ sum (m in Machines, r in Running) stepAtStart(machineProduce[m][r], 3) 
	//+ sum (m in Machines, r in Running) step(inferred(startOf(machineConsume[m][r])) + 1, 2)
	+ sum (m in Machines, r in Running) stepAtEnd(machineProduce[m][r], inferred(lengthOf(machineProduce[m][r]))*machineProductionRate)
	
	- sum (m in Machines, r in Running) stepAtStart(machineConsume[m][r], 3)
	//- sum (m in Machines, r in Running) step(inferred(startOf(machineConsume[m][r])) + 1, 3)
	- sum (m in Machines, r in Running) stepAtEnd(machineConsume[m][r], inferred(lengthOf(machineConsume[m][r]))*machineConsumptionRate);
	
cumulFunction output = sum (m in Machines, r in Running) stepAtEnd(machineConsume[m][r], inferred(lengthOf(machineConsume[m][r]))*3);


subject to {
  // Sum of all intervals greater than max
  forall(m in Machines) {
    sum(a in Activities) sizeOf(machineProduce[m][a]) >= numIntervals;
    sum(a in Activities) sizeOf(machineConsume[m][a]) >= numIntervals;
  }
  
  // Every cleaning interval is equal to 2
  forall(m in Machines, c in Cleaning) {
    sizeOf(machineProduce[m][c]) <= maximumCleaningIntervals;
    sizeOf(machineConsume[m][c]) <= maximumCleaningIntervals;
  }
  
  // Intervals stay in Order and no overlap
  forall(m in Machines, a1 in Activities, a2 in Activities : a1 < a2) {
    endBeforeStart(machineProduce[m][a1], machineProduce[m][a2]);
    endBeforeStart(machineConsume[m][a1], machineConsume[m][a2]);
  }
  
  // Resource capacities 
  cleanerUse <= 1;
  siloCapacity <= maximumSiloCapacity;
}