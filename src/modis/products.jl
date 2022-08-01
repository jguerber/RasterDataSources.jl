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
    to::String = "all",
    format::String = "Date")

    prod = product(T)
    
    @info "Requesting availables dates for product $prod at $lat , $lon"

    r = HTTP.request(
        "GET",
        joinpath(string(MODIS_URI), prod, "dates"),
        query = Dict(
            "latitude" => string(lat),
            "longitude" => string(lon)
        )
    )

    body = JSON.parse(String(r.body))

    #prebuild columns
    df = DataFrame(
        calendar_date=String[],
        modis_date=String[]
    )

    # fill
    for date in body["dates"]
        push!(df, date; cols=:subset)
    end

    df.calendar_date = Date.(df.calendar_date)
        
    from == "all" && (from = df[1, :calendar_date])
    to == "all" && (to = df[end, :calendar_date])

    df = subset(
        df,
        :calendar_date => d -> Date(to) .>= d,
        :calendar_date => d -> d .>= Date(from)  
        )

    if format == "ModisDate"
        return df[:, :modis_date]
    else
        return df[:, :calendar_date]
    end
end