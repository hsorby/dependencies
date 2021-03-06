CMAKE_MINIMUM_REQUIRED(VERSION 3.0 FATAL_ERROR)
PROJECT(OpenCMISS_Dependencies VERSION 1.0 LANGUAGES C CXX Fortran)

# See if we're running outside of the opencmiss main build script
# We still need the dependencies
if (NOT OPENCMISS_BUILD) 
    SET(OPENCMISS_UTILITIES_DIR ${OpenCMISS_Dependencies_SOURCE_DIR}/../utilities)
    if(NOT EXISTS ${OPENCMISS_UTILITIES_DIR})
        message(FATAL_ERROR "Cant build dependencies directly: Utilities folder ${OPENCMISS_UTILITIES_DIR} missing.")
    endif()
    if(NOT EXISTS ${OpenCMISS_Dependencies_SOURCE_DIR}/../OpenCMISSLocalConfig.cmake)
        message(FATAL_ERROR "Cant build dependencies directly: Missing ${OpenCMISS_Dependencies_SOURCE_DIR}/../OpenCMISSLocalConfig.cmake")
    endif()
    LIST(APPEND CMAKE_MODULE_PATH 
        ${OPENCMISS_UTILITIES_DIR}/CMakeFindModuleWrappers
        ${OpenCMISS_Dependencies_SOURCE_DIR}/..
        ${OPENCMISS_UTILITIES_DIR}/CMakeModules
        ${OPENCMISS_UTILITIES_DIR}/CMakeScripts)
endif()
#message(STATUS "OpenCMISS-Dependencies module path: ${CMAKE_MODULE_PATH}")

# ================================
# Dependencies
# ================================
# List of all dependency packages
SET(OCM_DEPS BLAS LAPACK PLAPACK SCALAPACK PARMETIS
    SUITESPARSE MUMPS SUPERLU SUPERLU_DIST
    SUNDIALS SCOTCH PTSCOTCH PASTIX HYPRE PETSC
    CELLML SLEPC)

# Dependencies using (any) MPI
# Used to determine when MPI compilers etc should be passed down to packages
SET(OCM_DEPS_WITHMPI MUMPS PARMETIS PASTIX PETSC
    PLAPACK SCALAPACK SCOTCH SUITESPARSE
    SUNDIALS SUPERLU_DIST SLEPC HYPRE)

# Forward/downstream dependencies (for cmake build ordering and dependency checking)
# Its organized this way as not all backward dependencies might be built by the cmake
# system. here, the actual dependency list is filled "as we go" and actually build
# packages locally, see ADD_DOWNSTREAM_DEPS in BuildMacros.cmake
SET(HYPRE_FWD_DEPS PETSC)
SET(LAPACK_FWD_DEPS SCALAPACK SUITESPARSE MUMPS
        SUPERLU SUPERLU_DIST PARMETIS HYPRE SUNDIALS PASTIX PLAPACK PETSC)
SET(MUMPS_FWD_DEPS PETSC)
SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST PASTIX)
SET(PASTIX_FWD_DEPS PETSC)
SET(PTSCOTCH_FWD_DEPS PASTIX PETSC MUMPS)
SET(SCALAPACK_FWD_DEPS MUMPS PETSC)
SET(SCOTCH_FWD_DEPS PASTIX PETSC MUMPS)
SET(SUNDIALS_FWD_DEPS PETSC)
SET(SUPERLU_FWD_DEPS PETSC)
SET(SUITESPARSE_FWD_DEPS PETSC)
SET(SUPERLU_DIST_FWD_DEPS PETSC)
SET(PETSC_FWD_DEPS SLEPC)

# Default: Build all dependencies
# This is changeable in the OpenCMISSLocalConfig file
FOREACH(OCM_DEP ${OCM_DEPS})
    SET(OCM_USE_${OCM_DEP} YES)
ENDFOREACH()

# ================================
# Read custom local config file
# ================================
include(OpenCMISSLocalConfig)

# ================================
# Postprocessing
# ================================
FOREACH(OCM_DEP ${OCM_DEPS})
    if(OCM_FORCE_${OCM_DEP} OR FORCE_OCM_ALLDEPS)
        SET(OCM_FORCE_${OCM_DEP} YES)
        # If forced we'll also use it right?
        SET(OCM_USE_${OCM_DEP} YES)
    else()
        SET(OCM_FORCE_${OCM_DEP} NO)
    endif()
    # Make a dependency check and enable other packages if required
    #if (${OCM_DEP}_FWD_DEPS)
    #    foreach(FWD_DEP ${${OCM_DEP}_FWD_DEPS})
    #        if(OCM_USE_${FWD_DEP} AND NOT OCM_USE_${OCM_DEP})
    #            message(STATUS "Package ${FWD_DEP} requires ${OCM_DEP}, setting OCM_USE_${OCM_DEP}=ON")
    #            set(OCM_USE_${OCM_DEP} ON)
    #        endif() 
    #    endforeach()
    #endif()
    
    message(STATUS "Package ${OCM_DEP}: Build: ${OCM_USE_${OCM_DEP}}, OCM forced: ${OCM_FORCE_${OCM_DEP}}")
ENDFOREACH()

# ================================
# Default installation path if none is given
# ================================
include(./OCMDepsBuildMacros.cmake)

if (NOT OPENCMISS_BUILD AND CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    # Need MPI information for correct arch path
    find_package(MPI MODULE QUIET)
    #include(OpenCMISSLocalConfig)
    get_architecture_path(ARCHITECTURE_PATH)
    get_build_type_extra(BUILDTYPEEXTRA)
    SET(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install/${ARCHITECTURE_PATH}/${BUILDTYPEEXTRA})
endif()
message(STATUS "OpenCMISS-Dependencies will be installed to ${CMAKE_INSTALL_PREFIX}")

# ================================
# Package creation
# ================================
# Note: The following order for all packages has to be in their interdependency order,
# i.e. mumps may need scotch so scotch has to be processed first on order to be added to the 
# external project dependencies list of any following package

# LAPACK (includes BLAS)
if(NOT OCM_FORCE_BLAS)
    find_package(BLAS ${BLAS_VERSION} QUIET)
endif()
if(NOT OCM_FORCE_LAPACK) 
    find_package(LAPACK ${LAPACK_VERSION} QUIET)
endif()    
if(OCM_FORCE_BLAS OR OCM_FORCE_LAPACK OR NOT (LAPACK_FOUND AND BLAS_FOUND))
    ADD_EXTERNAL_PROJECT(LAPACK lapack)
endif()

# Scotch 6.0
if (OCM_USE_PTSCOTCH)
    if (NOT OCM_FORCE_PTSCOTCH)
        FIND_PACKAGE(PTSCOTCH ${PTSCOTCH_VERSION} QUIET)
    endif()
    if(OCM_FORCE_PTSCOTCH OR NOT PTSCOTCH_FOUND)
        ADD_EXTERNAL_PROJECT(SCOTCH scotch
            BUILD_PTSCOTCH=YES USE_GZ=${SCOTCH_USE_GZ}
            USE_PTHREAD=${SCOTCH_USE_PTHREAD})
    endif()
elseif(OCM_USE_SCOTCH)
    if(NOT OCM_FORCE_SCOTCH)
        FIND_PACKAGE(SCOTCH ${SCOTCH_VERSION} QUIET)
    endif()
    if(OCM_FORCE_SCOTCH OR NOT SCOTCH_FOUND)
        ADD_EXTERNAL_PROJECT(SCOTCH scotch 
            BUILD_PTSCOTCH=NO USE_GZ=${SCOTCH_USE_GZ}
            USE_PTHREAD=${SCOTCH_USE_PTHREAD})
    endif()
endif()

# PLAPACK
if(OCM_USE_PLAPACK)
    if(NOT OCM_FORCE_PLAPACK)
        FIND_PACKAGE(PLAPACK QUIET)
    endif()        
    if(OCM_FORCE_PLAPACK OR NOT PLAPACK_FOUND)
        ADD_EXTERNAL_PROJECT(PLAPACK plapack
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# ScaLAPACK
if(OCM_USE_SCALAPACK)
    if(NOT OCM_FORCE_SCALAPACK)
        FIND_PACKAGE(SCALAPACK ${SCALAPACK_VERSION} QUIET)
    endif()
    if(OCM_FORCE_SCALAPACK OR NOT SCALAPACK_FOUND)
        ADD_EXTERNAL_PROJECT(SCALAPACK scalapack
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# parMETIS 4 (+METIS 5)
if(OCM_USE_PARMETIS)
    if(NOT OCM_FORCE_PARMETIS)
        FIND_PACKAGE(PARMETIS ${PARMETIS_VERSION} QUIET)
    endif()
    if(OCM_FORCE_PARMETIS OR NOT PARMETIS_FOUND)
        ADD_EXTERNAL_PROJECT(PARMETIS parmetis)
    endif()
endif()

# MUMPS
if (OCM_USE_MUMPS)
    if(NOT OCM_FORCE_MUMPS)
        FIND_PACKAGE(MUMPS ${MUMPS_VERSION} QUIET)
    endif()
    if(OCM_FORCE_MUMPS OR NOT MUMPS_FOUND)
        ADD_EXTERNAL_PROJECT(MUMPS mumps 
            USE_SCOTCH=${MUMPS_WITH_SCOTCH}
            USE_PTSCOTCH=${MUMPS_WITH_PTSCOTCH}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCOTCH_VERSION=${SCOTCH_VERSION}
            USE_PARMETIS=${MUMPS_WITH_PARMETIS}
            PARMETIS_VERSION=${PARMETIS_VERSION}
        )
    endif()
endif()

# SUITESPARSE [CHOLMOD / UMFPACK]
if (OCM_USE_SUITESPARSE)
    if(NOT OCM_FORCE_SUITESPARSE)
        FIND_PACKAGE(SUITESPARSE ${SUITESPARSE_VERSION} QUIET)
    endif()
    if(OCM_FORCE_SUITESPARSE OR NOT SUITESPARSE_FOUND)
        ADD_EXTERNAL_PROJECT(SUITESPARSE suitesparse
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION}
            METIS_VERSION=${METIS_VERSION})
    endif()
endif()

# Hypre 2.9.0b
if (OCM_USE_HYPRE)
    if(NOT OCM_FORCE_HYPRE)
        FIND_PACKAGE(HYPRE ${HYPRE_VERSION} QUIET)
    endif()
    if(OCM_FORCE_HYPRE OR NOT HYPRE_FOUND)
        ADD_EXTERNAL_PROJECT(HYPRE hypre
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# SuperLU 4.3
if (OCM_USE_SUPERLU)
    if(NOT OCM_FORCE_SUPERLU)
        FIND_PACKAGE(SUPERLU ${SUPERLU_VERSION} QUIET)
    endif()        
    if(OCM_FORCE_SUPERLU OR NOT SUPERLU_FOUND)
        ADD_EXTERNAL_PROJECT(SUPERLU superlu
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# SuperLU-DIST 4.0
if (OCM_USE_SUPERLU_DIST)
    if(NOT OCM_FORCE_SUPERLU_DIST)
        FIND_PACKAGE(SUPERLU_DIST ${SUPERLU_DIST_VERSION} QUIET)
    endif()        
    if(OCM_FORCE_SUPERLU_DIST OR NOT SUPERLU_DIST_FOUND)
        ADD_EXTERNAL_PROJECT(SUPERLU_DIST superlu_dist
            BLAS_VERSION=${BLAS_VERSION}
            USE_PARMETIS=${SUPERLU_DIST_WITH_PARMETIS}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            USE_METIS=${SUPERLU_DIST_WITH_METIS}
            METIS_VERSION=${METIS_VERSION}
        )
    endif()
endif()

# Sundials 2.5
if (OCM_USE_SUNDIALS)
    if(NOT OCM_FORCE_SUNDIALS)
        FIND_PACKAGE(SUNDIALS ${SUNDIALS_VERSION} QUIET)
    endif()
    if(OCM_FORCE_SUNDIALS OR NOT SUNDIALS_FOUND)
        ADD_EXTERNAL_PROJECT(SUNDIALS sundials
            USE_LAPACK=${SUNDIALS_WITH_LAPACK}
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# Pastix 5.2.2.16
if (OCM_USE_PASTIX)
    if(NOT OCM_FORCE_PASTIX)
        FIND_PACKAGE(PASTIX ${PASTIX_VERSION} QUIET)
    endif()
    if(OCM_FORCE_PASTIX OR NOT PASTIX_FOUND)
        ADD_EXTERNAL_PROJECT(PASTIX pastix
            INT_TYPE=${INT_TYPE}
            USE_THREADS=${PASTIX_USE_THREADS}
            USE_METIS=${PASTIX_USE_METIS}
            USE_PTSCOTCH=${PASTIX_USE_PTSCOTCH})
    endif()
endif()

# PETSc 3.5
if (OCM_USE_PETSC)
    if(NOT OCM_FORCE_PETSC)
        FIND_PACKAGE(PETSC ${PETSC_VERSION} QUIET)
    endif()
    if(OCM_FORCE_PETSC OR NOT PETSC_FOUND)
        ADD_EXTERNAL_PROJECT(PETSC petsc
            HYPRE_VERSION=${HYPRE_VERSION}
            MUMPS_VERSION=${MUMPS_VERSION}
            OCM_FORCE_MUMPS=${OCM_FORCE_MUMPS}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            PASTIX_VERSION=${PASTIX_VERSION}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
            SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
            SUNDIALS_VERSION=${SUNDIALS_VERSION}
            SUPERLU_VERSION=${SUPERLU_VERSION}
            SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION})
    endif()
endif()

# SLEPc 3.5
if (OCM_USE_SLEPC)
    if(NOT OCM_FORCE_SLEPC)
        FIND_PACKAGE(SLEPC ${SLEPC_VERSION} QUIET)
    endif()
    if(OCM_FORCE_SLEPC OR NOT SLEPC_FOUND)
        ADD_EXTERNAL_PROJECT(SLEPC slepc
            HYPRE_VERSION=${HYPRE_VERSION}
            MUMPS_VERSION=${MUMPS_VERSION}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            PASTIX_VERSION=${PASTIX_VERSION}
            PETSC_VERSION=${PETSC_VERSION}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
            SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
            SUNDIALS_VERSION=${SUNDIALS_VERSION}
            SUPERLU_VERSION=${SUPERLU_VERSION}
            SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION})
    endif()
endif()

# CellML
if (OCM_USE_LIBCELLML)
    ADD_EXTERNAL_PROJECT(CELLML libcellml)
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