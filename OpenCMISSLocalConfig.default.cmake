# ==============================
# Initial setup instructions
# ==============================
SET(OCM_DEVELOPER_MODE ON)

# ==============================
# Build configuration
# ==============================
# Use architecture information paths
SET(OCM_USE_ARCHITECTURE_PATH NO)

# Precision to build (if applicable)
# Valid choices are s,d,c,z and any combinations.
# s: Single / float precision
# d: Double precision
# c: Complex / float precision
# z: Complex / double precision
SET(BUILD_PRECISION d)

# Also build tests?
SET(BUILD_TESTS ON)

# ==============================
# Customisation of dependencies
# ==============================
# Planned: For inclusion of external, custom libraries you'd go like  
#SET(<PROJECT>_LIBRARIES )
#SET(<PROJECT>BLAS_INCLUDE_DIRS )
# A script/macro that automatically turns module packages to config packages is still required.

# Force to use all OpenCMISS dependencies - long compilation, but will work
SET(FORCE_OCM_ALLDEPS NO)

# To enforce use of the shipped package, set OCM_FORCE_<PACKAGE>=YES e.g.
#  SET(OCM_FORCE_BLAS YES)
# for BLAS libraries.

# Choose here which optional dependencies/packages will be built by cmake.
# The default is to build all

#SET(OCM_USE_LAPACK YES)
#SET(OCM_USE_SCALAPACK YES)
#SET(OCM_USE_MUMPS YES)
#SET(OCM_USE_METIS YES)
#SET(OCM_USE_PLAPACK YES)
#SET(OCM_USE_PTSCOTCH YES)
#SET(OCM_USE_SUITESPARSE YES)
#SET(OCM_USE_SUNDIALS YES)
#SET(OCM_USE_SUPERLU YES)
#SET(OCM_USE_SUPERLU_DIST YES)
#SET(OCM_USE_PARMETIS YES)
SET(OCM_USE_PASTIX NO)
SET(OCM_USE_HYPRE NO)

# ==============================
# Single module configuration
# ==============================
SET(MUMPS_WITH_METIS YES)
SET(MUMPS_WITH_PARMETIS NO)

SET(SUNDIALS_WITH_LAPACK YES)

SET(SCOTCH_USE_PTHREAD YES)
SET(SCOTCH_USE_GZ YES)

SET(SUITESPARSE_WITH_CHOLMOD YES)
SET(SUITESPARSE_WITH_UMFPACK YES)

SET(SUPERLU_DIST_WITH_PARMETIS NO)
SET(SUPERLU_DIST_WITH_METIS YES)