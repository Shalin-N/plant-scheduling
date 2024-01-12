"""
update the machine parameters for the next solve window in rolling horizon

  Inputs:
    𝓓: data structure
    LOCK_PERIOD: period to lock machine state
    dicts: dictionaries
    x: binary variables

  Outputs:
    𝓓: updated data structure
"""
function update_machine_params(𝓓, LOCK_PERIOD, dicts, x)
  for m in 𝓓.machines
    selected_schedule_ref = findfirst(value.(x[m.name]) .>= 0.5)
    schedule = dicts.schedules[m.name, selected_schedule_ref]
    duration = 0
    initial_state = ""
    initial_time = 0

    for s in schedule
      duration += s.duration
      if duration < LOCK_PERIOD; continue end # continue until lock period state

      state_info = 𝓓.states[findfirst(x -> x.current_state == s.name, 𝓓.states)]
      max_duration = getproperty(m, Symbol(state_info.max_duration_key))

      if s.duration == max_duration || state_info.current_state == "off" || state_info.current_state == "off-dirty"
        initial_state = state_info.next_rolling_hoz_state
        initial_time = 0
      else
        initial_state = s.name
        initial_time = max_duration - s.duration
      end

      break
    end

    m.initial_state = initial_state
    m.initial_time = initial_time
  end
  return 𝓓
end



"""
  update the resource parameters for the next solve window in rolling horizon

  Inputs:
    𝓓: data structure
    LOCK_PERIOD: period to lock machine state
    resource_volume: resource volume for each period and resource

  Outputs:
    𝓓: updated data structure
"""
function update_resource_params(𝓓, LOCK_PERIOD, resource_volume)
  for r in 𝓓.resources
    r.initial_volume = value(resource_volume[LOCK_PERIOD, r.name])
  end

  return 𝓓
end
