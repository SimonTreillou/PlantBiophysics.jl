module PlantBiophysics

# For model parameters (efficient and still mutable!)
using MutableNamedTuples

# For reading YAML:
using YAML
using OrderedCollections

# Generic structures:
include("structs.jl")

# Physical constants:
include("constants.jl")

# Atmosphere computations (vapor pressure...)
include("atmosphere.jl")

# Light interception
include("light_interception/generic_structs.jl")
include("light_interception/Ignore.jl")
include("light_interception/Translucent.jl")

# Photosynthesis related files:
include("photosynthesis/photosynthesis.jl")
include("photosynthesis/FvCB.jl")
include("photosynthesis/FvCBIter.jl")
include("photosynthesis/temperature-dependence.jl")

# stomatal conductance related files:
include("conductances/stomatal/constant.jl")
include("conductances/stomatal/gs.jl")
include("conductances/stomatal/medlyn.jl")


# boundary layer conductance:
include("conductances/boundary/gb.jl")

# Energy balance
include("energy/utilities.jl")
include("energy/longwave_energy.jl")
# include("energy/energy_balance.jl")

# File IO
include("io/read_model.jl")

# File IO:
export read_model
export is_model

# Atmosphere
export e
export e_sat
export e_sat_slope

# Energy balance
export black_body
export grey_body
export psychrometer_constant
export net_longwave_radiation

# structure for light interception
export Translucent
export Ignore
export OpticalProperties
export σ

# Photosynthesis
export Fvcb # Parameters for the Farquhar et al. (1980) model
export FvcbIter
export Constants
export assimilation
export gs
export Medlyn
export photosynthesis

# Physical constants
export Constants

# Temporary structures (to move to another package)
export Translucent
export Ignore

# Organs (structures that hold models)
export Leaf
export Metamer

end
