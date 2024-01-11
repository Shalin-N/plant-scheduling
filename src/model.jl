using JuMP, HiGHS
include("structures.jl")



"""
    builds a model based on 1 set of schedules and problem data

    Inputs:
      𝓓: problem data
      schedules_dict Dict of machine names to schedules

    Outputs:
      𝓜: model
      x: Dict of machine names to binary schedule variables
      resource_volume: Array of resource names to resource volume variables
      slack: Array of resource names to slack variables
      dicts: Dict of dictionaries which reference important model information that are not variables
"""
function build_model(𝓓::Data, schedules_dict::Dict{Tuple{String, Int64}, Vector{State}})
  dicts::Dictionaries = Dictionaries(schedules_dict)
  𝓜::Model = direct_model(HiGHS.Optimizer())
  set_attribute(𝓜, "output_flag", false)

  ### Variables
  x = Dict{String, Vector{VariableRef}}( # binary variable that represents a schedule
    m.name => @variable(𝓜, [1:1], binary = true, base_name = "$(m.name)")
    for m in 𝓓.machines
  )
  @variable(𝓜, resource_volume[p in 0:𝓓.periods, [r.name for r in 𝓓.resources]])
  @variable(𝓜, slack[p in 1:𝓓.periods, [r.name for r in 𝓓.resources]])
  @variable(𝓜, storage_slack[p in 1:𝓓.periods, [r.name for r in 𝓓.resources if r.type == "storage"]])
  @variable(𝓜, renewable_slack[p in 1:𝓓.periods, [r.name for r in 𝓓.resources if r.type == "renewable"]])

  ### Special
  for m in 𝓓.machines
    dicts.GUB[m.name] = @constraint(𝓜, sum(x[m.name][1]) == 1)
    dicts.num_schedules_start[m.name] = 1
    dicts.num_schedules_end[m.name] = 1
    dicts.schedules_age[m.name, 1] = 1
  end

  ### Constraints
  for r in 𝓓.resources
    @constraint(𝓜, resource_volume[0, r.name] == r.initial_volume) # initial resource volume

    for p in 1:𝓓.periods
      @constraint(𝓜,  resource_volume[p, r.name] + slack[p, r.name] <= r.max_capacity) # max capacity
      @constraint(𝓜,  resource_volume[p, r.name] + slack[p, r.name] >= r.min_capacity) # min capacity

      rate_expression = AffExpr() # resource volume constraint begins from here
      for m in 𝓓.machines
        machine_activity::String = find_machine_activity(schedules_dict[m.name, 1], p)
        index::Int64 = 0
              
        if r.name in m.flows && machine_activity == "on"
          index = findfirst(name -> name == r.name, m.flows)
          add_to_expression!(rate_expression, m.rates[index]*𝓓.period_increment, x[m.name][1])

        elseif  r.name == m.cleaner_key && machine_activity == "cleaning"
          index = findfirst(name -> name == m.name, r.flows)
          add_to_expression!(rate_expression, r.rates[index], x[m.name][1])
        end
      end

      if r.type == "storage"
        dicts.resource_volume_con[p, r.name] = @constraint(𝓜, resource_volume[p, r.name] - resource_volume[p-1, r.name] - rate_expression == 0)
        @constraint(𝓜, storage_slack[p, r.name] >= slack[p, r.name])  # absolute value of slack for storage
        @constraint(𝓜, storage_slack[p, r.name] >= -slack[p, r.name]) # absolute value of slack
      end

      if r.type == "renewable"
        dicts.resource_volume_con[p, r.name] = @constraint(𝓜, resource_volume[p, r.name] - r.max_capacity - rate_expression == 0)
        @constraint(𝓜, renewable_slack[p, r.name] >= slack[p, r.name])  # special slack for 2 step hueristic solve
        @constraint(𝓜, renewable_slack[p, r.name] >= -slack[p, r.name]) # special slack for 2 step hueristic solve
      end
    end
  end

  # adding in deliveries to resource volume constraint
  for d in 𝓓.deliveries
    set_normalized_rhs(dicts.resource_volume_con[d.time_period, d.resource], d.volume)
  end

  # minimise infeasibility
  @objective(𝓜, Min, sum(renewable_slack)*10 + sum(storage_slack))

  return 𝓜, x, resource_volume, slack, renewable_slack, storage_slack, dicts
end



"""
    Update the models constraint to support a new schedule

    Inputs:
      𝓓: problem data
      𝓜: model
      x: binary variables
      dicts: dictionaries of model information
    
    Outputs:
      𝓜: model
      x: binary variables
      dicts: dictionaries of model information
"""
function update_model(𝓓::Data, 𝓜::Model, x, dicts::Dictionaries, ittr::Int64 = 999, use_column_age::Bool = false, MAX_COLUMN_AGE::Int64 = 999)
  for m in 𝓓.machines
    if dicts.num_schedules_start[m.name] != dicts.num_schedules_end[m.name] # don't added schedules if this machine is already optimal

      if use_column_age

        for schedule_ref in 1:dicts.num_schedules_start[m.name]-1
            if ittr - dicts.schedules_age[m.name, schedule_ref] > MAX_COLUMN_AGE && is_valid(𝓜, x[m.name][schedule_ref])
              fix(x[m.name][schedule_ref], 0)
            end
        end
      end

      for schedule_ref in dicts.num_schedules_start[m.name]:dicts.num_schedules_end[m.name]
        dicts.schedules_age[m.name, schedule_ref] = ittr
        push!(x[m.name], @variable(𝓜, [[schedule_ref]], binary = true, base_name = "$(m.name)")[schedule_ref]) # Add new binary variables
        set_objective_coefficient(𝓜, x[m.name][schedule_ref], schedule_quality(dicts.schedules[m.name, schedule_ref])) # set schedule quality of binary variables
        set_normalized_coefficient(dicts.GUB[m.name], x[m.name][schedule_ref], 1) # update GUB constraint for new binary variables

        for p in 1:𝓓.periods, r in 𝓓.resources
          machine_activity::String = find_machine_activity(dicts.schedules[m.name, schedule_ref], p)
          index::Int64 = 0
                  
          if r.name in m.flows && machine_activity == "on"
            index = findfirst(name -> name == r.name, m.flows)
            set_normalized_coefficient(dicts.resource_volume_con[p, r.name], x[m.name][schedule_ref], -m.rates[index]*𝓓.period_increment)

          elseif  r.name == m.cleaner_key && machine_activity == "cleaning"
            index = findfirst(name -> name == m.name, r.flows)
            set_normalized_coefficient(dicts.resource_volume_con[p, r.name], x[m.name][schedule_ref], -r.rates[index])
          end
        end
      end
    end
  end

  return 𝓜, x, dicts
end



"""
    Find the current optimal schedule for a machine

    Inputs:
      x: binary variables
      machine_name: name of machine

    Outputs:
      schedule_ref: index of current optimal schedule
"""
function find_machine_activity(schedule::Vector{State}, p::Int64)
  time_period::Int64 = 0
  for s in schedule
      (time_period += s.duration) >= p && return s.name
  end
end



"""
    Find the current optimal schedule for a machine

    Inputs:
      x: binary variables
      machine_name: name of machine

    Outputs:
      schedule_ref: index of current optimal schedule
"""
function schedule_quality(schedule::Vector{State})
  return sum((s.duration for s in schedule if s.name in ["off", "off-dirty"] && s.duration > 0), init=0)
end
