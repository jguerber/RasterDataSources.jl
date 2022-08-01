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

    ondisk = true # flag for trying to read the layers file

    path = joinpath(
        ENV["RASTERDATASOURCES_PATH"],
        "MODIS/layers",
        prod*".csv"
    )

    layers = try
        open(path, "r") do f
            readline(f)
        end
    catch
        ondisk = false
    end

    if !ondisk # if not on disk we download layers info
        
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