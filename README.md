# PlantBiophysics

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://VEZY.github.io/PlantBiophysics.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://VEZY.github.io/PlantBiophysics.jl/dev)
[![Build Status](https://github.com/VEZY/PlantBiophysics.jl/workflows/CI/badge.svg)](https://github.com/VEZY/PlantBiophysics.jl/actions)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

A pure Julia package to simulate biophysical processes for plants such as photosynthesis, conductances for heat, water vapor and CO₂, latent, sensible energy fluxes, net radiation and temperature.

The benefits of using this package are:

- Blazing fast (μs for the whole energy balance + photosynthesis + conductances)
- Easy to use
- Great composability. Makes it easy to extend (add your model for any process, and it just works with the others)
- Easy to read, the code implement the equations as they are written in the scientific articles (thanks Julia Unicode!)
- Included in the Archimed platform. Will be used by other packages to simulate single leaves, voxels, canopies...
- Soon:
  - Units
  - Error propagation
  - Sensitivity analyses

## Examples

Here is an example usage with a simulation of the energy balance and assimilation of a leaf:

```julia
# ]add PlantBiophysics https://github.com/VEZY/PlantBiophysics.jl
using PlantBiophysics

# Declaring the meteorology for the simulated time-step:
meteo = Atmosphere(T = 22.0, Wind = 0.8333, P = 101.325, Rh = 0.4490995)

# Using the model from Medlyn et al. (2011) for Gs and the model of Monteith and Unsworth (2013) for the
# energy balance:
leaf = LeafModels(geometry = Geom1D(0.03),
            energy = Monteith(),
            photosynthesis = Fvcb(),
            stomatal_conductance = Medlyn(0.03, 12.0),
            Rₛ = 13.747, skyFraction = 1.0, PPFD = 1500.0)

energy_balance(leaf,meteo)
```

For more examples, please read the documentation.

## Roadmap

- [x] Add FvCB model
- [x] Add FvCB iterative model
- [x] Add stomatal + boundary layer conductance models
- [x] Add energy balance model, coupled with photosynthesis amd stomatal conductance models
- [x] Make the functions work on the output from `read_model`.
- [ ] Add a new conductance model using the version from Duursma, Remko A, Christopher J Blackman, Rosana Lop, et K Martin-StPaul. 2018. « On the Minimum Leaf Conductance: Its Role in Models of Plant Water Use, and Ecological and Environmental Controls ». New Phytologist, 13.
- [ ] Make the functions compatible with an MTG, e.g. apply photosynthesis to an MTG, and use the right method for each node. NB: I think the models should be a field of the node.
- [ ] Make the functions compatible with several meteorological time-steps
  - [x] Add a new struct for that: Weather
  - [x] Do it for energy_balance
  - [x] photosynthesis
  - [ ] stomatal conductance
  - [ ] Add tests for each
  - [ ] Update the doc!
- [ ] Evaluate using Schymanski et al. (2017) data + leaf measurements models (in progress)
- [ ] Check Schymanski input: is Rs = Rnleaf ok? Because Rs is Rn - Rll.
- [ ] Add more documentation + tutorial:
  - [ ] add doc about the design (components, models, model values, multiple dispatch)
  - [ ] add doc about input files
  - [ ] add doc for each process
  - [ ] add a list of models for each process
  - [ ] add documentation for each model
  - [ ] add a tutorial for a single leaf at one time-step
  - [ ] add a tutorial for a single leaf at several time-step
  - [ ] add a tutorial for a plant
  - [ ] How to implement a new model -> e.g. conductance (add a `variables` method)
  - [ ] How to implement a new component:
    - add a component type (subtype of `AbstractComponent` or `AbstractPhotoComponent`)
    - add a keyword method for the type and use `init_variables_manual`
    - modify `get_component_type()`
    - add methods to functions eventually (unless they are already compatible)
- [ ] Use [PrettyTables.jl](https://ronisbr.github.io/PrettyTables.jl/stable/#PrettyTables.jl) for printing the Weather and simulation outputs

### Notes

The Fvcb model is implemented in two ways:

- as in MAESPA, where the model needs Cₛ as input. And Cₛ is computed in the energy balance model and helps to close the whole balance with leaf temperature. If needed, Cₛ can be given as Cₐ.
- as in Archimed, where the model needs Gbc, but not Cₛ (and Cₐ instead) because the model iterates over the assimilation until it finds a stable Cᵢ. This implementation
can be less efficient because of the iterations.

## Contributing

Contributions are welcome! If you develop a model for a process, please make a pull request so the community can enjoy it!

See contributor's guide badge for more informations: [![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac).

## Similar projects

- [MAESPA](http://maespa.github.io/)
- [photosynthesis](https://github.com/cran/photosynthesis) R package
- [plantecophys](https://bitbucket.org/remkoduursma/plantecophys/src/master/) R package
Leuning et al. (1995)
- [LeafGasExchange](https://github.com/TESTgroup-BNL/LeafGasExchange) R package

## References

Baldocchi, Dennis. 1994. « An analytical solution for coupled leaf photosynthesis and
stomatal conductance models ». Tree Physiology 14 (7-8‑9): 1069‑79.
https://doi.org/10.1093/treephys/14.7-8-9.1069.

Duursma, R. A., et B. E. Medlyn. 2012. « MAESPA: a model to study interactions between water
limitation, environmental drivers and vegetation function at tree and stand levels, with an
example application to [CO2] × drought interactions ». Geoscientific Model Development 5
(4): 919‑40. https://doi.org/10.5194/gmd-5-919-2012.

Farquhar, G. D., S. von von Caemmerer, et J. A. Berry. 1980. « A biochemical model of
photosynthetic CO2 assimilation in leaves of C3 species ». Planta 149 (1): 78‑90.

Leuning, R., F. M. Kelliher, DGG de Pury, et E.-D. SCHULZE. 1995. « LeafModels nitrogen,
photosynthesis, conductance and transpiration: scaling from leaves to canopies ». Plant,
Cell & Environment 18 (10): 1183‑1200.

Medlyn, B. E., E. Dreyer, D. Ellsworth, M. Forstreuter, P. C. Harley, M. U. F. Kirschbaum, X. Le Roux, et al. 2002. « Temperature response of parameters of a biochemically based model of photosynthesis. II. A review of experimental data ». Plant, Cell & Environment 25 (9): 1167‑79. https://doi.org/10.1046/j.1365-3040.2002.00891.x.

Monteith, John L., et Mike H. Unsworth. 2013. « Chapter 13 - Steady-State Heat Balance: (i) Water Surfaces, Soil, and Vegetation ». In Principles of Environmental Physics (Fourth Edition), edited by John L. Monteith et Mike H. Unsworth, 217‑47. Boston: Academic Press.

Schymanski, Stanislaus J., et Dani Or. 2017. « LeafModels-Scale Experiments Reveal an Important
Omission in the Penman–Monteith Equation ». Hydrology and Earth System Sciences 21 (2): 685‑706. https://doi.org/10.5194/hess-21-685-2017.

Vezy, Rémi, Mathias Christina, Olivier Roupsard, Yann Nouvellon, Remko Duursma, Belinda Medlyn, Maxime Soma, et al. 2018. « Measuring and modelling energy partitioning in canopies of varying complexity using MAESPA model ». Agricultural and Forest Meteorology 253‑254 (printemps): 203‑17. https://doi.org/10.1016/j.agrformet.2018.02.005.
