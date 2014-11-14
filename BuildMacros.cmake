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

	# If we are builiding using devenv or msbuild we need to add the name of the solution file to the build and install command
	SET( LOCAL_PLATFORM_BUILD_COMMAND ${PLATFORM_BUILD_COMMAND} )
	SET( LOCAL_PLATFORM_INSTALL_COMMAND ${PLATFORM_INSTALL_COMMAND} )
	IF( GENERATOR_MATCH_VISUAL_STUDIO )
		# Some solution names differ from their project name so we change those here
		SET( SOLUTION_NAME ${PROJECT_NAME} )
		IF( ${PROJECT_NAME} STREQUAL "InsightToolkit" )
			SET( SOLUTION_NAME itk )
		ENDIF()
		LIST(INSERT LOCAL_PLATFORM_BUILD_COMMAND 1 ${SOLUTION_NAME}.sln )
		IF( DEPENDENCIES_DEVENV_EXECUTABLE )
			LIST(INSERT LOCAL_PLATFORM_INSTALL_COMMAND 1 ${SOLUTION_NAME}.sln )
		ENDIF( DEPENDENCIES_DEVENV_EXECUTABLE )			
	ENDIF( GENERATOR_MATCH_VISUAL_STUDIO )
    
    # get current revision ID
    execute_process(COMMAND git submodule status ${MODULE_PATH}
        OUTPUT_VARIABLE RES
        WORKING_DIRECTORY ${OpenCMISS_Dependencies_SOURCE_DIR})
    string(SUBSTRING ${RES} 1 40 REV_ID)

    #message(STATUS "CMAKE ARGS: '${PROJECT_CMAKE_ARGS}'")
    SET(USERMODE_DOWNLOAD_CMDS )
    if (OCM_DEVELOPER_MODE)
        # Retrieve current submodule revision if the submodule has not been
        # initialized, indicated by an "-" as first character of the submodules status string
        # See http://git-scm.com/docs/git-submodule # status
        string(SUBSTRING ${RES} 0 1 SUBMOD_STATUS)
        if (SUBMOD_STATUS STREQUAL -)
            message(STATUS "OpenCMISS Developer mode: Submodule ${MODULE_PATH} not initialized yet. Doing now..")
            execute_process(COMMAND git submodule update --init --recursive ${MODULE_PATH}
                WORKING_DIRECTORY ${OpenCMISS_Dependencies_SOURCE_DIR}
                ERROR_VARIABLE UPDATE_CMD_ERR)
            if (UPDATE_CMD_ERR)
                message(FATAL_ERROR "Error updating submodule '${MODULE_PATH}' (fix manually): ${UPDATE_CMD_ERR}")
            endif()
            # Check out opencmiss branch
            execute_process(COMMAND git checkout opencmiss
                WORKING_DIRECTORY ${OpenCMISS_Dependencies_SOURCE_DIR}/${MODULE_PATH}
                OUTPUT_VARIABLE CHECKOUT_DUMMY_OUTPUT #
                ERROR_VARIABLE CHECKOUT_CMD_ERR)
            #if (CHECKOUT_CMD_ERR)
            #    message(FATAL_ERROR "Error checking out submodule '${MODULE_PATH}' (fix manually): ${CHECKOUT_CMD_ERR}")
            #endif()
        endif()
    else()
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

FUNCTION(PRINT_VARS)
    get_cmake_property(_variableNames VARIABLES)
    foreach (_variableName ${_variableNames})
        message(STATUS "VARDUMP -- ${_variableName}=${${_variableName}}")
    endforeach()
ENDFUNCTION()