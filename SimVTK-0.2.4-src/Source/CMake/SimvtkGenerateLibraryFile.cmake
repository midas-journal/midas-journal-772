# SimvtkGenerateLibraryFile.cmake
#
# 1 macro, 1 argument.
#
# Macro: SIMVTK_GENERATE_LIBRARY_FILE
#    ARGUMENT: ${VTK_KIT}
#      where ${VTK_KIT} is the name of the VTK Kit file being referenced
#      (i.e. vtkImagingKit). Library file will be created using Kit name.
#    OUTPUT: Simvtk${KIT_NAME}Library.mdl
#      where Simvtk${KIT_NAME}Library.mdl will be a library file containing
#      all the functions associated with that kit.

MACRO(SIMVTK_GENERATE_LIBRARY_FILE VTK_KIT)

  # Make sure perl has access to the modules in the source directory

  ADD_CUSTOM_COMMAND(
    OUTPUT ${LIBRARY_OUTPUT_PATH}/Simvtk${KIT_NAME}Library.mdl
    DEPENDS ${PERL_LIB_SCRIPT}
    COMMAND ${PERL_EXECUTABLE}
    ARGS "-I" ${SIMVTK_SOURCE_DIR} ${PERL_LIB_SCRIPT} ${KIT_NAME} ${SIMCPP_OUTPUT_DIR}
    ${SIMVTK_SOURCE_DIR} ${LIBRARY_OUTPUT_PATH} "\"${KIT_CLASSES}\""
    COMMAND ${CMAKE_COMMAND}
    ARGS "-E" "remove"
         "${LIBRARY_OUTPUT_PATH}/Simvtk${KIT_NAME}LibraryPosition.in"
         "${LIBRARY_OUTPUT_PATH}/Simvtk${KIT_NAME}LibraryTemp.mdl"
    COMMENT "Finalizing library - ${VTK_KIT}"
  )

  SET(TMP_MDL_FILE ${LIBRARY_OUTPUT_PATH}/Simvtk${KIT_NAME}Library.mdl)

  IF(${CMAKE_PROJECT_NAME} STREQUAL "SIMVTK")
    ADD_CUSTOM_TARGET(vtk${KIT_NAME}MDL DEPENDS ${TMP_MDL_FILE})
    ADD_DEPENDENCIES(vtk${KIT_NAME}MDL vtkAllKitsCPP)
    SET(VTKMDL_TARGETS ${VTKMDL_TARGETS} vtk${KIT_NAME}MDL)
  ELSE(${CMAKE_PROJECT_NAME} STREQUAL "SIMVTK")
    ADD_CUSTOM_TARGET(${KIT_NAME}MDL DEPENDS ${TMP_MDL_FILE})
    ADD_DEPENDENCIES(${KIT_NAME}MDL All${KIT_NAME}CPP)
    SET(VTKMDL_TARGETS ${VTKMDL_TARGETS} ${KIT_NAME}MDL)
  ENDIF(${CMAKE_PROJECT_NAME} STREQUAL "SIMVTK")

ENDMACRO(SIMVTK_GENERATE_LIBRARY_FILE)
