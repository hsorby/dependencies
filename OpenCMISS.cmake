# OpenCMISS Dependencies main configuration file
#
# DO NOT EDIT.
# Use the OpenCMISSLocalConfig.default.cmake file and copy it to OpenCMISSLocalConfig.cmake and do changes there.
# If not copied manually, the defaults will be copied as-is.
include(BuildMacros)

if (NOT CMAKE_BUILD_TYPE AND NOT WIN32)
    SET(CMAKE_BUILD_TYPE RELEASE)
    message(STATUS "No CMAKE_BUILD_TYPE has been defined. Using RELEASE.")
endif()

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
    SUNDIALS SUPERLU_DIST SLEPC)

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
if (NOT EXISTS ${CMAKE_CURRENT_LIST_DIR}/OpenCMISSLocalConfig.cmake)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/OpenCMISSLocalConfig.default.cmake ${CMAKE_CURRENT_LIST_DIR}/OpenCMISSLocalConfig.cmake COPYONLY)
endif()
include(OpenCMISSLocalConfig)

# Add the utilities module path as well
LIST(APPEND CMAKE_MODULE_PATH ${OCM_UTILITIES_DIR}/cmake_modules)

# ================================
# The installation path for all locally build dependencies
# ================================
SET(INSTALL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/install)
if(OCM_USE_ARCHITECTURE_PATH)
    # Architecture
    include(TargetArch)
    target_architecture(ARCH)
    SET(INSTALL_DIR ${INSTALL_DIR}/${ARCH})
    
    # Compiler information
    if(MPI_C_COMPILER OR MPI_Fortran_COMPILER)
        get_filename_component(C_COMP_NAME ${MPI_C_COMPILER} NAME)
        get_filename_component(F_COMP_NAME ${MPI_Fortran_COMPILER} NAME)
    else()
        get_filename_component(C_COMP_NAME ${CMAKE_C_COMPILER} NAME)
        get_filename_component(F_COMP_NAME ${CMAKE_Fortran_COMPILER} NAME)
    endif()
    SET(INSTALL_DIR ${INSTALL_DIR}/${C_COMP_NAME}_${F_COMP_NAME})
endif()

if (NOT WIN32)
    STRING(TOLOWER ${CMAKE_BUILD_TYPE} buildtype)
    SET(UNIXBUILDTYPEEXTRA "/${buildtype}")
else()
    # The multiconfig generators for VS ignore the CMAKE_BUILD_TYPE and hence would cause trouble if
    # any paths would've been deduced from that.
    SET(UNIXBUILDTYPEEXTRA "")
endif()
SET(OCM_DEPS_INSTALL_PREFIX ${INSTALL_DIR}${UNIXBUILDTYPEEXTRA})
message(STATUS "OpenCMISS dependencies will be installed to ${OCM_DEPS_INSTALL_PREFIX}")

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
    if (${OCM_DEP}_FWD_DEPS)
        foreach(FWD_DEP ${${OCM_DEP}_FWD_DEPS})
            if(OCM_USE_${FWD_DEP} AND NOT OCM_USE_${OCM_DEP})
                message(STATUS "Package ${FWD_DEP} requires ${OCM_DEP}, setting OCM_USE_${OCM_DEP}=ON")
                set(OCM_USE_${OCM_DEP} ON)
            endif() 
        endforeach()
    endif()
    
    message(STATUS "Package ${OCM_DEP}: Build: ${OCM_USE_${OCM_DEP}}, Custom ${${OCM_DEP}_CUSTOM}, OCM forced: ${OCM_FORCE_${OCM_DEP}}")
ENDFOREACH()