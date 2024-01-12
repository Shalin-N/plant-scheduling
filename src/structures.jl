using JuMP

mutable struct Resource
  name::String
  min_capacity::Int
  max_capacity::Int
  initial_volume::Float64
  type::String
end

mutable struct Machine
  name::String
  initial_state::String
  initial_time::Int
  run_time::Int
  cleaning_time::Int
  min_off_time::Int
  max_off_time::Int
  resource_flows::Vector{Any}
  resource_rates::Vector{Any}
  cleaning_group::String
  cleaning_rate::Int
end

struct State2
current_state::String
next_state::String
next_rolling_hoz_state::String
duration_type::String
duration_key::String
min_duration_key::String
max_duration_key::String
include::Bool
end

struct Delivery
  resource::String
  time_period::Int
  volume::Int
end

mutable struct Data
  resources::Vector{Resource}
  machines::Vector{Machine}
  states::Vector{State2}
  periods::Int
  period_increment::Float64
  deliveries::Vector{Delivery}
end

mutable struct State
  name::String
  duration::Int64
end

# Struct to hold the dictionaries which reference important model information
mutable struct Dictionaries
  schedules           ::Dict{Tuple{String, Int64}, Vector{State}}
  GUB                 ::Dict{String, ConstraintRef}
  resource_volume_con ::Dict{Tuple{Int64, String}, ConstraintRef}
  num_schedules_start ::Dict{String, Int64}
  num_schedules_end   ::Dict{String, Int64}
  schedules_age       ::Dict{Tuple{String, Int64}, Int64}
  
  function Dictionaries(schedules)
    new(schedules, Dict{String, ConstraintRef}(), Dict{Tuple{Int64, String}, ConstraintRef}(), Dict{String, Int64}(), Dict{String, Int64}(), Dict{Tuple{String, Int64}, Int64}())
  end
end

# Not implemented yet
struct ScheduleVariable
  variable::Vector{VariableRef}
  age::Int64

  function ScheduleVariable(variable, age)
    new(variable, age)
  end

  function ScheduleVariable(variable)
    new(variable, 1)
  end
end

# Not implemented yet
mutable struct model_information
  𝓜::Model
  x::Dict{String, Vector{VariableRef}}
  resource_volume
  slack
end
