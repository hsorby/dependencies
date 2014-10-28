CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
#cmake_policy(SET CMP0048 NEW) # Allows VERSION in project definitions
include(ExternalProject)

# This later goes to the top level cmake script (or whereever that will be)
LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

PROJECT (OpenCMISS_Dependencies)
include(OpenCMISS)

# LAPACK (includes BLAS)
FIND_PACKAGE(BLAS CONFIG QUIET)
FIND_PACKAGE(LAPACK CONFIG QUIET)
if(OCM_FORCE_BLAS OR OCM_FORCE_LAPACK OR NOT (LAPACK_FOUND AND BLAS_FOUND))
    ADD_EXTERNAL_PROJECT(LAPACK lapack)
endif()

# PLAPACK
if(OCM_USE_PLAPACK)
    FIND_PACKAGE(PLAPACK CONFIG QUIET)
    if(OCM_FORCE_PLAPACK OR NOT PLAPACK_FOUND)
        ADD_EXTERNAL_PROJECT(PLAPACK plapack)
    endif()
endif()

# ScaLAPACK
if(OCM_USE_SCALAPACK)
    FIND_PACKAGE(SCALAPACK CONFIG QUIET)
    if(OCM_FORCE_SCALAPACK OR NOT SCALAPACK_FOUND)
        ADD_EXTERNAL_PROJECT(SCALAPACK scalapack)
    endif()
endif()

# METIS 4.0.3
# Note: Parmetis also comes with a metis version, but suitesparse and mumps still only work with the 4.0.x versions
if (OCM_USE_METIS)
    FIND_PACKAGE(METIS 4.0 CONFIG QUIET)
    if(OCM_FORCE_METIS OR NOT METIS_FOUND)
        ADD_EXTERNAL_PROJECT(METIS metis)
    endif()
endif()

# parMETIS (+METIS)
if (OCM_USE_PARMETIS)
    FIND_PACKAGE(PARMETIS CONFIG QUIET)
    if(OCM_FORCE_PARMETIS OR NOT PARMETIS_FOUND)
        ADD_EXTERNAL_PROJECT(PARMETIS parmetis)
    endif()
endif()

# MUMPS
if (OCM_USE_MUMPS)
    FIND_PACKAGE(MUMPS CONFIG QUIET)
    if(OCM_FORCE_MUMPS OR NOT MUMPS_FOUND)
        ADD_EXTERNAL_PROJECT(MUMPS mumps OCM_USE_PARMETIS OCM_USE_METIS)
    endif()
endif()

# CHOLMOD / UMFPACK
if (OCM_USE_SUITESPARSE)
    FIND_PACKAGE(CHOLMOD CONFIG QUIET)
    FIND_PACKAGE(UMFPACK CONFIG QUIET)
    if(OCM_FORCE_CHOLMOD OR NOT CHOLMOD_FOUND OR OCM_FORCE_UMFPACK OR NOT UMFPACK_FOUND)
        ADD_EXTERNAL_PROJECT(SUITESPARSE suitesparse)
    endif()
endif()

# Hypre 2.9.0b
if (OCM_USE_HYPRE)
    FIND_PACKAGE(HYPRE CONFIG QUIET)
    if(OCM_FORCE_HYPRE OR NOT HYPRE_FOUND)
        ADD_EXTERNAL_PROJECT(HYPRE hypre)
    endif()
endif()

# SuperLU 4.3
if (OCM_USE_SUPERLU)
    FIND_PACKAGE(SUPERLU CONFIG QUIET)
    if(OCM_FORCE_SUPERLU OR NOT SUPERLU_FOUND)
        ADD_EXTERNAL_PROJECT(SUPERLU superlu)
    endif()
endif()

# SuperLU-DIST 4.0
if (OCM_USE_SUPERLU_DIST)
    FIND_PACKAGE(SUPERLU_DIST CONFIG QUIET)
    if(OCM_FORCE_SUPERLU_DIST OR NOT SUPERLU_DIST_FOUND)
        ADD_EXTERNAL_PROJECT(SUPERLU_DIST superlu_dist)
    endif()
endif()

# Notes:
# lapack: not sure if LAPACKE is build/required 
# plapack: have only MACHINE_TYPE=500 and MANUFACTURE=50 (linux)
# plapack: some tests are not compiling
# parmetis/metis: test programs not available (but for gklib, and they are also rudimental), linking executables instead to have a 50% "its working" test
# mumps - not setup for libseq / sequential version
# mumps - only have double precision arithmetics
# mumps - no PORD is compiled (will have parmetis/scotch available)
# mumps - hardcoded Add_ compiler flag for c/fortran interfacing.. dunno if that is the best idea
# metis: have fixed IDXTYPEWIDTH 32 
# cholmod: could go with CUDA BLAS version (indicated by makefile)
# umfpack: building only "int" version right now (Suitesparse_long impl for AMD,CAMD etc but not umfpack)


# TODO
# cholmod - use CUDA stuff