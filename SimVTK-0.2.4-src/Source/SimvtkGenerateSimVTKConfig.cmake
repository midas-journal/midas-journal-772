# Generate the SimVTKConfig.cmake file in the build tree.  Also configure
# one for installation.  The file tells external projects how to use
# SimVTK.

SET(SIMVTK_USE_FILE ${SIMVTK_BINARY_DIR}/UseSimVTK.cmake)

# Configure UseSimVTK.cmake for use for third-party files
CONFIGURE_FILE(${SIMVTK_SOURCE_DIR}/UseSimVTK.cmake.in
               ${SIMVTK_BINARY_DIR}/UseSimVTK.cmake @ONLY IMMEDIATE)

CONFIGURE_FILE(${SIMVTK_SOURCE_DIR}/SimvtkConfig.cmake.in
               ${SIMVTK_BINARY_DIR}/SimvtkConfig.cmake @ONLY IMMEDIATE)
