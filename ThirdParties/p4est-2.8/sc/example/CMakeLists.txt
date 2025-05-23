cmake_minimum_required(VERSION 3.13...3.20)
project(libscExamples LANGUAGES C)

include(CTest)
include(CheckSymbolExists)
include(CheckIncludeFile)

option(mpi "use MPI" off)

# --- find external libraries
if(mpi)
  find_package(MPI COMPONENTS C REQUIRED)
  if(NOT MPIEXEC_EXECUTABLE)
    message(FATAL_ERROR "MPIEXEC not found")
  endif()
endif(mpi)

find_package(ZLIB REQUIRED)
find_package(Threads)

# --- find our library

if(NOT SC_ROOT AND NOT DEFINED ENV{SC_ROOT})
  set(SC_ROOT ${PROJECT_SOURCE_DIR}/../build)
endif()

find_package(SC REQUIRED)

# --- get system capabilities

check_symbol_exists(sqrt math.h SC_NONEED_M)
if(NOT SC_NONEED_M)
  set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} m)
  check_symbol_exists(sqrt math.h SC_NEED_M)
endif()

check_include_file(unistd.h SC_HAVE_UNISTD_H)
if(SC_HAVE_UNISTD_H)
  check_include_file(getopt.h SC_HAVE_GETOPT_H)
endif()

# --- build examples

function(test_sc_example name files)

add_executable(sc_${name} ${files})
target_include_directories(sc_${name} PRIVATE ${PROJECT_SOURCE_DIR}/src ${PROJECT_BINARY_DIR}/include)
target_link_libraries(sc_${name} PRIVATE SC::SC)
if(MPI_FOUND)
  target_link_libraries(sc_${name} PRIVATE MPI::MPI_C)
endif()
if(ZLIB_FOUND)
  target_link_libraries(sc_${name} PRIVATE ZLIB::ZLIB)
endif()
if(SC_NEED_M)
  target_link_libraries(sc_${name} PRIVATE m)
endif()

if(MPI_FOUND)
  add_test(NAME sc:example:${name} COMMAND ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${MPIEXEC_MAX_NUMPROCS} $<TARGET_FILE:sc_${name}>)
else()
  add_test(NAME sc:example:${name} COMMAND $<TARGET_FILE:sc_${name}>)
endif()

endfunction(test_sc_example)


test_sc_example(function function/function.c)
test_sc_example(logging logging/logging.c)
test_sc_example(test_shmem testing/sc_test_shmem.c)

if(SC_HAVE_GETOPT_H)
  test_sc_example(options options/options.c)
endif()

if(OpenMP_FOUND)
  test_sc_example(openmp openmp/openmp.c)
  target_link_libraries(sc_openmp PRIVATE OpenMP::OpenMP_C)
endif()

if(Threads_FOUND)
  check_include_file(pthread.h HAS_PTHREAD)
  if(HAS_PTHREAD)
    test_sc_example(pthread pthread/pthread.c)
    target_link_libraries(sc_pthread PRIVATE Threads::Threads)
  endif()
endif()
