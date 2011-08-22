# SimvtkGenerateMEXFile.cmake
#
# 1 macro, 1 argument.
#
# Macro: SIMVTK_GENERATE_MEX_FILE
#    ARGUMENT: ${ONE_CLASS}
#        where ${ONE_CLASS} is the name of the class file that will have
#        its S-Function source code compiled into a .mex file.
#    OUTPUT: .mex file (i.e. .mexw32, .mexmaci, etc.) depending on the
#        platform being used.

MACRO(SIMVTK_GENERATE_MEX_FILE ONE_CLASS)

  #In case we were given a path with the class name
  GET_FILENAME_COMPONENT(TMP_CLASS ${ONE_CLASS} NAME_WE)
  GET_FILENAME_COMPONENT(TMP_DIR ${ONE_CLASS} PATH)

  IF("${TMP_DIR}" STREQUAL "")
    SET(TMP_HEADER_DIR ${KIT_HEADER_DIR})
  ELSE("${TMP_DIR}" STREQUAL "")
    SET(TMP_HEADER_DIR ${TMP_DIR})
  ENDIF("${TMP_DIR}" STREQUAL "")

  IF(NOT "${VTK_CLASS_WRAP_EXCLUDE_${TMP_CLASS}}" EQUAL 1)

    IF(NOT "${VTK_CLASS_ABSTRACT_${TMP_CLASS}}" EQUAL 1)

      #Ignore the files that were problems
      LIST(FIND SKIP_CLASSES ${TMP_CLASS} TMP_RESULT)

      IF(${TMP_RESULT} EQUAL -1)

        # SimVTK needs a custom interactor under Mac OS X
        IF(APPLE)
          SET(SIMVTK_EXTRA_SRCS)
          SET(EXTRA_DEPENDS)

          IF("${TMP_CLASS}" STREQUAL "vtkRenderWindow")
            SET(SIMVTK_EXTRA_SRCS
              vtkSimCocoaRenderWindow.mm)
            #SET(EXTRA_DEPENDS "-framework Cocoa")
            IF(VTK_REQUIRED_OBJCXX_FLAGS)
              SET_SOURCE_FILES_PROPERTIES(
                vtkSimCocoaRenderWindow.mm
                PROPERTIES COMPILE_FLAGS "${VTK_REQUIRED_OBJCXX_FLAGS}")
            ENDIF(VTK_REQUIRED_OBJCXX_FLAGS)
          ENDIF("${TMP_CLASS}" STREQUAL "vtkRenderWindow")

          IF("${TMP_CLASS}" STREQUAL "vtkRenderWindowInteractor")
            SET(SIMVTK_EXTRA_SRCS
              vtkSimCocoaNSView.mm
              vtkSimCocoaRenderWindowInteractor.mm)
            #SET(EXTRA_DEPENDS "-framework Cocoa")
            IF(VTK_REQUIRED_OBJCXX_FLAGS)
              SET_SOURCE_FILES_PROPERTIES(
                vtkNSViewWithQueue.mm
                vtkSimCocoaRenderWindowInteractor.mm
                PROPERTIES COMPILE_FLAGS "${VTK_REQUIRED_OBJCXX_FLAGS}")
            ENDIF(VTK_REQUIRED_OBJCXX_FLAGS)
          ENDIF("${TMP_CLASS}" STREQUAL "vtkRenderWindowInteractor")
        ENDIF(APPLE)

        ADD_LIBRARY("Sim${TMP_CLASS}Mat" SHARED
          "${SIMCPP_OUTPUT_DIR}/Sim${TMP_CLASS}Mat.cpp"
          ${SIMVTK_EXTRA_SRCS})
        ADD_DEPENDENCIES("Sim${TMP_CLASS}Mat" ${VTKCPP_TARGETS})

        #This is needed for all MATLAB mex files
        IF(WIN32 AND NOT APPLE)
          SET_TARGET_PROPERTIES("Sim${TMP_CLASS}Mat" PROPERTIES
            LINK_FLAGS "/export:mexFunction")
          IF("${CMAKE_SIZEOF_VOID_P}" GREATER 4)
            SET_TARGET_PROPERTIES("Sim${TMP_CLASS}Mat"
              PROPERTIES PREFIX "" SUFFIX ".mexw64")
          ELSE("${CMAKE_SIZEOF_VOID_P}" GREATER 4)
            SET_TARGET_PROPERTIES("Sim${TMP_CLASS}Mat"
              PROPERTIES PREFIX "" SUFFIX ".mexw32")
          ENDIF("${CMAKE_SIZEOF_VOID_P}" GREATER 4)
        ELSE(WIN32 AND NOT APPLE)
          IF("${CMAKE_SIZEOF_VOID_P}" GREATER 4)
            SET_TARGET_PROPERTIES("Sim${TMP_CLASS}Mat"
              PROPERTIES PREFIX "" SUFFIX ".mexa64")
          ELSE("${CMAKE_SIZEOF_VOID_P}" GREATER 4)
            SET_TARGET_PROPERTIES("Sim${TMP_CLASS}Mat"
              PROPERTIES PREFIX "" SUFFIX ".mexglx")
          ENDIF("${CMAKE_SIZEOF_VOID_P}" GREATER 4)
        ENDIF(WIN32 AND NOT APPLE)

        IF(APPLE)
          IF("${CMAKE_OSX_ARCHITECTURES}" STREQUAL "x86_64")
            SET_TARGET_PROPERTIES("Sim${TMP_CLASS}Mat"
              PROPERTIES PREFIX "" SUFFIX ".mexmaci64")
          ELSE("${CMAKE_OSX_ARCHITECTURES}" STREQUAL "x86_64")
            SET_TARGET_PROPERTIES("Sim${TMP_CLASS}Mat"
              PROPERTIES PREFIX "" SUFFIX ".mexmaci")
          ENDIF("${CMAKE_OSX_ARCHITECTURES}" STREQUAL "x86_64")
        ENDIF(APPLE)

        IF(${CMAKE_PROJECT_NAME} STREQUAL "SIMVTK")
          TARGET_LINK_LIBRARIES("Sim${TMP_CLASS}Mat"
            vtk${KIT_NAME} ${KIT_LIB_DEPENDS}
            ${MATLAB_LIBRARIES})
        ELSE(${CMAKE_PROJECT_NAME} STREQUAL "SIMVTK")
          TARGET_LINK_LIBRARIES("Sim${TMP_CLASS}Mat"
            ${KIT_LIB_DEPENDS}
            ${MATLAB_LIBRARIES})
        ENDIF(${CMAKE_PROJECT_NAME} STREQUAL "SIMVTK")

      ENDIF(${TMP_RESULT} EQUAL -1)

    ENDIF(NOT "${VTK_CLASS_ABSTRACT_${TMP_CLASS}}" EQUAL 1)

  ENDIF(NOT "${VTK_CLASS_WRAP_EXCLUDE_${TMP_CLASS}}" EQUAL 1)
ENDMACRO(SIMVTK_GENERATE_MEX_FILE)
