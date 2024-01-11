# Plant Scheduling


The bug folder contains reproduction of a bug in found in JuMP <br />
The constraintProgramming folder contains files for that approach with its own README <br />
The src folder contains all the functions and helper functions for running the MIP solution <br />
The example folder constains solve.jl that simplifies the proccess of running the code. <br />

## How to Use
### Solve Parameters
for each solve you can specificy the parameters, and options you want to use: <br />

const DATA_PATH::String = "the folder path of JSONs" <br />
const MAX_ITER::Int64 =  50 # max number of itterations <br />
const MAX_TIME = 60 # seconds (this is per solve) <br />
const TOL::Float64 = 0.0001 # maximum tolerance for convergence <br />
const SOLVES::Int64 = 2 # how mant time windows you want to solve <br />
const SOLVE_PERIOD::Int64 = 36 # time points (easier to thank as hours) <br />
const LOCK_PERIOD::Int64 = 24 # time points (easier to thank as hours) <br />
const PERIOD_INCREMENT::Float64 = 1 # time points (easier to thank as hours) <br />
const RECORD_SOLVES::Bool = true # output each solve to an excel <br />
const RECORD_ITTR::Bool = false # output each itteration to an excel <br />
const RECORD_TIMINGS::Bool = false # output timings of each itteration to excel <br />
const PRINT_ITTERATIONS::Bool = true # output itterations to console <br /> 
const USE_CONVERGENCE::Bool = true # decision whether to use convergence or not <br />
const USE_COLUMN_AGE = true # decision whether to use column ageing or not <br />
const AMOUNT_TO_FIX = 1  # amount of infeasible states to fix per itteration of the hueristic <br />


### Data Structure
The data folder contains different plant setups, formatted as 4 JSONs for ingestition into the model <br />
there are 4 JSONs used to describe a plant are: deliveries, machines, resources, and states. <br />

For deliveres the JSON is formatted 
```json
{
  "storage_resource_name": {
    "time_ppoint": x, (the time point at whichs this volume change should happen)
    "volume": x
  }
}
```

For Machines the JSON is formatted
```json
{
  "machine_name": {
    "initial_state": "off",
    "initial_time": 0, (in time points)
    "run_time": 8, (in time points)
    "cleaning_time": 3, (in time points)
    "min_off_time": 0, (in time points)
    "max_off_time": 3, (in time points)
    "rates": [-51, 42.5], (rate applied to each silo contained in flows)
    "flows": ["silo1", "silo2"] (which silos this machine interacts with),
    "cleaner_key": "cleaner1" (which cleaner subgroup this machine belongs to)
  }
}
```


For Resources the JSON is formatted
```json
{
  "resource_name": {
    "min_capacity": 0,
    "max_capacity": 999999,
    "initial_volume": 500,
    "rates": [], (applicable for cleaners, indicates how much cleaning resource a machine uses)
    "type": "storage",
    "flows": [] (applicable for cleaner resources indicating which machine belongs to this cleaner)
  }
}
```



For States the JSON is formatted
```json
{
  "state_name": {
    "next_state": "state_name",
    "duration_type": "xxxx", (whether the duration type is random or fixed)
    "min_duration_key": "xxxx", (The parameter on machines that indicates the max duration)
    "max_duration_key": , (the parameter on machines that indicates the min duration, only used in random schedul generation)
    "include": true (whether this state is to be considered used or the cycling of states)
  }
}
```