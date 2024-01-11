include("structures.jl")



"""
    generate a random schedule for each machine in the data structure 𝓓
    and store it in the dictionary schedules_dict

    Inputs:
      𝓓: problem data
      schedules_dict: dictionary to store schedules in
      variable_ref: reference to the binary variable index that the schedule is for
      use_params: if true, use the initial state and time for each machine
                  if false, generate random initial state and time for each machine

    Outputs:
      schedules_dict: dictionary with schedules for each machine and binary variable

    Notes:
     schedules_dict still needs to be type casted to a Dict{[String, Int64], Vector{State}}
"""
function build_schedules(𝓓::Data, schedules_dict::Dict{Tuple{String, Int64}, Vector{State}}, variable_ref::Int64, use_params::Bool = false)
  for m in 𝓓.machines
    schedule::Vector{State} = []
    duration::Int64 = 0
    next_state::String = use_params ? m.initial_state : ["on", "cleaning", "off"][rand(1:3)]
    next_time::Int64 = use_params ? m.initial_time : 0
    time_limit::Int64 = 𝓓.periods + next_time
    current_time::Int64 = 1
    
    while current_time <= time_limit
      state_info = 𝓓.states[findfirst(s -> s.current_state == next_state, 𝓓.states)]

      duration = if state_info.duration_type == "fixed_duration"
                  convert(Int, div(getproperty(m, Symbol(state_info.max_duration_key)), 𝓓.period_increment))
                 elseif !state_info.include
                  0
                 else
                  convert(Int, div(rand(m.min_off_time:m.max_off_time), 𝓓.period_increment))
                 end
      duration = min(duration, time_limit - current_time + 1)

      push!(schedule, State(state_info.current_state, duration - next_time))

      next_time = 0
      next_state = state_info.next_state
      current_time = current_time + duration
    end

    # include an 0 duration off state at the end of the schedule
    state_info = 𝓓.states[findfirst(s -> s.current_state == next_state, 𝓓.states)]
    push!(schedule, State(state_info.current_state, 0))

    schedules_dict[m.name, variable_ref] = schedule
  end
  return schedules_dict
end
