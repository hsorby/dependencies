include(BuildMacros)
#message(STATUS "Looking for cmake modules in: ${CMAKE_MODULE_PATH}")

if (NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE RELEASE)
endif()

# The library path for all locally build dependencies
STRING(TOLOWER ${CMAKE_BUILD_TYPE} buildtype)
SET(OPENCMISS_DEPENDENCIES_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR}/lib/${buildtype})
SET(OPENCMISS_DEPENDENCIES_EXECUTABLES ${CMAKE_CURRENT_SOURCE_DIR}/bin/${buildtype})
# Here will the config-files from self-built external projects reside
SET(OPENCMISS_DEPENDENCIES_CONFIGS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${buildtype})

# ================================
# Dependencies
# ================================
# List of all dependency packages
SET(OCM_DEPS BLAS LAPACK PLAPACK SCALAPACK PARMETIS CHOLMOD SUITESPARSE MUMPS SUPERLU SUPERLU_DIST)
# Forward/downstream dependencies (for cmake external build ordering)
SET(LAPACK_FWD_DEPS SCALAPACK PLAPACK SUITESPARSE MUMPS SUPERLU SUPERLU_DIST METIS PARMETIS HYPRE)
SET(METIS_FWD_DEPS MUMPS SUITESPARSE)
SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST)
SET(SCALAPACK_FWD_DEPS MUMPS)
#SET(SUITESPARSE_FWD_DEPS BLAS LAP)

# Default: Build all dependencies
FOREACH(OCM_DEP ${OCM_DEPS})
    SET(OCM_USE_${OCM_DEP} YES)
ENDFOREACH()

# ================================
# Read custom local config file
# ================================
if (NOT EXISTS ${CMAKE_CURRENT_LIST_DIR}/OpenCMISSLocalConfig.cmake)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/OpenCMISSLocalConfig.default.cmake ${CMAKE_CURRENT_LIST_DIR}/OpenCMISSLocalConfig.cmake COPYONLY)
endif()
include(OpenCMISSLocalConfig)

# ================================
# Postprocessing
# ================================
FOREACH(OCM_DEP ${OCM_DEPS})
    # Not currently used
    #if (${OCM_DEP}_LIBRARIES OR ${OCM_DEP}_LIBRARY)
    #    SET(${OCM_DEP}_CUSTOM YES)
    #else()
    #    SET(${OCM_DEP}_CUSTOM NO)
    #endif()
    if(OCM_FORCE_${OCM_DEP} OR FORCE_OCM_ALLDEPS)
        SET(OCM_FORCE_${OCM_DEP} YES)
    else()
        SET(OCM_FORCE_${OCM_DEP} NO)
    endif()
    message(STATUS "Package ${OCM_DEP}: Build: ${OCM_USE_${OCM_DEP}}, Custom ${${OCM_DEP}_CUSTOM}, OCM forced: ${OCM_FORCE_${OCM_DEP}}")
ENDFOREACH()