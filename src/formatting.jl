using DataFrames, XLSX
include("structures.jl")



"""
    format results into a data frame

    Inputs:
      𝓓: data struct
      𝓜: model struct
      resource_values: resource values from model
      slack: slack values from model
      x: binary variables from model
      dicts: dictionary of model information
      HEADERS: HEADERS for data frame

    Outputs:
      data frame with results
"""
function format_output(𝓓::Data, 𝓜, resource_values, slack, x, dicts::Dictionaries, HEADERS::Vector{String}, starting_period=0)
  df = create_df(HEADERS, 𝓓.periods+1)

  # adding time periods 
  df[!, Symbol(HEADERS[1])] = [starting_period:starting_period+𝓓.periods...]

  # add machine schedules to dataframe
  for m in 𝓓.machines
      activities = convert_to_tp_sequence(𝓓.periods, dicts.schedules[m.name, selected_schedule(x, m.name)])
      df[!, Symbol(m.name)] = vcat([""], activities[1:end])
  end

  # add resource values and their slacks to dataframe
  for r in 𝓓.resources
    values = value.(resource_values[:, r.name])
    df[!, Symbol(r.name)] = vcat(r.initial_volume, values[1:end])

    values = value.(slack[:, r.name])
    df[!, Symbol("slack_" * r.name)] = vcat([""], values[1:end])
  end

  return df
end



"""
  create a data frame with empty columns

  Inputs:
    HEADERS: HEADERS for data frame
    n: number of rows

  Outputs:
    data frame with empty columns

TBW
"""
function create_df(HEADERS, n)
  df = DataFrame()
  for header in HEADERS
      df[!, Symbol(header)] = Vector{Any}(undef, n)
  end
  return df
end



"""
    return the indices of the binary variable that is being used for machine_name

    Inputs:
      x: dictionary of binary variables
      machine_name: name of machine to find binary variable for

    Outputs:
      index of binary variable that is being used for machine_name
"""
function selected_schedule(x, machine_name)
  return findfirst(value.(x[machine_name]) .>= 0.5)
end



"""
    export data frame to excel file

    Inputs:
      df: data frame to export
      filename: name of excel file to export to
      sheet_name: name of sheet

    Outputs:
      creates excel file
"""
function write_to_xlsx(df,filename, sheet_name)
  XLSX.openxlsx(filename, mode="w") do xf
    sheet = XLSX.addsheet!(xf, sheet_name)
  XLSX.writetable!(sheet, df)
  end
end 



"""
    add data frame to excel file as a sheet

    Inputs:
      df: data frame to export
      filename: name of excel file to export to
      sheet_name: name of sheet

    Outputs:
      updated excel file
"""
function add_sheet(df,filename, sheet_name)
  XLSX.openxlsx(filename, mode="rw") do xf
    sheet = XLSX.addsheet!(xf, sheet_name)
    XLSX.writetable!(sheet, df)
    XLSX.close(xf)
  end
end 



"""
  convert the state sequence to a time period sequence

  Inputs:
    periods: number of time periods
    stateSequence: sequence of states

  Outputs:
    sequence of time periods
"""
function convert_to_tp_sequence(periods, stateSequence)
  schedule = []

  for p in 1:periods
    time_period=0
    for s in stateSequence
      time_period += s.duration
      if time_period >= p 
        push!(schedule, s.name)
        break
      end
    end
  end
  return schedule
end
