# SimvtkFindMATLABRoot.cmake
#
# 1 macro, 0 arguments.
#
# Macro: SIMVTK_FIND_MATLAB_ROOT
#     ARGUMENTS: None
#     OUTPUT: ${MATLAB_ROOT} variable set.

MACRO(SIMVTK_FIND_MATLAB_ROOT)

  IF(WIN32)
    SET(MATLAB_PATH_SEARCH
      "C:/Program Files/MATLAB/R2007a"
      "C:/Program Files/MATLAB/R2007b"
      "C:/Program Files/MATLAB/R2008a"
      "C:/Program Files/MATLAB/R2008b"
      "C:/Program Files/MATLAB/R2009a"
      "C:/Program Files/MATLAB/R2009b"
    )
  ENDIF(WIN32)

  IF(NOT WIN32 AND NOT APPLE)
    SET(MATLAB_PATH_SEARCH
      "/usr/local/matlab74"
      "/usr/local/matlab76"
      "/usr/local/matlab77"
      "/usr/local/matlab78"
      "/usr/local/matlab79"
    )
  ENDIF(NOT WIN32 AND NOT APPLE)

  IF(APPLE)
    SET(MATLAB_PATH_SEARCH
      "/Applications/MATLAB_R2008a"
      "/Applications/MATLAB_R2008b.app"
      "/Applications/MATLAB_R2009a.app"
      "/Applications/MATLAB_R2009b.app"
    )
  ENDIF(APPLE)

  FIND_PATH(MATLAB_ROOT patents.txt
    $ENV{MATLAB_ROOT}
    ${MATLAB_PATH_SEARCH}
    DOC "The directory where MATLAB is installed"
  )

  SET(MATLAB_FOUND 0)
  IF(MATLAB_ROOT)
    IF(EXISTS ${MATLAB_ROOT}/patents.txt)
      SET(MATLAB_FOUND 1)
    ENDIF(EXISTS ${MATLAB_ROOT}/patents.txt)
  ENDIF(MATLAB_ROOT)

  IF(NOT MATLAB_FOUND)
    MESSAGE(FATAL_ERROR "MATLAB not found, please set MATLAB_ROOT")
  ENDIF(NOT MATLAB_FOUND)

ENDMACRO(SIMVTK_FIND_MATLAB_ROOT)
