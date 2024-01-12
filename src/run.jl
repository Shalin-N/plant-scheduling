using Dates
include("model.jl")
include("schedules.jl")
include("formatting.jl")
include("import.jl")
include("hueristic.jl")
include("rolling_horizon.jl")



function run_model(DATA_PATH::String, MAX_ITER::Int64, MAX_TIME, TOL::Float64,
                         SOLVES::Int64, SOLVE_PERIOD::Int64, LOCK_PERIOD::Int64, PERIOD_INCREMENT::Float64,
                         RECORD_SOLVES::Bool, RECORD_ITTR::Bool, RECORD_TIMINGS::Bool, PRINT_ITTERATIONS::Bool, 
                         USE_CONVERGENCE::Bool, USE_COLUMN_AGE::Bool, MAX_COLUMN_AGE::Int64, AMOUNT_TO_FIX::Int64)

  HEADERS::Vector{String} = ["period", "silo1", "slack_silo1", "machine1a","machine1b","machine1c","machine1d", "silo2", 
                                    "slack_silo2", "cleaner1", "slack_cleaner1", "machine2", "silo3", "slack_silo3","machine3a",
                                    "machine3b", "silo4", "slack_silo4", "cleaner2", "slack_cleaner2", "machine4a", "machine4b", 
                                    "silo5", "slack_silo5", "machine5", "silo6", "cleaner3", "slack_cleaner3", "slack_silo6",
                                    "machine6","silo7", "slack_silo7", "machine7", "silo8", "slack_silo8", "cleaner4", "slack_cleaner4"]

  TIMESTAMP::String = Dates.format(now(), "dd-mm-yyyy HH:MM")
  FOLDER::String = "$TIMESTAMP"
  PATH::String = joinpath(pwd(), FOLDER)
  
  𝓓::Data = import_data(DATA_PATH, SOLVE_PERIOD, PERIOD_INCREMENT)
  solve_ittr::Int64 = 1
  machine_params = true # type of params changes in the future so no static typing

  if RECORD_TIMINGS || RECORD_ITTR || RECORD_SOLVES
    mkdir(PATH)
  end

  total_slack_value::Float64 = 0
  total_schedules::Int64 = 0
  total_fixed_variables::Int64 = 0
  total_elapsed_time::Float64 = 0
  total_itteations::Int64 = 0

  while solve_ittr <= SOLVES
    i::Int64 = 1

    first_time::Float64 = @elapsed begin
      schedules_dict::Dict{Tuple{String, Int64}, Vector{State}} = build_schedules(𝓓, Dict{Tuple{String, Int64}, Vector{State}}(), i, machine_params)
      𝓜::Model, x, resource_volume, slack, renewable_slack, storage_slack, dicts::Dictionaries = build_model(𝓓, schedules_dict)
      optimize!(𝓜)
    end

    old_obj::Float64 = 0
    obj::Float64 = objective_value(𝓜)
    elapsed_times::Vector{Float64} = [first_time]
    PRINT_ITTERATIONS ? println("Iteration: ", i, "    obj: ", obj) : nothing

    if solve_ittr == 1 && RECORD_ITTR
      write_to_xlsx(format_output(𝓓, 𝓜, resource_volume, slack, x, dicts, HEADERS), joinpath(PATH,"Itterations.xlsx"), "Solve"*"$solve_ittr"*"-1")
    elseif RECORD_ITTR
      add_sheet(format_output(𝓓, 𝓜, resource_volume, slack, x, dicts, HEADERS), joinpath(PATH,"Itterations.xlsx"), "Solve"*"$solve_ittr"*"-1")
    end
    
    i += 1

    while i < MAX_ITER+1 && sum(elapsed_times) < MAX_TIME && (!USE_CONVERGENCE || abs(obj - old_obj) > TOL)
      old_obj = obj

      elapsed_time = @elapsed begin
        dicts, columns_added = improve_schedules_hueristic(𝓓, dicts, slack, x, AMOUNT_TO_FIX)

        if !columns_added
          break
        end

        𝓜, x, dicts = update_model(𝓓, 𝓜, x, dicts, i, USE_COLUMN_AGE, MAX_COLUMN_AGE)
        optimize!(𝓜)
      end

      obj = objective_value(𝓜)
      PRINT_ITTERATIONS ? println("Iteration: ", i, "    obj: ", obj) : nothing
      RECORD_ITTR ? add_sheet(format_output(𝓓, 𝓜, resource_volume, slack, x, dicts, HEADERS), joinpath(PATH,"Itterations.xlsx"), "Solve"*"$solve_ittr"*"-"*"$i") : nothing
      i += 1
      push!(elapsed_times, elapsed_time)
    end
    i -= 1

    schedules_count = sum(size(x[m.name])[1] for m in 𝓓.machines)
    total_slack_value += sum(value(slack[p, r.name]) for r in 𝓓.resources for p in 1:LOCK_PERIOD)
    total_schedules += schedules_count
    total_fixed_variables += length(resource_volume) + length(slack)*3
    total_elapsed_time += sum(elapsed_times)
    total_itteations += i
    
    println("elapsed time: ", sum(elapsed_times), "   obj: ", obj, "   fixed_variables: ", length(resource_volume) + length(slack)*3, "   schedules_count: ", schedules_count, "   itteration: ", i, "\n")

    if solve_ittr == 1
      RECORD_TIMINGS ? write_to_xlsx(DataFrame(iteration=1:length(elapsed_times)-1, elapsed_time=elapsed_times[1:end-1]), joinpath(PATH,"Timings.xlsx"), "Solve"*"$solve_ittr") : nothing
      RECORD_SOLVES ? write_to_xlsx(format_output(𝓓, 𝓜, resource_volume, slack, x, dicts, HEADERS), joinpath(PATH, "Solves.xlsx"), "Solve"*"$solve_ittr"*"-$i") : nothing
    else
      RECORD_TIMINGS ? add_sheet(DataFrame(iteration=1:length(elapsed_times)-1, elapsed_time=elapsed_times[1:end-1]), joinpath(PATH,"Timings.xlsx"), "Solve"*"$solve_ittr") : nothing
      RECORD_SOLVES ? add_sheet(format_output(𝓓, 𝓜, resource_volume, slack, x, dicts, HEADERS, (solve_ittr-1)*LOCK_PERIOD), joinpath(PATH, "Solves.xlsx"), "Solve"*"$solve_ittr"*"-$i") : nothing
    end

    # update for next itteration
    correct_LOCK_PERIOD = convert(Int, div(LOCK_PERIOD, 𝓓.period_increment))
    𝓓 = update_machine_params(𝓓, correct_LOCK_PERIOD, dicts, x)
    𝓓 = update_resource_params(𝓓, correct_LOCK_PERIOD, resource_volume)

    solve_ittr += 1
  end

  println("total elapsed time: ", total_elapsed_time, "\ntotal itterations: ", total_itteations, "\ntotal slack value: ", total_slack_value, "\ntotal schedules: ", total_schedules, "\ntotal fixed_variables: ", total_fixed_variables)

  # Open a file for writing
  output_file = open(joinpath(PATH, "output.txt"), "w")
  write(output_file, "MAX TIME: $MAX_TIME\n")
  write(output_file, "MAX ITTR: $MAX_ITER\n")
  write(output_file, "total elapsed time: $total_elapsed_time\n")
  write(output_file, "total itterations: $total_itteations\n")
  write(output_file, "total slack value: $total_slack_value - 0 means feasible\n" )
  write(output_file, "final objective: Not implemented yet, need to account for overlap caused by solve window vs lock window\n" )
  write(output_file, "total schedules: $total_schedules\n")
  write(output_file, "total fixed_variables: $total_fixed_variables\n")
  write(output_file, "converge: $USE_CONVERGENCE\n")
  write(output_file, "column age: $USE_COLUMN_AGE\n")
  close(output_file)
end
