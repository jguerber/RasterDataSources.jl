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





