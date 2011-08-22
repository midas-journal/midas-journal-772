SET(${CMAKE_PROJECT_NAME}_WRAP_FOR_SIMVTK ${WRAP_FOR_SIMVTK})

MACRO(WRAP_FOR_SIMVTK LIBRARY_NAME)

  IF (${CMAKE_PROJECT_NAME}_WRAP_FOR_SIMVTK)

    INCLUDE_DIRECTORIES(${SIMVTK_SOURCE_DIR} ${SIMVTK_BINARY_DIR})

    #----------------------------------------------------------------------
    # Get the full path to the vtkXML

    FILE(MAKE_DIRECTORY "${${CMAKE_PROJECT_NAME}_BINARY_DIR}/vtkXML")

    # TODO: Only copy XML files.
    FILE(COPY ${SIMVTK_BINARY_DIR}/vtkXML
      DESTINATION ${${CMAKE_PROJECT_NAME}_BINARY_DIR}
    )

    # XML and CPP output directories
    SET(VTKXML_OUTPUT_DIR "${${CMAKE_PROJECT_NAME}_BINARY_DIR}/vtkXML")
    SET(SIMCPP_OUTPUT_DIR "${${CMAKE_PROJECT_NAME}_BINARY_DIR}/bin")

    FIND_FILE(VTKXML_HINTS xmlhints ${SIMVTK_SOURCE_DIR}/vtkXML
      NO_CMAKE_FIND_ROOT_PATH)
    MARK_AS_ADVANCED(VTKXML_HINTS)

    #----------------------------------------------------------------------
    # IMPLEMENT slblocks.m and SimVTK${CMAKE_PROJECT_NAME}Library.mdl here?
    #----------------------------------------------------------------------

    # Declare variables to be used throughout macro calls

      SET(KIT_NAME "${LIBRARY_NAME}")
      SET(KIT_HEADER_DIR "${${KIT_NAME}_HEADER_DIR}")
      SET(KIT_CLASSES "${${KIT_NAME}_CLASSES}")
      SET(KIT_LIB_DEPENDS "${${KIT_NAME}_LIB_DEPENDS}")

    # Include macro to generate XML from class name.
    INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateXMLFile.cmake")

    # This will be a list of targets for all the XML files
    SET(VTKXML_TARGETS)

    # To store a list of all xml files
    SET(TMP_XML_FILES)

    FOREACH(ONE_CLASS ${KIT_CLASSES})

      # Call to XML Generation Macro
      SIMVTK_GENERATE_XML_FILE(${ONE_CLASS})

    ENDFOREACH(ONE_CLASS ${KIT_CLASSES})

    # Add a custom target for the kit XML
    ADD_CUSTOM_TARGET("${KIT_NAME}XML" DEPENDS ${TMP_XML_FILES})
    SET(VTKXML_TARGETS ${VTKXML_TARGETS} "${KIT_NAME}XML")

    # Add a custom target for all vtkXML outputs
    ADD_CUSTOM_TARGET(All${KIT_NAME}XML ALL)
    ADD_DEPENDENCIES(All${KIT_NAME}XML ${VTKXML_TARGETS})

    #----------------------------------------------------------------------

    # Find the Perl libraries so we can generate code using perl scripts
    FIND_PACKAGE(Perl)

    #----------------------------------------------------------------------
    # Look for MATLAB and define useful variables

    INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkFindMATLABRoot.cmake")
    INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkFindMATLABLibraries.cmake")

    SIMVTK_FIND_MATLAB_ROOT()

    SIMVTK_FIND_MATLAB_LIBRARIES()

    #----------------------------------------------------------------------
    # Set other include directories (especially your own)
    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})

    #----------------------------------------------------------------------
    # Create the source code for all S-Functions

    # Include file for the S-Function Source Generation macro
    INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateSFunctionFile.cmake")

    # This will be a list of targets for all the cpp files
    SET(VTKCPP_TARGETS)

    # Sets the XML file and perl scripts to be used
    SET(PERL_SCRIPT "${SIMVTK_SOURCE_DIR}/vtkBlockGenerator.pl")
    SET(PERL_LIB_SCRIPT "${SIMVTK_SOURCE_DIR}/vtkLibraryGen.pl")

    SET(CLASS_COUNTER 0)

    # To store a list of all cpp files for this Kit
    SET(TMP_CPP_FILES)

    FOREACH(ONE_CLASS ${KIT_CLASSES})

      # Call to the S-Function Source Generation macro
      SIMVTK_GENERATE_SFUNCTION_FILE(${ONE_CLASS})

    ENDFOREACH(ONE_CLASS ${KIT_CLASSES})

    # Add a custom target for the kit cpp
    ADD_CUSTOM_TARGET("${KIT_NAME}CPP" DEPENDS ${TMP_CPP_FILES})
    ADD_DEPENDENCIES("${KIT_NAME}CPP" All${KIT_NAME}XML)
    SET(VTKCPP_TARGETS ${VTKCPP_TARGETS} "${KIT_NAME}CPP")

    # Add a custom target for all vtkCPP outputs
    ADD_CUSTOM_TARGET(All${KIT_NAME}CPP ALL)
    ADD_DEPENDENCIES(All${KIT_NAME}CPP ${VTKCPP_TARGETS})

    #-----------------------------------------------------------------------

    #Include the Library Generating macro
    INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateLibraryFile.cmake")

    # This will be a list of targets for all the cpp files
    SET(VTKMDL_TARGETS)

    SIMVTK_GENERATE_LIBRARY_FILE(${KIT_NAME})

    # Add a custom target for all vtkMDL outputs
    ADD_CUSTOM_TARGET(All${KIT_NAME}MDL ALL)
    ADD_DEPENDENCIES(All${KIT_NAME}MDL ${VTKMDL_TARGETS})

    #----------------------------------------------------------------------
    # compile the S-Functions

    # Include for the MEX-Generating macro
    INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateMEXFile.cmake")

    FOREACH(ONE_CLASS ${KIT_CLASSES})

      # Call to the MEX-Generating Macro
      SIMVTK_GENERATE_MEX_FILE(${ONE_CLASS})

    ENDFOREACH(ONE_CLASS ${KIT_CLASSES})

  ENDIF (${CMAKE_PROJECT_NAME}_WRAP_FOR_SIMVTK)

ENDMACRO(WRAP_FOR_SIMVTK LIBRARY_NAME)
