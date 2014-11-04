include(BuildMacros)

if (NOT CMAKE_BUILD_TYPE AND NOT WIN32)
    SET(CMAKE_BUILD_TYPE RELEASE)
    message(WARNING "No CMAKE_BUILD_TYPE has been defined. Using RELEASE.")
endif()

# The library path for all locally build dependencies
if (NOT WIN32)
    STRING(TOLOWER ${CMAKE_BUILD_TYPE} buildtype)
    SET(UNIXBUILDTYPEEXTRA "/${buildtype}")
else()
    # The multiconfig generators for VS ignore the CMAKE_BUILD_TYPE and hence would cause trouble if
    # any paths would've been deduced from that.
    SET(UNIXBUILDTYPEEXTRA "")
endif()
SET(OCM_DEPS_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install${UNIXBUILDTYPEEXTRA})

# ================================
# Dependencies
# ================================
# List of all dependency packages
SET(OCM_DEPS BLAS LAPACK PLAPACK SCALAPACK METIS
    PARMETIS SUITESPARSE MUMPS SUPERLU SUPERLU_DIST
    SUNDIALS SCOTCH PTSCOTCH PASTIX HYPRE)
# Forward/downstream dependencies (for cmake external build ordering)
SET(LAPACK_FWD_DEPS SCALAPACK SUITESPARSE MUMPS
    SUPERLU SUPERLU_DIST METIS PARMETIS
    HYPRE SUNDIALS PASTIX PLAPACK)
SET(METIS_FWD_DEPS MUMPS SUITESPARSE PASTIX)
SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST)
SET(SCALAPACK_FWD_DEPS MUMPS)
SET(PTSCOTCH_FWD_DEPS PASTIX)
SET(SCOTCH_FWD_DEPS PASTIX)

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
    if(OCM_FORCE_${OCM_DEP} OR FORCE_OCM_ALLDEPS)
        SET(OCM_FORCE_${OCM_DEP} YES)
    else()
        SET(OCM_FORCE_${OCM_DEP} NO)
    endif()
    message(STATUS "Package ${OCM_DEP}: Build: ${OCM_USE_${OCM_DEP}}, Custom ${${OCM_DEP}_CUSTOM}, OCM forced: ${OCM_FORCE_${OCM_DEP}}")
ENDFOREACH()