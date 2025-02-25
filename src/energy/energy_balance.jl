"""
    energy_balance(object, meteo, constants = Constants())
    energy_balance!(object, meteo, constants = Constants())

Computes the energy balance of one or several components based on the type of the model it was
parameterized with in `object.energy`, and on one or several meteorology time-steps.

At the moment, two models are implemented in the package:

- [`Monteith`](@ref): the model found in Monteith and Unsworth (2013)
- `Missing`: if no computation of the energy balance is needed

# Arguments

- `object`: a [`Component`](@ref) struct ([`AbstractComponentModel`](@ref)), or a Dict/Array of.
- `meteo::Union{AbstractAtmosphere,Weather}`: meteorology structure, see [`Atmosphere`](@ref) or
[`Weather`](@ref)
- `constants = Constants()`: physical constants. See [`Constants`](@ref) for more details

# Note

Some models need input values for some variables. For example [`Monteith`](@ref) requires a
value for `Rₛ`, `d` and `skyFraction`. If you read the models from a file, you can
use [`init_status!`](@ref) (see examples).


# Examples

```julia
# ---Simple example---

meteo = Atmosphere(T = 20.0, Wind = 1.0, P = 101.3, Rh = 0.65)

# Using the model of Monteith and Unsworth (2013) for energy, Farquhar et al. (1980) for
# photosynthesis, and Medlyn et al. (2011) for stomatal conductance:
leaf = LeafModels(energy = Monteith(),
            photosynthesis = Fvcb(),
            stomatal_conductance = Medlyn(0.03, 12.0),
            Rₛ = 13.747, skyFraction = 1.0, PPFD = 1500.0, d = 0.03)

energy_balance(leaf,meteo)

# ---Using several components---

leaf2 = copy(leaf)
leaf2.status.PPFD = 800.0

energy_balance([leaf,leaf2],meteo)

# You can use a Dict if you'd like to keep track of the leaf in the returned DataFrame:
energy_balance(Dict(:leaf1 => leaf, :leaf2 => leaf2), meteo)

# ---Using several meteo time-steps---

w = Weather([Atmosphere(T = 20.0, Wind = 1.0, P = 101.3, Rh = 0.65),
             Atmosphere(T = 25.0, Wind = 1.5, P = 101.3, Rh = 0.55)],
             (site = "Test site",))

energy_balance(leaf, w)

# ---Using several meteo time-steps and several components---

energy_balance(Dict(:leaf1 => leaf, :leaf2 => leaf2), w)

# ---Using a model file---

model = read_model(joinpath(dirname(dirname(pathof(PlantBiophysics))),"test","inputs","models","plant_coffee.yml"))

# An example model file is available here:
# "https://raw.githubusercontent.com/VEZY/PlantBiophysics/main/test/inputs/models/plant_coffee.yml"

# Initialising the mandatory variables:
init_status!(model, Rₛ = 13.747, skyFraction = 1.0, PPFD = 1500.0, Tₗ = 25.0, d = 0.03)

# NB: To know which variables has to be initialised according to the models used, you can use
# `to_initialise(Component)`, *e.g.*:
to_initialise(model["Leaf"])

# Running a simulation for all component types in the same scene:
energy_balance!(model, meteo)

model["Leaf"].status.Rn
model["Leaf"].status.A
model["Leaf"].status.Cᵢ
```

# References

Duursma, R. A., et B. E. Medlyn. 2012. « MAESPA: a model to study interactions between water
limitation, environmental drivers and vegetation function at tree and stand levels, with an
example application to [CO2] × drought interactions ». Geoscientific Model Development 5 (4):
919‑40. https://doi.org/10.5194/gmd-5-919-2012.

Monteith, John L., et Mike H. Unsworth. 2013. « Chapter 13 - Steady-State Heat Balance: (i)
Water Surfaces, Soil, and Vegetation ». In Principles of Environmental Physics (Fourth Edition),
edited by John L. Monteith et Mike H. Unsworth, 217‑47. Boston: Academic Press.

Schymanski, Stanislaus J., et Dani Or. 2017. « Leaf-Scale Experiments Reveal an Important
Omission in the Penman–Monteith Equation ». Hydrology and Earth System Sciences 21 (2): 685‑706.
https://doi.org/10.5194/hess-21-685-2017.

Vezy, Rémi, Mathias Christina, Olivier Roupsard, Yann Nouvellon, Remko Duursma, Belinda Medlyn,
Maxime Soma, et al. 2018. « Measuring and modelling energy partitioning in canopies of varying
complexity using MAESPA model ». Agricultural and Forest Meteorology 253‑254 (printemps): 203‑17.
https://doi.org/10.1016/j.agrformet.2018.02.005.
"""
energy_balance!, energy_balance

function energy_balance!(object::AbstractComponentModel, meteo::AbstractAtmosphere, constants = Constants())
    is_init = is_initialised(object)
    !is_init && error("Some variables must be initialized before simulation")

    net_radiation!(object, meteo, constants)
    return nothing
end

# Same as above but non-mutating
function energy_balance(object::AbstractComponentModel, meteo::AbstractAtmosphere, constants = Constants())
    object_tmp = copy(object)
    energy_balance!(object_tmp, meteo, constants)

    return object_tmp
end

# energy_balance over several objects (e.g. all leaves of a plant) in an Array
function energy_balance!(object::O, meteo::AbstractAtmosphere, constants = Constants()) where O <: AbstractArray{<:AbstractComponentModel}

    for i in values(object)
        energy_balance!(i, meteo, constants)
    end

    return nothing
end

# energy_balance over several objects (e.g. all leaves of a plant) in a kind of Dict.
function energy_balance!(object::O, meteo::AbstractAtmosphere, constants = Constants()) where {O <: AbstractDict{N,<:AbstractComponentModel} where N}

    for (k, v) in object
        energy_balance!(v, meteo, constants)
    end

    return nothing
end

# same as the above but non-mutating
function energy_balance(
    object::O,
    meteo::AbstractAtmosphere,
    constants = Constants()
    ) where O <: Union{AbstractArray{<:AbstractComponentModel},AbstractDict{N,<:AbstractComponentModel} where N}

    # Copy the objects only once before the computation for performance reasons:
    object_tmp = copy(object)

    # Computation:
    energy_balance!(object_tmp, meteo, constants)

    return object_tmp
end

# energy_balance over several meteo time steps (called Weather) and possibly several components:
function energy_balance!(
    object::T,
    meteo::Weather,
    constants = Constants()
    ) where T <: Union{AbstractArray{<:AbstractComponentModel},AbstractDict{N,<:AbstractComponentModel} where N}

    # Check if the meteo data and the status have the same length (or length 1)
    check_status_wheather(object, meteo)

    # Computing for each time-steps:
    for (i, meteo_i) in enumerate(meteo.data)
        # Each object in a time-step:
        for obj in object
            energy_balance!(obj[i], meteo_i, constants)
        end
    end

end

# If we call weather with one component only, put it in an Array and call the function above
function energy_balance!(object::AbstractComponentModel, meteo::Weather, constants = Constants())
    energy_balance!([object], meteo, constants)
end

# energy_balance over several meteo time steps (same as above) but non-mutating
function energy_balance(
    object::T,
    meteo::Weather,
    constants = Constants()
    ) where T <: Union{AbstractComponentModel,AbstractDict{N,<:AbstractComponentModel} where N}

    object_tmp = copy(object)

    energy_balance!(object_tmp, meteo, constants)

    return object_tmp
end
