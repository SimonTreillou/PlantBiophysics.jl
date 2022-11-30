# Generate all methods for the photosynthesis process: several meteo time-steps, components,
#  over an MTG, and the mutating /non-mutating versions
@gen_process_methods "photosynthesis"


"""
Generic photosynthesis model for photosynthetic organs. Computes the assimilation and
stomatal conductance according to the models set in (or each component in) `object`.

The models used are defined by the types of the `photosynthesis` and `stomatal_conductance`
fields of `leaf`. For exemple to use the implementation of the Farquhar–von Caemmerer–Berry
(FvCB) model (see [`photosynthesis`](@ref)), the `leaf.photosynthesis` field should be of type
[`Fvcb`](@ref).

# Examples

```julia
meteo = Atmosphere(T = 20.0, Wind = 1.0, P = 101.3, Rh = 0.65)

# Using Fvcb model:
leaf =
    ModelList(
        photosynthesis = Fvcb(),
        stomatal_conductance = Medlyn(0.03, 12.0),
        status = (Tₗ = 25.0, PPFD = 1000.0, Cₛ = 400.0, Dₗ = meteo.VPD)
    )

photosynthesis(leaf, meteo)

# ---Using several components---

leaf2 = copy(leaf)
leaf2.status.PPFD = 800.0

photosynthesis([leaf,leaf2],meteo)

# ---Using several meteo time-steps---

w = Weather(
        [
            Atmosphere(T = 20.0, Wind = 1.0, P = 101.3, Rh = 0.65),
            Atmosphere(T = 25.0, Wind = 1.5, P = 101.3, Rh = 0.55)
        ],
        (site = "Test site,)
    )

photosynthesis(leaf, w)

# ---Using several meteo time-steps and several components---

photosynthesis(Dict(:leaf1 => leaf, :leaf2 => leaf2), w)

# Using a model file:

model = read_model("a-model-file.yml")

# Initialising the mandatory variables:
init_status!(model, Tₗ = 25.0, PPFD = 1000.0, Cₛ = 400.0, Dₗ = meteo.VPD)

# Running a simulation for all component types in the same scene:
photosynthesis!(model, meteo)
model["Leaf"].status.A

```
"""
photosynthesis, photosynthesis!
