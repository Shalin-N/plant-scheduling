using JSON
include("structures.jl")



function import_data(file_path, periods, period_increment)
    resource_data = JSON.parsefile(joinpath(file_path, "resources.json"))
    machine_data = JSON.parsefile(joinpath(file_path, "machines.json"))
    states_data = JSON.parsefile(joinpath(file_path, "states.json"))
    deliveries_data = JSON.parsefile(joinpath(file_path, "deliveries.json"))

    resources = [Resource(resource_name,
                          resource_data[resource_name]["min_capacity"],
                          resource_data[resource_name]["max_capacity"],
                          resource_data[resource_name]["initial_volume"],
                          resource_data[resource_name]["rates"],
                          resource_data[resource_name]["flows"],
                          resource_data[resource_name]["type"])
                 for resource_name in keys(resource_data)]

    machines = [Machine(machine_name,
                        machine_data[machine_name]["initial_state"],
                        machine_data[machine_name]["initial_time"],
                        machine_data[machine_name]["run_time"],
                        machine_data[machine_name]["cleaning_time"],
                        machine_data[machine_name]["min_off_time"],
                        machine_data[machine_name]["max_off_time"],
                        machine_data[machine_name]["rates"],
                        machine_data[machine_name]["flows"],
                        get(machine_data[machine_name], "cleaner_key", "NA"))
                for machine_name in keys(machine_data)]

    states = [State2(current_state,
                state_data["next_state"],
                state_data["duration_type"],
                get(state_data, "duration_key", "NA"),
                get(state_data, "min_duration_key", "NA"),
                get(state_data, "max_duration_key", "NA"),
                state_data["include"])
         for (current_state, state_data) in states_data]

    deliveries = [Delivery(resource_name,
                            delivery_data["time_period"],
                            delivery_data["volume"])
                  for (resource_name, delivery_data) in deliveries_data]

    return Data(resources, machines, states, convert(Int, div(periods, period_increment)), period_increment, deliveries)
end
