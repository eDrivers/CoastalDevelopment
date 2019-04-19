# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                     LIBRARIES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(raster)
library(sf)
library(magrittr)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                   DOWNLOAD DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The data used to characterize coastal development is the Nighttime Lights Time
# Series. Nighttime light products are compiled by the Earth Observation Group
# at the National Oceanic and Atmospheric Administration’s (NOAA) National
# Centers for Environmental Information (NCEI)
# For more information read the repo's README.md document

# Output location for downloaded data
output <- './Data/RawData'

# URLs
link <- c(
  "https://data.ngdc.noaa.gov/instruments/remote-sensing/passive/spectrometers-radiometers/imaging/viirs/dnb_composites/v10//2015/SVDNB_npp_20150101-20151231_75N060W_v10_c201701311200.tgz",
  "https://data.ngdc.noaa.gov/instruments/remote-sensing/passive/spectrometers-radiometers/imaging/viirs/dnb_composites/v10//2016/SVDNB_npp_20160101-20161231_75N060W_v10_c201807311200.tgz",
  "https://data.ngdc.noaa.gov/instruments/remote-sensing/passive/spectrometers-radiometers/imaging/viirs/dnb_composites/v10//2016/SVDNB_npp_20160101-20161231_75N180W_v10_c201807311200.tgz",
  "https://data.ngdc.noaa.gov/instruments/remote-sensing/passive/spectrometers-radiometers/imaging/viirs/dnb_composites/v10//2015/SVDNB_npp_20150101-20151231_75N180W_v10_c201701311200.tgz"
)

# Export names
export <- c(
  "SVDNB_npp_20150101-20151231_75N060W_vcm-orm-ntl_v10_c201701311200.avg_rade9.tif",
  "SVDNB_npp_20160101-20161231_75N060W_vcm-orm-ntl_v10_c201807311200.avg_rade9.tif",
  "SVDNB_npp_20150101-20151231_75N180W_vcm-orm-ntl_v10_c201701311200.avg_rade9.tif",
  "SVDNB_npp_20160101-20161231_75N180W_vcm-orm-ntl_v10_c201807311200.avg_rade9.tif"
)

# ID of file to download on repository
fileID <- data.frame(link, export, stringsAsFactors = F)


# Build string to send wget command to the terminal throught R
wgetString <- paste0('wget --user-agent Mozilla/5.0 "',
                     fileID$link,
                     '" -O ',
                     output,
                     '/',
                     fileID$export)

# Download data using `wget`
for(i in wgetString) system(noquote(i), intern = T)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                   IMPORT DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Untar files
# 2015 E
untar(paste0(output, '/', "SVDNB_npp_20150101-20151231_75N060W_v10_c201701311200.tgz"),
      files = c("./SVDNB_npp_20150101-20151231_75N060W_vcm-orm-ntl_v10_c201701311200.avg_rade9.tif",
                "./README_dnb_composites_v1.txt"),
      exdir = output)

# 2016 E
untar(paste0(output, '/', "SVDNB_npp_20160101-20161231_75N060W_v10_c201807311200.tgz"),
      files = "./SVDNB_npp_20160101-20161231_75N060W_vcm-orm-ntl_v10_c201807311200.avg_rade9.tif",
      exdir = output)

# 2015 W
untar(paste0(output, '/', "SVDNB_npp_20150101-20151231_75N180W_v10_c201701311200.tgz"),
      files = "./SVDNB_npp_20150101-20151231_75N180W_vcm-orm-ntl_v10_c201701311200.avg_rade9.tif",
      exdir = output)

# 2016 W
untar(paste0(output, '/', "SVDNB_npp_20160101-20161231_75N180W_v10_c201807311200.tgz"),
      files = "./SVDNB_npp_20160101-20161231_75N180W_vcm-orm-ntl_v10_c201807311200.avg_rade9.tif",
      exdir = output)


# Import tif files
nl2015E <- raster(paste0(output, '/', 'SVDNB_npp_20150101-20151231_75N060W_vcm-orm-ntl_v10_c201701311200.avg_rade9.tif'))
nl2016E <- raster(paste0(output, '/', 'SVDNB_npp_20160101-20161231_75N060W_vcm-orm-ntl_v10_c201807311200.avg_rade9.tif'))
nl2015W <- raster(paste0(output, '/', 'SVDNB_npp_20150101-20151231_75N180W_vcm-orm-ntl_v10_c201701311200.avg_rade9.tif'))
nl2016W <- raster(paste0(output, '/', 'SVDNB_npp_20160101-20161231_75N180W_vcm-orm-ntl_v10_c201807311200.avg_rade9.tif'))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                   CLIP DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# We clip the data to the extent of the St. Lawrence to make it easier to work with
# Remove this part of the code if you wish to work with the global data or
# modify the extent if you want to use it on a different extent

# Study area extent
# Roughly selecting the St. Lawrence
ext <- c(xmin = -78.48951, xmax = -49.51001, ymin = 45.03379, ymax = 52.73329) %>%
       extent()

# Crop raster to extent
nl2015E <- crop(nl2015E, ext)
nl2016E <- crop(nl2016E, ext)
nl2015W <- crop(nl2015W, ext)
nl2016W <- crop(nl2016W, ext)

# Merge annual rasters
nl2015 <- merge(nl2015E, nl2015W)
nl2016 <- merge(nl2016E, nl2016W)

# Measure the mean of values between 2015 and 2016
# No time series used for this, but remove this to consider years separately
# Note: process takes a few minutes to run
nl <- overlay(nl2015, nl2016, fun = mean)

# Copy raster values to memory to that export is done properly
values(nl) <- values(nl)

# Modify projection
# We use the Lambert projection as a default, which allows us to work in meters
# rather than in degrees
prj <- st_crs(32198)$proj4string
nl <- projectRaster(nl, crs = prj)

# Steps to select only relevant raster cells, as too much is not doable computationally
# I need to give terrestrial values to coastal values
  # 1. Import coastal trait shapefile
  # 2. Apply a buffer to the trait of size = 1000 meters
  # 3. Select coastal cells using the buffered trait
  # 4. Apply a buffer to coastal cells of size = 1000 meters
  # 5. Intersect buffered coastal cells with night light shapefile
  # 6. Join intersected values with study grid

# Data
data(egslGrid)
data(egslCoast)

# Subselection of night lights file to make it manageable
# I am selecting all raster cells that fall within 10km of the coastline
load('./Data/Grids/Data/egslCoast.RData')
nl <- egslCoast %>%
      st_buffer(10000) %>% # buffer around coast line
      as('Spatial') %>% # Transform as sp object
      mask(nl, .) %>% # Select raster cells intersecting the buffered coast line
      rasterToPolygons() %>% # Transform masked raster as a polygons shapefile
      st_as_sf() # transform back as sf object

# Change name
colnames(nl)[1] <- 'NightLights'

# Select only features with values > 0
id0 <- nl$NightLights > 0
nl <- nl[id0, ]


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                  EXPORT DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Export object as .RData
save(nl, file = './data/rawData/nightLights.RData')
