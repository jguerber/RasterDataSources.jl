"""
    MODIS{ModisProduct} <: RasterDataSource

MODIS/VIIRS Land Product Database. Vegetation indices, surface reflectance, and more land cover data.

See [modis.ornl.gov](https://modis.ornl.gov/)
"""
struct MODIS{X} <: RasterDataSource end

const MODIS_URI = URI(
    scheme = "https",
    host = "modis.ornl.gov",
    path = "/rst/api/v1"
)

function layerkeys(T::Type{MODIS{X}}) where X 
    layernames = list_layers(X)

    keys = []
    # For some products, layers have names that start with numbers, thus 
    # resulting in bad Symbol names. Here we remove some words from each
    # layer name until it's in a good format.
    for l in layernames
        newname = []
        words = split(l, "_")
        beginning = true
        for w in words # keep only "clean" words
            if beginning
                if match(r"^[0-9]|days|m|meters", w) === nothing
                    push!(newname, w)
                    beginning = false # added one word: no more checks
                end
            else
                push!(newname, w)
            end
        end
        push!(keys, Symbol(join(newname, "_"))) # build Array of newname Symbols
    end
    return Tuple(collect(keys)) # build tuple from Array{Symbol}
end

layerkeys(T::Type{<:ModisProduct}) = layerkeys(MODIS{T})

function layers(T::Type{MODIS{X}}) where X
    return Tuple(1:length(layerkeys(T)))
end

layers(T::Type{<:ModisProduct}) = layers(MODIS{T})

function get_raster(T::Type{<:ModisProduct}, layer::Union{Tuple, Symbol, Int};
    lat::Real,
    lon::Real,
    km_ab::Int,
    km_lr::Int,
    from::Union{String, Date},
    to::Union{String, Date}
)
    _get_raster(T, layer;
        lat = lat,
        lon = lon,
        km_ab = km_ab,
        km_lr = km_lr,
        from = from,
        to = to
    )
end

function _get_raster(T::Type{<:ModisProduct}, layer::Symbol;
    kwargs...
)
    _get_raster(T, modis_int(T, layer); kwargs)
end

function _get_raster(T::Type{<:ModisProduct}, layer::Int;
    lat::Real,
    lon::Real,
    km_ab::Int,
    km_lr::Int,
    from::Union{String, Date},
    to::Union{String, Date}
)
    dates = list_dates(T;
        lat = lat,
        lon = lon,
        format = "Date"
    )

    if length(dates) <= 10
        _get_raster(T, layer;
            lat = lat,
            lon = lon,
            km_ab = km_ab,
            km_lr = km_lr,
            dates = dates
        )
    else

    end
end

function rasterpath(T::Type{<:ModisProduct})
    return joinpath(rasterpath(), "MODIS", string(nameof(T)))
end

function rastername(T::Type{<:ModisProduct}, layer::Int; kwargs...)
    name = "$(layerkeys(T)[layer])_$(kwargs[:lat])_$(kwargs[:lon])_$(kwargs[:date]).tif"
    return name
end

function rastername(T::Type{<:ModisProduct}; kwargs...)
    name = "raster_$(kwargs[:lat])_$(kwargs[:lon])_$(kwargs[:date]).tif"
    return name
end




