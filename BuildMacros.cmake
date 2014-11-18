include(OCMUtilsBuildMacros)

MACRO( ADD_EXTERNAL_PROJECT 
    PROJECT_NAME
    SUBMODULE_NAME)
    
    # Until something better comes up
    # Local module name
    SET(MODULE_PATH src/${SUBMODULE_NAME})
    SET(PROJECT_FOLDER ${CMAKE_CURRENT_BINARY_DIR}/${SUBMODULE_NAME})

    # additional args
	SET( PROJECT_CMAKE_ARGS "")
	# As the CMAKE_ARGS are a list themselves, we need to treat the ; in the (possible) list of module_paths
	# specially. Therefore CMAKE has a special command $<SEMICOLON>
	STRING(REPLACE ";" "$<SEMICOLON>" CMAKE_MODULE_PATH_ESC "${CMAKE_MODULE_PATH}")
	LIST(APPEND PROJECT_CMAKE_ARGS
	    -DCMAKE_INSTALL_PREFIX:PATH=${OCM_DEPS_INSTALL_PREFIX}
	    -DCMAKE_BUILD_TYPE:PATH=${CMAKE_BUILD_TYPE}
	    -DBUILD_PRECISION=${BUILD_PRECISION}
	    -DBUILD_TESTS=${BUILD_TESTS}
	    -DCMAKE_PREFIX_PATH=${OCM_DEPS_INSTALL_PREFIX}/lib
	    -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH_ESC}
	)
	# check if MPI compilers should be forwarded/set
	# so that the local FindMPI uses that
	foreach(DEP OCM_DEPS_WITHMPI)
	    if(DEP STREQUAL PROJECT_NAME)
	        foreach(lang C CXX Fortran)
	            if(MPI_${lang}_COMPILER)
	                LIST(APPEND PROJECT_CMAKE_ARGS
	                    -DMPI_${lang}_COMPILER=${MPI_${lang}_COMPILER}
	                )
	            endif()
	        endforeach()
	    endif()
	endforeach()
	# Forward any other variables
    foreach(extra_var ${ARGN})
        #LIST(APPEND PROJECT_CMAKE_ARGS -D${extra_var}=${${extra_var}})
        #message(STATUS "Appending extra definition -D${extra_var}=${${extra_var}}")
        LIST(APPEND PROJECT_CMAKE_ARGS -D${extra_var})
        message(STATUS "${PROJECT_NAME}: Using extra definition -D${extra_var}")
    endforeach()

	GET_BUILD_COMMANDS(LOCAL_PLATFORM_BUILD_COMMAND LOCAL_PLATFORM_INSTALL_COMMAND ${PROJECT_FOLDER})
    GET_SUBMODULE_STATUS(SUBMOD_STATUS REV_ID ${OpenCMISS_Dependencies_SOURCE_DIR} ${MODULE_PATH})

    SET(USERMODE_DOWNLOAD_CMDS )
    # Default: Download the current revision
    if (NOT OCM_DEVELOPER_MODE)
        SET(USERMODE_DOWNLOAD_CMDS URL https://github.com/OpenCMISS-Dependencies/${SUBMODULE_NAME}/archive/${REV_ID}.zip)    
    endif()        
	ExternalProject_Add(${PROJECT_NAME}
		DEPENDS ${${PROJECT_NAME}_DEPS}
		PREFIX ${PROJECT_FOLDER}
		TMP_DIR ${PROJECT_FOLDER}/ep_tmp
		STAMP_DIR ${PROJECT_FOLDER}/ep_stamp
		
		#--Download step--------------
		DOWNLOAD_DIR ${PROJECT_FOLDER}/ep_dl
        ${USERMODE_DOWNLOAD_CMDS}
        
		#--Configure step-------------
		SOURCE_DIR ${OpenCMISS_Dependencies_SOURCE_DIR}/${MODULE_PATH}
		BINARY_DIR ${PROJECT_FOLDER}
		CMAKE_ARGS ${PROJECT_CMAKE_ARGS}
		
		#--Build step-----------------
		BUILD_COMMAND ${LOCAL_PLATFORM_BUILD_COMMAND}
		#--Install step---------------
		INSTALL_COMMAND ${LOCAL_PLATFORM_INSTALL_COMMAND}
	)
	# Add the checkout commands
	if (OCM_DEVELOPER_MODE AND SUBMOD_STATUS STREQUAL -)
        ADD_SUBMODULE_CHECKOUT_STEPS(${PROJECT_NAME} ${OpenCMISS_Dependencies_SOURCE_DIR} ${MODULE_PATH} opencmiss)
    endif()
	
	UNSET( LOCAL_PLATFORM_BUILD_COMMAND )
	UNSET( LOCAL_PLATFORM_INSTALL_COMMAND )
	
	# Add the dependency information for other downstream packages that might use this one
	ADD_DOWNSTREAM_DEPS(${PROJECT_NAME})
    #message(STATUS "Dependencies of ${PROJECT_NAME}: ${${PROJECT_NAME}_DEPS}")
    
ENDMACRO()

MACRO(ADD_DOWNSTREAM_DEPS PACKAGE)
    if (${PACKAGE}_FWD_DEPS)
        #message(STATUS "Package ${PACKAGE} has forward dependencies: ${${PACKAGE}_FWD_DEPS}")
        foreach(FWD_DEP ${${PACKAGE}_FWD_DEPS})
            #message(STATUS "adding ${PACKAGE} to fwd-dep ${FWD_DEP}_DEPS")  
            LIST(APPEND ${FWD_DEP}_DEPS ${PACKAGE})
        endforeach()
    endif()
ENDMACRO()

#[[ #Commmented out
MACRO(EXTRACT_PKG_CONFIG PACKAGE_NAME)
    string(TOUPPER ${PACKAGE_NAME} PACKAGE_NAME_UPPER)
    SET(PKG_LIB ${PACKAGE_NAME_UPPER}_LIBRARIES)
    SET(PKG_INCDIR ${PACKAGE_NAME_UPPER}_INCLUDE_DIRS)
    get_target_property(${PKG_LIB} ${PACKAGE_NAME} LOCATION)
    if (NOT ${PKG_LIB})
        get_target_property(${PKG_LIB} ${PACKAGE_NAME} IMPORTED_LOCATION)
    endif()
    if (NOT ${PKG_LIB})
        get_target_property(${PKG_LIB} ${PACKAGE_NAME} IMPORTED_LOCATION_NOCONFIG)
    endif()
    get_target_property(${PKG_INCDIR} ${PACKAGE_NAME} INCLUDE_DIRECTORIES)
    
    message(STATUS "Extracted package information for ${PACKAGE_NAME}: ${PKG_LIB}=${${PKG_LIB}}, ${PKG_INCDIR}=${${PKG_INCDIR}}")
ENDMACRO()
]]