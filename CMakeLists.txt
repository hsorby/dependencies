PROJECT (OpenCMISS_Dependencies)
CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
include(ExternalProject)

SET(OCM_UTILS_DIR ${OpenCMISS_Dependencies_SOURCE_DIR}/../utils)

# This later goes to the top level cmake script (or whereever that will be)
include(${OCM_UTILS_DIR}/OpenCMISS.cmake)

# Put all 3rd party libraries/executables into one folder
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OPENCMISS_DEPENDENCIES_EXECUTABLES})
SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OPENCMISS_DEPENDENCIES_LIBRARIES})
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${OPENCMISS_DEPENDENCIES_LIBRARIES})

# TESTING/DEBUG STUFF
#SET(PLATFORM_BUILD_COMMAND make -j8)
#

# MPI
# Deal with all the MPI stuff later
#FIND_PACKAGE(MPI REQUIRED)

#SET(CMAKE_C_COMPILER ${MPI_C_COMPILER})
#SET(CMAKE_C_FLAGS "-O3")
#SET(CMAKE_Fortran_COMPILER ${MPI_Fortran_COMPILER})
#SET(CMAKE_Fortran_FLAGS "-fno-f2c -O3 -Q")

#add_library(ocm_mpi STATIC IMPORTED)
#set_property(TARGET ocm_mpi APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
#set_target_properties(ocm_mpi PROPERTIES
#  INTERFACE_INCLUDE_DIRECTORIES "${MPI_Fortran_INCLUDE_PATH};${MPI_C_INCLUDE_PATH}"
 #IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "C"
 #IMPORTED_LINK_INTERFACE_LIBRARIES_NOCONFIG "m"
#  IMPORTED_LOCATION_NOCONFIG "${MPI_C_LIBRARIES};${MPI_Fortran_LIBRARIES}"
#)
#get_property(outvar TARGET ocm_mpi PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
#message(STATUS "INTERFACE_INCLUDE_DIRECTORIES of ocm_mpi: ${outvar}")
#PRINT_VARS()

# LAPACK (includes BLAS)
FIND_PACKAGE(BLAS CONFIG QUIET)
FIND_PACKAGE(LAPACK CONFIG QUIET)
if(OCM_FORCE_BLAS OR OCM_FORCE_LAPACK OR NOT (LAPACK_FOUND AND BLAS_FOUND))
    ADD_EXTERNAL_PROJECT(LAPACK lapack "")
    SET(PLAPACK_DEPS LAPACK)
    SET(SCALAPACK_DEPS LAPACK)
endif()

# PLAPACK
FIND_PACKAGE(PLAPACK CONFIG QUIET)
if(OCM_FORCE_PLAPACK OR NOT PLAPACK_FOUND)
    ADD_EXTERNAL_PROJECT(PLAPACK plapack ${PLAPACK_DEPS})
endif()

# ScaLAPACK
FIND_PACKAGE(SCALAPACK CONFIG QUIET)
if(OCM_FORCE_SCALAPACK OR NOT SCALAPACK_FOUND)
    ADD_EXTERNAL_PROJECT(SCALAPACK scalapack ${SCALAPACK_DEPS})
endif()

# parMETIS (+METIS)
if (OCM_USE_PARMETIS)
    FIND_PACKAGE(PARMETIS CONFIG QUIET)
    if(OCM_FORCE_PARMETIS OR NOT PARMETIS_FOUND)
        ADD_EXTERNAL_PROJECT(PARMETIS parmetis "")
    endif()
endif()

# MUMPS
#if (NOT MUMPS_CUSTOM)
#    FIND_PACKAGE(MUMPS QUIET)
#endif()
#if(OCM_FORCE_MUMPS OR NOT MUMPS_FOUND)
#    message(STATUS "parmetis includes: ${PARMETIS_INCLUDES}")
#    add_subdirectory(mumps)
#endif()

# CHOLMOD
#if (NOT CHOLMOD_CUSTOM)
#    FIND_PACKAGE(CHOLMOD QUIET)
#endif()
#if(OCM_FORCE_CHOLMOD OR NOT CHOLMOD_FOUND)
#    add_subdirectory(suitesparse/SuiteSparse_config)
#    add_subdirectory(suitesparse/AMD)
#    add_subdirectory(suitesparse/COLAMD)
#    add_subdirectory(suitesparse/CAMD)
#    add_subdirectory(suitesparse/CCOLAMD)
#    add_subdirectory(suitesparse/CHOLMOD)
#endif()


# Notes:
# plapack: have only MACHINE_TYPE=500 and MANUFACTURE=50 (linux)
# mumps - not setup for libseq / sequential version
# mumps - only have double precision arithmetics
# mumps - no PORD is compiled (will have parmetis/scotch available)

# TODO
# cholmod - use CUDA stuff