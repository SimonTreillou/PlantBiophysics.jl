"""
    TimeStepTable(vars)

`TimeStepTable` stores the values of the variables for each time step of a simulation. For example, it is used as the
structure in the status field of the [`ModelList`](@ref) type.

`TimeStepTable` implements the `Tables.jl` interface, so it can be used with any package that uses `Tables.jl` (like `DataFrames.jl`).

# Examples

```julia
# A leaf with several values for at least one of its variable will make a status with
# several time steps:
leaf = ModelList(
    photosynthesis = Fvcb(),
    stomatal_conductance = Medlyn(0.03, 12.0),
    status=(Tₗ=[25.0, 26.0], PPFD=1000.0, Cₛ=400.0, Dₗ=1.0)
)

# Indexing the model list with an integer will return the first time step:
leaf[1]

# Indexing the model list with a symbol will return the variable with all time steps:
leaf[:Tₗ]

# If you need the value for one variable at one time step, prefer using this (5x faster):
leaf[1].Tₗ

# Rather than this (5x slower):
leaf[:Tₗ][1]
```
"""
struct TimeStepTable{T}
    names::NTuple{N,Symbol} where {N}
    ts::Vector{T}
end

TimeStepTable(ts::V) where {V<:Vector} = TimeStepTable(keys(ts[1]), ts)
# Case where we instantiate the table with one time step only, not given as a vector:
TimeStepTable(ts) = TimeStepTable(keys(ts), ts)

struct TimeStepRow{T} <: Tables.AbstractRow
    row::Int
    source::TimeStepTable{T}
end

###### Tables.jl interface ######

Tables.istable(::Type{TimeStepTable{T}}) where {T} = true

# Keys should be the same between TimeStepTable so we only need the ones from the first timestep
Base.keys(ts::TimeStepTable) = getfield(ts, :names)
names(ts::TimeStepTable) = keys(ts)
# matrix(ts::TimeStepTable) = reduce(hcat, [[i...] for i in ts])'

function Tables.schema(m::TimeStepTable{T}) where {T<:MutableNamedTuple}
    # This one is complicated because the types of the variables are hidden in the Status as RefValues:
    Tables.Schema(names(m), DataType[i.types[1] for i in T.parameters[2].parameters])
end

Tables.rowaccess(::Type{<:TimeStepTable}) = true

function Tables.rows(t::TimeStepTable)
    return [TimeStepRow(i, t) for i in 1:length(t)]
end

Base.eltype(::Type{TimeStepTable{T}}) where {T} = TimeStepRow{T}

function Base.length(A::TimeStepTable{T}) where {T}
    length(getfield(A, :ts))
end

Tables.columnnames(ts::TimeStepTable) = getfield(ts, :names)

# Iterate over all time-steps in a TimeStepTable object.
# Base.iterate(st::TimeStepTable{T}, i=1) where {T} = i > length(st) ? nothing : (getfield(st, :ts)[i], i + 1)
Base.iterate(t::TimeStepTable{T}, st=1) where {T} = st > length(t) ? nothing : (TimeStepRow(st, t), st + 1)
Base.size(t::TimeStepTable{T}, dim=1) where {T} = dim == 1 ? length(t) : length(getfield(t, :names))

function Tables.getcolumn(row::TimeStepRow, i::Int)
    return getfield(getfield(row, :source), :ts)[getfield(row, :row)][i]
end
Tables.getcolumn(row::TimeStepRow, nm::Symbol) =
    getfield(getfield(row, :source), :ts)[getfield(row, :row)][nm]
Tables.columnnames(row::TimeStepRow) = getfield(getfield(row, :source), :names)

function Base.setindex!(row::TimeStepRow, x, i::Int)
    st = getfield(getfield(row, :source), :ts)[getfield(row, :row)]
    setproperty!(st, i, x)
end

function Base.setproperty!(row::TimeStepRow, nm::Symbol, x)
    st = getfield(getfield(row, :source), :ts)[getfield(row, :row)]
    setproperty!(st, nm, x)
end

##### Indexing and setting:

# Indexing a TimeStepTable object with the dot syntax returns values of all time-steps for a
# variable (e.g. `status.A`).
function Base.getproperty(ts::TimeStepTable, key::Symbol)
    getproperty(Tables.columns(ts), key)
end

# Indexing with a Symbol extracts the variable (same as getproperty):
function Base.getindex(ts::TimeStepTable, index::Symbol)
    getproperty(ts, index)
end

# Setting the values of a variable in a TimeStepTable object is done by indexing the object
# and then providing the values for the variable (must match the length).
function Base.setproperty!(ts::TimeStepTable, s::Symbol, x)
    @assert length(x) == length(ts)
    for (i, row) in enumerate(Tables.rows(ts))
        setproperty!(row, s, x[i])
    end
end

# # Indexing a TimeStepTable with an integer returns the ith time-step.
# function Base.getindex(status::TimeStepTable, index::T) where {T<:Integer}
#     getfield(status, :ts)[index]
# end

@inline function Base.getindex(ts::TimeStepTable, row_ind::Integer, col_ind::Integer)
    rows = Tables.rows(ts)
    @boundscheck begin
        if col_ind < 1 || col_ind > length(keys(ts))
            throw(BoundsError(ts, (row_ind, col_ind)))
        end
        if row_ind < 1 || row_ind > length(ts)
            throw(BoundsError(ts, (row_ind, col_ind)))
        end
    end
    return @inbounds rows[row_ind][col_ind]
end

# Indexing a TimeStepTable in one dimension only gives the row (e.g. `ts[1] == ts[1,:]`)
@inline function Base.getindex(ts::TimeStepTable, i::Integer)
    rows = Tables.rows(ts)
    @boundscheck begin
        if i < 1 || i > length(ts)
            throw(BoundsError(ts, i))
        end
    end

    return @inbounds rows[i]
end

# Indexing a TimeStepTable with a colon (e.g. `ts[1,:]`) gives all values in column.
@inline function Base.getindex(ts::TimeStepTable, row_ind::Integer, ::Colon)
    return getindex(ts, row_ind)
end

# Indexing a TimeStepTable with a colon (e.g. `ts[:,1]`) gives all values in the row.
@inline function Base.getindex(ts::TimeStepTable, ::Colon, col_ind::Integer)
    return getproperty(Tables.columns(ts), col_ind)
end

# push!(x, row)
# append!(x, rows)
# x[i] = row

function Base.show(io::IO, t::TimeStepTable, limit=true)
    length(t) == 0 && return

    ts_all = getfield(t, :ts)
    ts_print = []
    for (i, ts) in enumerate(ts_all)
        push!(ts_print, Term.highlight("Step $i: " * show_long_format_status(ts, true)))
        limit && i >= displaysize(io)[1] && (push!(ts_print, "…"); break)
    end

    st_panel = Term.Panel(
        join(ts_print, "\n"),
        title="TimeStepTable",
        style="red",
        fit=false,
    )

    print(io, st_panel)
end

function Base.show(io::IO, row::TimeStepRow)
    i = getfield(row, :row)
    st = getfield(getfield(row, :source), :ts)[i]
    # st_panel = Term.highlight("Step $i: " * show_long_format_status(st, true))
    ts_print = "Step $i: " * show_long_format_status(st, true)

    st_panel = Term.Panel(
        ts_print,
        title="TimeStepRow",
        style="red",
        fit=false,
    )

    print(io, Term.highlight(st_panel))
    # print(io, "TimeStepRow", NamedTuple(t))
end
