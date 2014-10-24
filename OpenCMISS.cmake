LIST(APPEND CMAKE_MODULE_PATH ${OCM_UTILS_DIR} ${OCM_UTILS_DIR}/cmake_modules)
include(BuildMacros)
#message(STATUS "Looking for cmake modules in: ${CMAKE_MODULE_PATH}")

# The library path for all locally build dependencies
SET(OPENCMISS_DEPENDENCIES_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR}/lib)
SET(OPENCMISS_DEPENDENCIES_EXECUTABLES ${CMAKE_CURRENT_SOURCE_DIR}/bin)
# Here will the config-files from self-built external projects reside
SET(OPENCMISS_DEPENDENCIES_CONFIGS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

LIST(APPEND CMAKE_MODULE_PATH ${OPENCMISS_DEPENDENCIES_CONFIGS_DIR})

# ================================
# Read custom config file
include(OpenCMISSLocalConfig)

# ================================
# Dependencies
# ================================
SET(LAPACK_FWD_DEPS SCALAPACK PLAPACK SUITESPARSE MUMPS SUPERLU SUPERLU_DIST METIS PARMETIS HYPRE)
SET(METIS_FWD_DEPS MUMPS SUITESPARSE)
SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST)
SET(SCALAPACK_FWD_DEPS MUMPS)
#SET(SUITESPARSE_FWD_DEPS BLAS LAP)

# Postprocessing
SET(OCM_DEPS BLAS LAPACK PLAPACK SCALAPACK PARMETIS CHOLMOD SUITESPARSE MUMPS SUPERLU SUPERLU_DIST)
FOREACH(OCM_DEP ${OCM_DEPS})
    if(DEBUG_${OCM_DEP} OR DEBUG_ALL)
        SET(DEBUG_${OCM_DEP} YES)
    else()
        SET(DEBUG_${OCM_DEP} NO)
    endif()
    if (${OCM_DEP}_LIBRARIES OR ${OCM_DEP}_LIBRARY)
        SET(${OCM_DEP}_CUSTOM YES)
    else()
        SET(${OCM_DEP}_CUSTOM NO)
    endif()
    if(OCM_FORCE_${OCM_DEP} OR ${FORCE_OCM_ALLDEPS})
        SET(OCM_FORCE_${OCM_DEP} YES)
    else()
        SET(OCM_FORCE_${OCM_DEP} NO)
    endif()
    message(STATUS "Package ${OCM_DEP}: Debug: ${DEBUG_${OCM_DEP}}, Custom ${${OCM_DEP}_CUSTOM}, OCM forced: ${OCM_FORCE_${OCM_DEP}}")
ENDFOREACH()
# ================================

# Debug stuff
SET(DEBUG_POSTFIX "dbg")