"""
    MODIS-specific utility functions

MODIS data is not available in .tif format so we need a bit more
steps before storing the retrieved data and we can't download() it.

Data parsing is way easier using JSON.jl and DataFrames.jl but it
adds more dependencies..
"""

function modis_int(T::Type{<:ModisProduct}, l::Symbol)
    keys = layerkeys(T)
    for i in eachindex(keys)
        keys[i] === l && return(i)
    end 
end

"""
    Lowest level function for requests to modis server.

All arguments are assumed of correct types
"""
function modis_request(
    T::Type{<:ModisProduct},
    layer,
    lat,
    lon,
    km_ab,
    km_lr,
    from,
    to
)
    base_uri = joinpath(string(MODIS_URI), product(T), "subset")
    query = string(URI(; query = Dict(
        "latitude" => string(lat),
        "longitude" => string(lon),
        "startDate" => string(from),
        "endDate" => string(to),
        "kmAboveBelow" => string(km_ab),
        "kmLeftRight" => string(km_lr),
        "band" => string(layer)
    )))

    r = HTTP.request(
        "GET",
        URI(base_uri * query),
        ["Accept" => "application/json"]
    )

    body = JSON.parse(String(r.body))

    # The server outputs data in a nested JSON array that we can
    # parse manually : the highest level is a metadata array with
    # a "subset" column containing pixel array for each (band, timepoint)

    metadata = DataFrame(body)[:, Not(:subset)]

    out = DataFrame()

    for i in 1:nrow(metadata) # for each (band, time)

        subset = DataFrame(body["subset"][i])
        subset.pixel = 1:nrow(subset)

        # this thing here could be prettier..

        subset.cellsize .= metadata[i, :cellsize]
        subset.latitude .= metadata[i, :latitude]
        subset.longitude .= metadata[i, :longitude]
        subset.ncols .= metadata[i, :ncols]
        subset.nrows .= metadata[i, :nrows]
        subset.xllcorner .= metadata[i, :xllcorner]
        subset.yllcorner .= metadata[i, :yllcorner]
        subset.header .= metadata[i, :header]

        out = [out; subset]
    end

    return out
end

# using EPSG.io API (found on GitHub)
function sin_to_ll(x::Real, y::Real)

    url = "https://epsg.io/trans"

    query = Dict(
        "x" => string(x),
        "y" => string(y),
        "s_srs" => "53008", # sinusoidal
        "t_srs" => "4326" # WGS84
    )

    r = HTTP.request(
        "GET",
        url;
        query = query
    )

    body = JSON.parse(String(r.body))

    lat = parse(Float64, body["y"])
    lon = parse(Float64, body["x"])

    return (lat, lon)
end

# data from https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
const EARTH_EQ_RADIUS = 6378137
const EARTH_POL_RADIUS = 6356752

function meters_to_latlon(d::Real, lat::Real)
    dlon = asind(d/(cosd(lat)*EARTH_EQ_RADIUS))
    dlat = d * 180 / (π * EARTH_POL_RADIUS)

    return (dlat, dlon)
end

"""
    Process a raw subset dataframe and create several rasters
"""
function process_subset(T::Type{<:ModisProduct}, df::DataFrame)
    
    dates = unique(df[:, :calendar_date])
    bands = unique(df[:, :band])

    ncols = df[1, :ncols]
    nrows = df[1, :nrows]

    cellsize = df[1, :cellsize]

    xllcorner = parse(Float64, df[1, :xllcorner])
    yllcorner = parse(Float64, df[1, :yllcorner])

    # build a bounding box for the raster(s)
    lon, lat = sin_to_ll(xllcorner, yllcorner)
        
    resolution = meters_to_latlon(
        cellsize,
        lat
    ) # pixel size in (latitudinal, longitudinal) degrees

    bbox = [lat - resolution[1]/2, resolution[1], 0.0, lon - resolution[2]/2, 0.0, -resolution[2]]
    
    raster_path = rasterpath(T)

    path_out = String[]

    for d in eachindex(dates)

        raster_name = rastername(T;
            lat = lat,
            lon = lon,
            date = dates[d]
        )

        ar = Array{Float64}(undef, nrows, ncols, length(bands))
        
        for b in eachindex(bands)

            sub_df = subset(df,
                :calendar_date => x -> x .== dates[d],
                :band => y -> y .== bands[b]
            )
            
            mat = Matrix{Float64}(undef, nrows, ncols)

            # fill matrix row by row
            count = 1
            for j in 1:ncols
                for i in 1:nrows
                    mat[i,j] = float(sub_df[count, :data])
                    count += 1
                end
            end

            ar[:,:,b] = mat

            mkpath(joinpath(raster_path, bands[b]))

            if !isfile(raster_path, bands[b], raster_name)
                ArchGDAL.create(
                    joinpath(raster_path, bands[b], raster_name),
                    driver = ArchGDAL.getdriver("GTiff"),
                    width = ncols,
                    height = nrows,
                    nbands = length(bands),
                    dtype = Float32
                ) do dataset
                    # add data to object
                    for b in eachindex(bands)
                        ArchGDAL.write!(dataset, mat, 1)
                    end
                    # set bounding box
                    ArchGDAL.setgeotransform!(dataset, bbox)
                    # set crs
                    ArchGDAL.setproj!(dataset, ArchGDAL.toWKT(
                        ArchGDAL.importPROJ4("+proj=latlong +ellps=WGS84 +datum=WGS84 +no_defs"))
                    )
                end
            end

            push!(path_out, joinpath(raster_path, raster_name))

        end
    end

    return (length(path_out) == 1 ? path_out[1] : path_out)
end