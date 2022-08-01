"""
    MODIS{ModisProduct} <: RasterDataSource

MODIS/VIIRS Land Product Database. Vegetation indices, surface reflectance, and more land cover data.

See [modis.ornl.gov](https://modis.ornl.gov/)
"""
struct MODIS{X::ModisProduct} <: RasterDataSource end





