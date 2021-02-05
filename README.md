# RasterDataSources.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://cesaraustralia.github.io/RasterDataSources.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://cesaraustralia.github.io/RasterDataSources.jl/dev)
![CI](https://github.com/cesaraustralia/RasterDataSources.jl/workflows/CI/badge.svg)
[![codecov.io](http://codecov.io/github/cesaraustralia/RasterDataSources.jl/coverage.svg?branch=master)](http://codecov.io/github/cesaraustralia/RasterDataSources.jl?branch=master)

RasterDataSources downloads raster data for local use or for integration
into other spatial data packages, like
[GeoData.jl](https://github.com/rafaqz/GeoData.jl).

The collection is largely focussed on datasets relevant to ecology,
but will have a lot of crossover with other sciences.

Currently sources include :

| Source    | URL                                      | Status                               |
| --------- | ---------------------------------------- |--------------------------------------|
| CHELSA    | https://chelsa-climate.org               | BioClim layers only                  |
| WorldClim | https://www.worldclim.org                | Climate, Weather and BioClim layers  |
| EarthEnv  | http://www.earthenv.org                  | LandCover and HabitatHeterogeneity   |
| AWAP      | http://www.bom.gov.au/jsp/awap/index.jsp | Complete                             |
| ALWB      | http://www.bom.gov.au/water/landscape/   | Complete                             |

Please add an issue for more datasets to add, or create a PR 
following the form of the other datasets where possible.


Usage is generally via the `getraster` method - which will download the
raster data source if it isn't available locally, or simply return the path/s
of the raster file/s.

```julia
julia> using RasterDataSources

julia> getraster(WorldClim{Climate}, :wind)
12-element Array{String,1}:
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_01.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_02.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_03.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_04.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_05.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_06.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_07.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_08.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_09.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_10.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_11.tif"
 "/home/user/Data/WorldClim/Climate/wind/wc2.1_10m_wind_12.tif"
```

To download data you will need to specify a folder to put it in. You can do this
by assigning the environment variable `RASTERDATASOURCES_PATH`:

```julia
ENV["RASTERDATASOURCES_PATH"] = "/home/user/Data/"
```

This can be put in your `startup.jl` file or the system environment.


Pull requests are with additional data sources are welcomed, but should as much as
possible follow the structure used for existing data sources.

RasterDataSources was based on code from the `SimpleSDMDataSoures.jl`
package by Timothée Poisot.
