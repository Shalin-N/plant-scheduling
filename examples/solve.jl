include("../src/run.jl")
const DATA_PATH::String = joinpath(dirname(dirname(@__FILE__)), "data", "plant")
const MAX_ITER::Int64 = 50
const MAX_TIME = 60 # seconds (this is per solve)
const TOL::Float64 = 0.0001
const SOLVES::Int64 = 2
const SOLVE_PERIOD::Int64 = 36 # hours
const LOCK_PERIOD::Int64 = 24 # hours
const PERIOD_INCREMENT::Float64 = 1 # hours
const RECORD_SOLVES::Bool = true
const RECORD_ITTR::Bool = false
const RECORD_TIMINGS::Bool = false
const PRINT_ITTERATIONS::Bool = true
const USE_CONVERGENCE::Bool = true
const USE_COLUMN_AGE = true
const MAX_COLUMN_AGE = 4
const AMOUNT_TO_FIX = 1  # amount of infeasible states to fix per itteration of the hueristic


run_model(DATA_PATH, MAX_ITER, MAX_TIME, TOL, SOLVES, SOLVE_PERIOD, LOCK_PERIOD, PERIOD_INCREMENT, RECORD_SOLVES, RECORD_ITTR, RECORD_TIMINGS, PRINT_ITTERATIONS, USE_CONVERGENCE, USE_COLUMN_AGE, MAX_COLUMN_AGE, AMOUNT_TO_FIX)