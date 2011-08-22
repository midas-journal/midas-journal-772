PROJECT(SIMVTK)

# CMake version requirements
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

# Look for a VTK build directory
FIND_PACKAGE(VTK)
IF (VTK_FOUND)
  INCLUDE (${VTK_USE_FILE})
ENDIF (VTK_FOUND)

#-----------------------------------------------------------------------------
# Output directories.
IF(NOT LIBRARY_OUTPUT_PATH)
  SET(LIBRARY_OUTPUT_PATH ${SIMVTK_BINARY_DIR}/bin CACHE INTERNAL
    "Single output directory for building all libraries.")
ENDIF(NOT LIBRARY_OUTPUT_PATH)
IF(NOT EXECUTABLE_OUTPUT_PATH)
  SET(EXECUTABLE_OUTPUT_PATH ${SIMVTK_BINARY_DIR}/bin CACHE INTERNAL
    "Single output directory for building all executables.")
ENDIF(NOT EXECUTABLE_OUTPUT_PATH)

# Include the config type
SET(SIMVTK_LIBRARY_DIR ${LIBRARY_OUTPUT_PATH}/${CMAKE_CFG_INTDIR})
SET(SIMVTK_EXECUTABLE_DIR ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_CFG_INTDIR})

INCLUDE(SimvtkGenerateSimVTKConfig.cmake)

# XML and CPP output directories
SET(VTKXML_OUTPUT_DIR ${SIMVTK_BINARY_DIR}/vtkXML)
SET(SIMCPP_OUTPUT_DIR ${SIMVTK_BINARY_DIR}/vtkXML)

#-----------------------------------------------------------------------------

# The vtkXML executable
SUBDIRS(vtkXML)

# Get the full path to the vtkXML
SET(VTKXML_EXE ${SIMVTK_EXECUTABLE_DIR}/vtkXML)

# Get the hints file, set as an advanced option
FIND_FILE(VTKXML_HINTS xmlhints ${SIMVTK_SOURCE_DIR}/vtkXML
      NO_CMAKE_FIND_ROOT_PATH)
MARK_AS_ADVANCED(VTKXML_HINTS)

#-----------------------------------------------------------------------------
# Current list of classes that were not able to compile properly
# due to various problems that will soon be fixed
# NOTICE: vtkMatrix4x4 is on here permanently since we will use our
# own hand made one
SET(SKIP_CLASSES
vtkgl
vtkCocoaGLView
vtkWidgetEvent
vtkOpenGLRenderer
vtkOpenGLFreeTypeTextMapper
vtkTextMapper
vtkSQLiteDatabase
vtkSQLDatabaseGraphSource
vtkSQLDatabaseTableSource
vtkSQLGraphReader
vtkSQLDatabaseSchema
vtkSQLiteQueryMat
vtkMatrix4x4
)

#-----------------------------------------------------------------------------

# Copy slblocks.m and SimVTK.mdl to the build/bin directory
# for integration with the Simulink Library Browser.

CONFIGURE_FILE(
  "${SIMVTK_SOURCE_DIR}/slblocks.m"
  "${SIMVTK_BINARY_DIR}/bin/slblocks.m"
  COPYONLY
)

CONFIGURE_FILE(
  "${SIMVTK_SOURCE_DIR}/SimVTK.mdl"
  "${SIMVTK_BINARY_DIR}/bin/SimVTK.mdl"
  COPYONLY
)

#-----------------------------------------------------------------------------

# Include the contents of all the kit .cmake files.
# This provides a list of the classes included in VTK.
INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/vtkIncludeAllKits.cmake")

# Include macro to generate XML from class name.
INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateXMLFile.cmake")

# This will be a list of targets for all the XML files
SET(VTKXML_TARGETS)

FOREACH(VTK_KIT ${VTK_KITS})

  SET(KIT_NAME "${VTK_${VTK_KIT}_NAME}")
  SET(KIT_HEADER_DIR "${VTK_${VTK_KIT}_HEADER_DIR}")
  SET(KIT_CLASSES "${VTK_${VTK_KIT}_CLASSES}")

  # To store a list of all xml files
  SET(TMP_XML_FILES)

  FOREACH(ONE_CLASS ${KIT_CLASSES})

    # Call to XML Generation Macro
    SIMVTK_GENERATE_XML_FILE(${ONE_CLASS})

  ENDFOREACH(ONE_CLASS ${KIT_CLASSES})

  # Add a custom target for the kit XML
  ADD_CUSTOM_TARGET(vtk${KIT_NAME}XML DEPENDS ${TMP_XML_FILES})
  SET(VTKXML_TARGETS ${VTKXML_TARGETS} vtk${KIT_NAME}XML)

ENDFOREACH(VTK_KIT ${VTK_KITS})

# Add a custom target for all vtkXML outputs
ADD_CUSTOM_TARGET(vtkAllKitsXML ALL)
ADD_DEPENDENCIES(vtkAllKitsXML ${VTKXML_TARGETS})

#-----------------------------------------------------------------------------
# Disable deprecation warnings for standard C and STL functions
# in VS2005 and later
IF(CMAKE_COMPILER_2005)
  ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE)
  ADD_DEFINITIONS(-D_SCL_SECURE_NO_DEPRECATE)
ENDIF(CMAKE_COMPILER_2005)

# Find the Perl libraries so we can generate code using perl scripts
FIND_PACKAGE(Perl)

#-----------------------------------------------------------------------------
# Look for MATLAB and define useful variables

INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkFindMATLABRoot.cmake")
INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkFindMATLABLibraries.cmake")

SIMVTK_FIND_MATLAB_ROOT()

SIMVTK_FIND_MATLAB_LIBRARIES()

#-----------------------------------------------------------------------------
# Set other include directories (especially your own)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})

# Set any extra source files (if any) needed for the dlls
#SET(SIMVTK_EXTRA_SRCS)

# List of classes to replace with a customized S-Function.
# The vtkMatrix4x4 should be moved here
SET(CUSTOM_CLASSES
vtkColorTransferFunction
vtkPiecewiseFunction
)

#----------------------------------------------------------------------
# Create the source code for all S-Functions

# Include file for the S-Function Source Generation macro
INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateSFunctionFile.cmake")

# This will be a list of targets for all the cpp files
SET(VTKCPP_TARGETS)

# Sets the XML file and perl scripts to be used
  SET(PERL_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/vtkBlockGenerator.pl")
  SET(PERL_LIB_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/vtkLibraryGen.pl")

FOREACH(VTK_KIT ${VTK_KITS})
  SET(KIT_NAME "${VTK_${VTK_KIT}_NAME}")
  SET(KIT_HEADER_DIR "${VTK_${VTK_KIT}_HEADER_DIR}")
  SET(KIT_CLASSES "${VTK_${VTK_KIT}_CLASSES}")

  SET(CLASS_COUNTER 0)

  # To store a list of all cpp files for this Kit
  SET(TMP_CPP_FILES)

  # Store the ITKImageImport File first (if is in imaging)
  IF("${KIT_NAME}" STREQUAL "Imaging")
    ADD_CUSTOM_COMMAND(
      OUTPUT ${SIMCPP_OUTPUT_DIR}/SimvtkITKImageImportMat.cpp
      COMMAND ${CMAKE_COMMAND}
      # Make sure perl has access to modules in the source directory
      ARGS "-E" "copy" "${CMAKE_CURRENT_SOURCE_DIR}/SimvtkITKImageImportMat.cpp"
      "${SIMCPP_OUTPUT_DIR}/SimvtkITKImageImportMat.cpp"
      COMMENT "Copying over SimvtkITKImageImportMat.cpp"
      )
    SET(TMP_CPP_FILES ${TMP_CPP_FILES}
      "${SIMCPP_OUTPUT_DIR}/SimvtkITKImageImportMat.cpp")
    SET(CLASS_COUNTER 1)
  ENDIF("${KIT_NAME}" STREQUAL "Imaging")

  # Store the Matrix4x4FromMatlabMatrix File first (if is in common)
  IF("${KIT_NAME}" STREQUAL "Common")
    ADD_CUSTOM_COMMAND(
      OUTPUT ${SIMCPP_OUTPUT_DIR}/SimvtkMatrix4x4FromMatlabMatrixMat.cpp
      COMMAND ${CMAKE_COMMAND}
      # Make sure perl has access to modules in the source directory
      ARGS "-E" "copy" "${CMAKE_CURRENT_SOURCE_DIR}/SimvtkMatrix4x4FromMatlabMatrixMat.cpp"
      "${SIMCPP_OUTPUT_DIR}/SimvtkMatrix4x4FromMatlabMatrixMat.cpp"
      COMMENT "Copying over SimvtkMatrix4x4FromMatlabMatrixMat.cpp"
      )
    SET(TMP_CPP_FILES ${TMP_CPP_FILES}
      "${SIMCPP_OUTPUT_DIR}/SimvtkMatrix4x4FromMatlabMatrixMat.cpp")
    SET(CLASS_COUNTER 1)
  ENDIF("${KIT_NAME}" STREQUAL "Common")

  # Special classes from Filtering
  IF("${KIT_NAME}" STREQUAL "Filtering")
    ADD_CUSTOM_COMMAND(
      OUTPUT ${SIMCPP_OUTPUT_DIR}/SimvtkColorTransferFunctionMat.cpp
      COMMAND ${CMAKE_COMMAND}
      # Make sure perl has access to modules in the source directory
      ARGS "-E" "copy" "${CMAKE_CURRENT_SOURCE_DIR}/SimvtkColorTransferFunctionMat.cpp"
      "${SIMCPP_OUTPUT_DIR}/SimvtkColorTransferFunctionMat.cpp"
      COMMENT "Copying over SimvtkColorTransferFunctionMat.cpp"
      )
    ADD_CUSTOM_COMMAND(
      OUTPUT ${SIMCPP_OUTPUT_DIR}/SimvtkPiecewiseFunctionMat.cpp
      COMMAND ${CMAKE_COMMAND}
      # Make sure perl has access to modules in the source directory
      ARGS "-E" "copy" "${CMAKE_CURRENT_SOURCE_DIR}/SimvtkPiecewiseFunctionMat.cpp"
      "${SIMCPP_OUTPUT_DIR}/SimvtkPiecewiseFunctionMat.cpp"
      COMMENT "Copying over SimvtkPiecewiseFunctionMat.cpp"
      )
    SET(TMP_CPP_FILES ${TMP_CPP_FILES}
      "${SIMCPP_OUTPUT_DIR}/SimvtkColorTransferFunctionMat.cpp"
      "${SIMCPP_OUTPUT_DIR}/SimvtkPiecewiseFunctionMat.cpp")
    SET(CLASS_COUNTER 2)
  ENDIF("${KIT_NAME}" STREQUAL "Filtering")

  FOREACH(ONE_CLASS ${KIT_CLASSES})

    # Call to the S-Function Source Generation macro
    SIMVTK_GENERATE_SFUNCTION_FILE(${ONE_CLASS})

  ENDFOREACH(ONE_CLASS ${KIT_CLASSES})

  # Add a custom target for the kit cpp
  ADD_CUSTOM_TARGET(vtk${KIT_NAME}CPP DEPENDS ${TMP_CPP_FILES})
  ADD_DEPENDENCIES(vtk${KIT_NAME}CPP vtkAllKitsXML)
  SET(VTKCPP_TARGETS ${VTKCPP_TARGETS} vtk${KIT_NAME}CPP)

ENDFOREACH(VTK_KIT ${VTK_KITS})

# Add a custom target for all vtkCPP outputs
ADD_CUSTOM_TARGET(vtkAllKitsCPP ALL)
ADD_DEPENDENCIES(vtkAllKitsCPP ${VTKCPP_TARGETS})

#-----------------------------------------------------------------------------
#Include the Library Generating macro
INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateLibraryFile.cmake")

# This will be a list of targets for all the cpp files
SET(VTKMDL_TARGETS)

FOREACH(VTK_KIT ${VTK_KITS})

  SET(KIT_NAME "${VTK_${VTK_KIT}_NAME}")
  SET(KIT_HEADER_DIR "${VTK_${VTK_KIT}_HEADER_DIR}")
  SET(KIT_CLASSES "${VTK_${VTK_KIT}_CLASSES}")

  SIMVTK_GENERATE_LIBRARY_FILE(${VTK_KIT})

ENDFOREACH(VTK_KIT ${VTK_KITS})

# Add a custom target for all vtkMDL outputs
ADD_CUSTOM_TARGET(vtkAllKitsMDL ALL)
ADD_DEPENDENCIES(vtkAllKitsMDL ${VTKMDL_TARGETS})

#-----------------------------------------------------------------------------
# compile the S-Functions

# Include for the MEX-Generating macro
INCLUDE("${SIMVTK_SOURCE_DIR}/CMake/SimvtkGenerateMEXFile.cmake")

 FOREACH(VTK_KIT ${VTK_KITS})

  SET(KIT_NAME "${VTK_${VTK_KIT}_NAME}")
  SET(KIT_HEADER_DIR "${VTK_${VTK_KIT}_HEADER_DIR}")
  SET(KIT_CLASSES "${VTK_${VTK_KIT}_CLASSES}")
  SET(KIT_LIB_DEPENDS "${vtk${KIT_NAME}_LIB_DEPENDS}")

  IF(KIT_NAME STREQUAL "Imaging")
    SET(KIT_CLASSES ${KIT_CLASSES} vtkITKImageImport)
  ENDIF(KIT_NAME STREQUAL "Imaging")

  IF(KIT_NAME STREQUAL "Common")
    SET(KIT_CLASSES ${KIT_CLASSES} vtkMatrix4x4FromMatlabMatrix)
  ENDIF(KIT_NAME STREQUAL "Common")

  FOREACH(ONE_CLASS ${KIT_CLASSES})

    # Call to the MEX-Generating Macro
    SIMVTK_GENERATE_MEX_FILE(${ONE_CLASS})

  ENDFOREACH(ONE_CLASS ${KIT_CLASSES})

ENDFOREACH(VTK_KIT ${VTK_KITS})
