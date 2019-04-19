# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                  LIBRARIES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(sf)
library(magrittr)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                    DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
load('./data/rawData/nightLights.RData')
load('./Data/Grids/Data/egslCoast.RData')
load('./Data/Grids/Data/egslGrid.RData')


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                 DRIVER LAYER
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Select coastal grid cells
# I choose all cells whose area touches less than 2km from the coast
coast <- egslCoast %>%
         st_buffer(2000) %>% # Buffer around coast line
         st_intersects(egslGrid) %>% # Intersect with grid
         unlist() %>%
         egslGrid[., ] # Select grid cells within 2km of the coast

# Apply a buffer to all coastal cells
bufGrid <- st_buffer(coast, 2000)

# Intersect buffered cells with night lights data
# Weight area average
coastDev <- sf::st_intersection(bufGrid, nl) %>% # zonal intersect
            dplyr::mutate(area = sf::st_area(.)) %>%
            st_set_geometry(NULL) %>%
            dplyr::group_by(ID) %>% # groups geometries by ID of grid cells
            dplyr::summarise(areaWghtAve = as.vector((NightLights %*% area) / sum(area))) %>% # area weighted average of attributes intersecting cells
            dplyr::left_join(bufGrid, ., by = 'ID') %>%
            dplyr::mutate(areaWghtAve = ifelse(is.na(areaWghtAve), 0, areaWghtAve)) %>%
            dplyr::rename(CoastalDevelopment = areaWghtAve)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                  EXPORT DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Export object as .RData
save(coastDev, file = './Data/Driver/CoastalDevelopment.RData')


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                 VISUALIZE DATA
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
png('./Figures/CoastalDevelopment.png', width = 1280, height = 1000, res = 200, pointsize = 6)
plot(coastDev[, 'CoastalDevelopment'], border = 'transparent')
dev.off()
