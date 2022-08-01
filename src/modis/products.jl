"""
    This file contains functions to handle MODIS product info.

Depending on missions and products, MODIS data does not have the
same layers.
"""

"""
    Extracts product name as a `String`
"""
function product(T::Type{<:ModisProduct})
    return String(nameof(T))
end

"""
    Lists availabe layers for a given MODIS Product

Looks in `joinpath(ENV["RASTERDATASOURCES_PATH"]/MODIS/layers` for
a file with the right name. If not found, sends a request to the server
to get the list.

This allows to make as many internal calls of layers() and layerkeys() as
needed without issuing a lot of requests.
"""
function list_layers(T::Type{<:ModisProduct})
    
    prod = product(T)

    path = joinpath(
        ENV["RASTERDATASOURCES_PATH"],
        "MODIS/layers",
        prod*".csv"
    )

    if isfile(path)
        layers = open(path, "r") do f
            readline(f)
        end
    else # if not on disk we download layers info
        
        @info "Starting download of layers list for product $prod"
        mkpath(dirname(path))
        r = HTTP.download(
            joinpath(string(MODIS_URI), prod, "bands"),
            path,
            ["Accept" => "text/csv"]
        )

        # read downloaded file
        layers = open(path, "r") do f
            readline(f)
        end

    end

    return split(String(layers), ",")
end

"""
    List available dates for a MODIS product at given coordinates
"""
function list_dates(T::Type{<:ModisProduct};
    lat::Real,
    lon::Real,
    from::String = "all", # might be handy
    to::String = "all")

    prod = product(T)
    ondisk = true
end