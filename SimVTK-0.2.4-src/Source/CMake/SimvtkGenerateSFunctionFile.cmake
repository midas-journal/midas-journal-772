# SimvtkGenerateSFunctionFile.cmake
#
# 1 macro, 1 argument.
#
# Macro: SIMVTK_GENERATE_SFUNCTION_FILE
#    ARGUMENT: ${ONE_CLASS}
#        where ${ONE_CLASS} is the name of the class XML file
#        to be used to create the corresponding S-Function source
#        code.
#    OUTPUT: Sim${ONE_CLASS}Mat.cpp S-Function file.
#
# NOTE: There is one current exception, vtkVolumeProperty, that
# has been pre-built and is just being copied for the time being.

MACRO(SIMVTK_GENERATE_SFUNCTION_FILE ONE_CLASS)

  # In case we were given a path with the class name
  GET_FILENAME_COMPONENT(TMP_CLASS ${ONE_CLASS} NAME_WE)
  GET_FILENAME_COMPONENT(TMP_DIR ${ONE_CLASS} PATH)

  IF("${TMP_DIR}" STREQUAL "")
    SET(TMP_HEADER_DIR ${KIT_HEADER_DIR})
  ELSE("${TMP_DIR}" STREQUAL "")
    SET(TMP_HEADER_DIR ${TMP_DIR})
  ENDIF("${TMP_DIR}" STREQUAL "")

  IF(NOT "${VTK_CLASS_WRAP_EXCLUDE_${TMP_CLASS}}" EQUAL 1)
    IF(NOT "${VTK_CLASS_ABSTRACT_${TMP_CLASS}}" EQUAL 1)

      # Make sure class is not in SKIP_CLASSES or CUSTOM_CLASSES
      LIST(FIND SKIP_CLASSES ${TMP_CLASS} RESULT)

      IF (${RESULT} EQUAL -1)
        LIST(FIND CUSTOM_CLASSES ${TMP_CLASS} RESULT)
      ENDIF (${RESULT} EQUAL -1)

      IF (${RESULT} EQUAL -1)
        SET(TMP_INPUT "${VTKXML_OUTPUT_DIR}/${TMP_CLASS}.xml")

        # This special case for vtkVolumeProperty is temporary...
        IF (${TMP_CLASS} STREQUAL "vtkVolumeProperty")
          # add custom command to output
          ADD_CUSTOM_COMMAND(
            OUTPUT ${SIMCPP_OUTPUT_DIR}/Sim${TMP_CLASS}Mat.cpp
            DEPENDS ${TMP_INPUT} ${PERL_SCRIPT}
            COMMAND ${PERL_EXECUTABLE}
            # Make sure perl has access to modules in the source directory
            ARGS "-I" ${CMAKE_CURRENT_SOURCE_DIR} ${PERL_SCRIPT}
              "-GENERATE" ${TMP_INPUT} ${LIBRARY_OUTPUT_PATH}
              ${SIMCPP_OUTPUT_DIR} ${KIT_NAME} ${VTKXML_OUTPUT_DIR}
              ${CMAKE_CURRENT_SOURCE_DIR} ${CLASS_COUNTER}
            COMMAND ${CMAKE_COMMAND}
            ARGS "-E" "copy" "${CMAKE_CURRENT_SOURCE_DIR}/Sim${TMP_CLASS}Mat.cpp"
            "${SIMCPP_OUTPUT_DIR}/Sim${TMP_CLASS}Mat.cpp"
            COMMENT "Special Temporary Exception - ${TMP_CLASS}"
            )
        ELSE (${TMP_CLASS} STREQUAL "vtkVolumeProperty")
          # add custom command to output
          ADD_CUSTOM_COMMAND(
            OUTPUT ${SIMCPP_OUTPUT_DIR}/Sim${TMP_CLASS}Mat.cpp
            DEPENDS ${TMP_INPUT} ${PERL_SCRIPT}
            COMMAND ${PERL_EXECUTABLE}
            # Make sure perl has access to modules in the source directory
            ARGS "-I" ${SIMVTK_SOURCE_DIR} ${PERL_SCRIPT}
                "-GENERATE" ${TMP_INPUT} ${LIBRARY_OUTPUT_PATH}
                ${SIMCPP_OUTPUT_DIR} ${KIT_NAME} ${VTKXML_OUTPUT_DIR}
                ${SIMVTK_SOURCE_DIR} ${CLASS_COUNTER}
            COMMENT "Building S-Function and Callbacks - ${TMP_CLASS}"
            )
        ENDIF (${TMP_CLASS} STREQUAL "vtkVolumeProperty")

        SET(TMP_CPP_FILES ${TMP_CPP_FILES}
          ${SIMCPP_OUTPUT_DIR}/Sim${TMP_CLASS}Mat.cpp)

        # add 1 to the counter
        MATH(EXPR CLASS_COUNTER ${CLASS_COUNTER}+1 )

      ENDIF(${RESULT} EQUAL -1)

    ENDIF(NOT "${VTK_CLASS_ABSTRACT_${TMP_CLASS}}" EQUAL 1)

  ENDIF(NOT "${VTK_CLASS_WRAP_EXCLUDE_${TMP_CLASS}}" EQUAL 1)

ENDMACRO(SIMVTK_GENERATE_SFUNCTION_FILE)
