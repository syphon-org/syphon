# - Find sqlite3
# Find the native OLM headers and libraries.
#
# OLM_INCLUDE_DIRS	- where to find sqlite3.h, etc.
# OLM_LIBRARIES	- List of libraries when using sqlite.
# OLM_FOUND	- True if sqlite found.

# Look for the library.
FIND_LIBRARY(OLM_LIBRARY NAMES olm)

# Handle the QUIETLY and REQUIRED arguments and set OLM_FOUND to TRUE if all listed variables are TRUE.
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(OLM DEFAULT_MSG OLM_LIBRARY)

# Copy the results to the output variables.
IF(OLM_FOUND)
	SET(OLM_LIBRARIES ${OLM_LIBRARY})
	SET(OLM_INCLUDE_DIRS ${OLM_INCLUDE_DIR})
ELSE(OLM_FOUND)
	SET(OLM_LIBRARIES)
	SET(OLM_INCLUDE_DIRS)
ENDIF(OLM_FOUND)

MARK_AS_ADVANCED(OLM_INCLUDE_DIRS OLM_LIBRARIES)