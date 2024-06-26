include("structures.jl")



"""
    generate_schedules_using_next_decent(𝓓, schedules, ittr, slack, x)

    Inputs:
    - 𝓓: the data structure containing all the data
    - schedules: a dictionary of schedules for each machine
    - num_schedules: a dictionary of the current number of schedules for each machine
    - slack: the slack variables for each period and renewable resource
    - x: the binary variables for each machine and schedule
TBW
"""
function improve_schedules_hueristic(𝓓::Data, dicts::Dictionaries, slack, x, starting_period::Int64, ending_period::Int64, AMOUNT_TO_FIX=1, renewable::Bool=true, storage::Bool=true)
  columns_added::Bool = false
  dicts.num_schedules_start::Dict{String, Int64} = deepcopy(dicts.num_schedules_end)

  for m in 𝓓.machines
    break_condition::Int64 = 0
    schedule_ref::Int64 = find_current_optimal_schedule(x, m.name)
    renewable_resource_ref::String = m.cleaning_group
    num_states::Int64 = size(dicts.schedules[m.name, schedule_ref])[1]

    for p in starting_period:ending_period
      state::State, state_i::Int64 = find_machine_state(dicts.schedules[m.name, schedule_ref], starting_period, p)
      conflict::Float64 = value(slack[p, renewable_resource_ref])
      overflow::Float64 = sum(value(slack[p, storage]) for storage in m.resource_flows)

      # Cleaning Conflict
      if state.name == "cleaning" && conflict != 0 && renewable
        if 2 < state_i && state_i <= num_states-2
          columns_added = true
          break_condition += 1
          for time_shift::Int64 in 1:m.cleaning_time
            dicts.schedules, dicts.num_schedules_end = generate_new_cleaning_schedules(dicts.schedules, dicts.num_schedules_end, m, schedule_ref, state_i, time_shift)
            dicts.schedules, dicts.num_schedules_end = generate_new_cleaning_schedules(dicts.schedules, dicts.num_schedules_end, m, schedule_ref, state_i, -time_shift)
          end
        elseif state_i == num_states-1 # handle cleaning at the last non off state
          columns_added = true
          break_condition += 1
          for time_shift in 1:m.cleaning_time
            dicts.schedules, dicts.num_schedules_end = generate_new_cleaning_schedules(dicts.schedules, dicts.num_schedules_end, m, schedule_ref, state_i, -time_shift, 2 , 1)
          end
        end

      # Silo Overflow
      elseif state.name == "on" && overflow != 0 && state_i <= num_states-1 && storage
        columns_added = true
        dicts.num_schedules_end[m.name] += 1
        dicts.schedules[m.name, dicts.num_schedules_end[m.name]] = deepcopy(dicts.schedules[m.name, schedule_ref])
        dicts.schedules[m.name, dicts.num_schedules_end[m.name]][state_i].duration -= 1
        dicts.schedules[m.name, dicts.num_schedules_end[m.name]][state_i + 1].duration += 1

        break_condition += 1
      end

      if break_condition >= AMOUNT_TO_FIX
        break
      end
    end
  end
  return dicts, columns_added
end



"""
    finds the indexes of the current most optimal schedule for a given machine 

    Inputs:
    - x: the binary variables for each machine and schedule
    - machine_name: the name of the machine being considered

    Outputs:
    - index of the current most optimal schedule for a given machine
"""
function find_current_optimal_schedule(x, machine_name::String)
  return findfirst(value.(x[machine_name]) .>= 0.5)
end



"""
    find the machine state at period

    Inputs:
    - schedule: a schedule for a given machine
    - p: the period being considered

    Outputs:
    - the state that is active during period p
    - the index of the state that is active during period p
"""
function find_machine_state(schedule::Vector{State}, starting_period::Int64, p::Int64)
  time_period::Int64 = starting_period
  for (index, s) in enumerate(schedule)
    (time_period += s.duration) >= p && return s, index
  end
end



"""
  Takes in a schedule and returns multiple new schedules with the bad clean state shifted 
  in time according to time_shift

  Inputs:
  - schedules: a dictionary of schedules for each machine
  - num_schedules: a dictionary of the current number of schedules for each machine
  - m: the machine being considered
  - schedule_ref: the index of the schedule being considered
  - state_i: the index of the state being considered
  - time_shift: the amount of time to shift the bad clean state forward and backward
  - period_shift_minus: which state to apply time shift to before current state_i
  - period_shift_plus: which state to apply time shift to after current state_i

  Outputs:
  - schedules: a dictionary of schedules for each machine
  - num_schedules: a dictionary of the current number of schedules for each machine

  Notes:
  by using a negative sign time_shift (e.g -3), the current state_i can be shifted backward in time

"""
function generate_new_cleaning_schedules(schedules::Dict{Tuple{String, Int64}, Vector{State}}, num_schedules::Dict{String, Int64}, m, schedule_ref::Int64, state_i::Int64, time_shift::Int64, state_shift_minus::Int64=2, state_shift_plus::Int64=2)
  if state_i == state_shift_minus
    println(state_i)
    println(state_shift_minus)
  end
  
  num_schedules[m.name] += 1
  schedules[m.name, num_schedules[m.name]] = deepcopy(schedules[m.name, schedule_ref]) 
  schedules[m.name, num_schedules[m.name]][state_i - state_shift_minus].duration += time_shift
  schedules[m.name, num_schedules[m.name]][state_i + state_shift_plus].duration -= time_shift

  return schedules, num_schedules
end
