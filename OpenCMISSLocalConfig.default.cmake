# ==============================
# Initial setup instructions
# ==============================
#SET(OCM_DEVELOPER_MODE ON)

# ==============================
# Build configuration
# ==============================
# Use architecture information paths
SET(OCM_USE_ARCHITECTURE_PATH NO)

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

#SET(OCM_USE_PLAPACK NO)
#SET(OCM_USE_METIS NO)
#SET(OCM_USE_PARMETIS NO)