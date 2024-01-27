using JSON
include("structures.jl")



function import_data(file_path, periods, period_increment)
    resources = import_resources(file_path)
    machines = import_machines(file_path)
    states = import_states(file_path)
    deliveries = import_deliveries(file_path)

    return Data(resources, machines, states, convert(Int, div(periods, period_increment)), period_increment, deliveries)
end



function import_resources(file_path)
    resource_data = JSON.parsefile(joinpath(file_path, "resources.json"))

    resources = [Resource(resource_name,
                          resource_data[resource_name]["min_capacity"],
                          resource_data[resource_name]["max_capacity"],
                          resource_data[resource_name]["initial_volume"],
                          resource_data[resource_name]["type"])
                 for resource_name in keys(resource_data)]

    return resources
end



function import_machines(file_path)
    machine_data = JSON.parsefile(joinpath(file_path, "machines.json"))

    machines = [Machine(machine_name,
                        machine_data[machine_name]["initial_state"],
                        machine_data[machine_name]["initial_time"],
                        machine_data[machine_name]["run_time"],
                        machine_data[machine_name]["cleaning_time"],
                        machine_data[machine_name]["min_off_time"],
                        machine_data[machine_name]["max_off_time"],
                        machine_data[machine_name]["resource_flows"],
                        machine_data[machine_name]["resource_rates"],
                        machine_data[machine_name]["cleaning_group"],
                        machine_data[machine_name]["cleaning_rate"])          
                for machine_name in keys(machine_data)]

    return machines
end



function import_states(file_path)
    states_data = JSON.parsefile(joinpath(file_path, "states.json"))

    states = [State2(current_state,
                     state_data["next_state"],
                     state_data["next_rolling_hoz_state"],
                     state_data["duration_type"],
                     get(state_data, "duration_key", "NA"),
                     get(state_data, "min_duration_key", "NA"),
                     get(state_data, "max_duration_key", "NA"),
                     state_data["include"])
              for (current_state, state_data) in states_data]

    return states
end



function import_deliveries(file_path)
    deliveries_data = JSON.parsefile(joinpath(file_path, "deliveries.json"))

    deliveries = [Delivery(resource_name,
                           delivery_data["time_period"],
                           delivery_data["volume"])
                  for (resource_name, delivery_data) in deliveries_data]
    
    return deliveries
end