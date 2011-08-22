// =================
// Copyright (c) Queen's University
// All rights reserved.

// See Copyright.txt for more details.
// =================

/* This will be a semi-template for how all the others should be so that
 * things can easily be inputted/transformed.
 * Stuff to fill in will be marked by @STUFF@
*/


/*
 * You must specify the S_FUNCTION_NAME as the name of your S-function.
 */

#define S_FUNCTION_NAME  SimvtkPiecewiseFunctionMat
#define S_FUNCTION_LEVEL 2
#define MATLAB_MEX_FILE

/*
 * Need to include simstruc.h for the definition of the SimStruct and
 * its associated macro definitions.
 *
 * The following headers are included by matlabroot/simulink/include/simstruc.h
 * when compiling as a MEX file:
 *
 *   matlabroot/extern/include/tmwtypes.h    - General types, e.g. real_T
 *   matlabroot/extern/include/mex.h         - MATLAB MEX file API routines
 *   matlabroot/extern/include/matrix.h      - MATLAB MEX file API routines
 *
 */
#include "simstruc.h"
#include "vtkPiecewiseFunction.h"


//must include if written in c++
#ifdef __cplusplus
extern "C" { // use the C fcn-call standard for all functions
#endif       // defined within this scope


/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 *
 *    The direct feedthrough flag can be either 1=yes or 0=no. It should be
 *    set to 1 if the input, "u", is used in the mdlOutput function. Setting
 *    this to 0 is akin to making a promise that "u" will not be used in the
 *    mdlOutput function. If you break the promise, then unpredictable results
 *    will occur.
 *
 *    The NumContStates, NumDiscStates, NumInputs, NumOutputs, NumRWork,
 *    NumIWork, NumPWork NumModes, and NumNonsampledZCs widths can be set to:
 *       DYNAMICALLY_SIZED    - In this case, they will be set to the actual
 *                              input width, unless you are have a
 *                              mdlSetWorkWidths to set the widths.
 *       0 or positive number - This explicitly sets item to the specified
 *                              value.
 */
static void mdlInitializeSizes(SimStruct *S)
{
  int nInputPorts  = 1;  /* just 1 input for the table from matlab */
  int nOutputPorts = 1;  /* just 1 for "Self" */


  int needsInput = 1; /*require all ports to be direct feedthrough */

  int i = 0, j = 0;

  DTypeId id;

  if (ssGetDataTypeId((S), "vtkObject") == INVALID_DTYPE_ID)
    {
    int status;
    id = ssRegisterDataType(S, "vtkObject");
    if(id == INVALID_DTYPE_ID) return;
    status = ssSetDataTypeSize(S, id, sizeof(void *));
    if (status == 0) return;
    }
  else
    {
    id = ssGetDataTypeId(S, "vtkObject");
    }

  /* Number of expected parameters = 0 */
  ssSetNumSFcnParams(S, 0);
  if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S))
    {
    return;
    }

  ssSetNumContStates(    S, 0);   /* number of continuous states           */
  ssSetNumDiscStates(    S, 0);   /* number of discrete states             */

  //set Number of input ports
  if (!ssSetNumInputPorts(S, nInputPorts)) return;

  ssSetInputPortDimensionInfo(S, 0, DYNAMIC_DIMENSION);
  ssSetInputPortDataType(S, 0, SS_DOUBLE);
  ssSetInputPortDirectFeedThrough(S, 0, needsInput);
  ssSetInputPortRequiredContiguous(S, 0, 1); //make all required contiguous

  //setting number of output ports
  if (!ssSetNumOutputPorts(S, nOutputPorts)) return;

  /*
   * Set output port dimensions for each output port.
   * Since each output will always be passed as a pointer, so only need
   * to keep track of current location in simulink port list.
   */
  ssSetOutputPortWidth(S, 0, 1);
  ssSetOutputPortDataType(S, 0, id);

  ssSetNumSampleTimes(   S, 1);   /* number of sample times                */

  ssSetNumRWork(         S, 0);   /* number of real work vector elements   */
  ssSetNumIWork(         S, 0);   /* number of integer work vector elements*/
  ssSetNumPWork(         S, 0);   /* number of pointer work vector elements*/
  ssSetNumModes(         S, 0);   /* number of mode work vector elements   */
  ssSetNumNonsampledZCs( S, 0);   /* number of nonsampled zero crossings   */
  ssSetOptions(          S, SS_OPTION_CALL_TERMINATE_ON_EXIT);   /* since */
      /*  objects are created in mdlStart, always want them deleted at end */

} /* end mdlInitializeSizes */


/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *
 *    This function is used to specify the sample time(s) for your S-function.
 *    You must register the same number of sample times as specified in
 *    ssSetNumSampleTimes. If you specify that you have no sample times, then
 *    the S-function is assumed to have one inherited sample time.
 *
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
  /* Register one pair for each sample time */
  ssSetSampleTime(S, 0, CONTINUOUS_SAMPLE_TIME);
  ssSetOffsetTime(S, 0, 0.0);

} /* end mdlInitializeSampleTimes */


#define MDL_START  /* Change to #undef to remove function */
#if defined(MDL_START)
  /* Function: mdlStart =======================================================
   * Abstract:
   *    This function is called once at start of model execution. If you
   *    have states that should be initialized once, this is the place
   *    to do it.
   */
static void mdlStart(SimStruct *S)
{
  int i = 0;
  /* get the number of inputs that the vtkAlgorithm will use (so know
   * location of where self indicator will be)
   */
  vtkPiecewiseFunction *filter = vtkPiecewiseFunction::New();
  ssSetUserData(S, (void*)filter);

  /* dim[0] = rows , dim[1] = col */
  int* dimensions0 = ssGetInputPortDimensions(S, 0); /* matrix */

  int numDimensions0 = ssGetInputPortNumDimensions(S, 0); /* matrix */

  if (numDimensions0 != 2 || (dimensions0[1] != 2 && dimensions0[1] != 4))
    {
    ssSetErrorStatus(S, "Input should be a 2xN or 4xN matrix.");
    return;
    }

  /* Set up all parameters that will be constant throughout the
   * program and all pointers  (which also stay constant)
   */
  double *InputMatrix = (double*) ssGetInputPortSignal(S,0);

  if (dimensions0[1] == 2)
    {
    filter->RemoveAllPoints();
    for (i=0; i<dimensions0[0]; i++)
      {
      filter->AddPoint(InputMatrix[0*dimensions0[0] + i],
                       InputMatrix[1*dimensions0[0] + i]);
      }
    }
  else if (dimensions0[1] == 4)
    {
    filter->RemoveAllPoints();
    for (i=0; i<dimensions0[0]; i++)
      {
      filter->AddPoint(InputMatrix[0*dimensions0[0] + i],
                       InputMatrix[1*dimensions0[0] + i],
                       InputMatrix[2*dimensions0[0] + i],
                       InputMatrix[3*dimensions0[0] + i]);
      }
    }

  vtkPiecewiseFunction **OutputPort;
  OutputPort = reinterpret_cast<vtkPiecewiseFunction**>(ssGetOutputPortSignal(S, 0));
  OutputPort[0] = filter;
}
#endif /*  MDL_START */

/* Function: mdlOutputs =======================================================
 * Abstract:
 *    In this function, you compute the outputs of your S-function
 *    block. Generally outputs are placed in the output vector(s),
 *    ssGetOutputPortSignal.
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
  int i = 0, j = 0;
  /* get the number of inputs that the vtkAlgorithm will use (so know
   * location of where self indicator will be)
   */
  vtkPiecewiseFunction *filter = reinterpret_cast<vtkPiecewiseFunction *> (ssGetUserData(S));

  UNUSED_ARG(tid);

  /* dim[0] = rows , dim[1] = col */
  int* dimensions0 = ssGetInputPortDimensions(S, 0); /* matrix */

  int numDimensions0 = ssGetInputPortNumDimensions(S, 0); /* matrix */

  if (numDimensions0 != 2 || (dimensions0[1] != 2 && dimensions0[1] != 4))
    {
    ssSetErrorStatus(S, "Input should be a 2xN or 4xN matrix.");
    return;
    }

  /* Set up all parameters that will be constant throughout the
   * program and all pointers  (which also stay constant)
   */
  double *InputMatrix = (double*) ssGetInputPortSignal(S,0);

  if (dimensions0[1] == 2)
    {
    filter->RemoveAllPoints();
    for (i=0; i<dimensions0[0]; i++)
      {
      filter->AddPoint(InputMatrix[0*dimensions0[0] + i],
                       InputMatrix[1*dimensions0[0] + i]);
      }
    }
   else if (dimensions0[1] == 4)
    {
    filter->RemoveAllPoints();
    for (i=0; i<dimensions0[0]; i++)
      {
      filter->AddPoint(InputMatrix[0*dimensions0[0] + i],
                       InputMatrix[1*dimensions0[0] + i],
                       InputMatrix[2*dimensions0[0] + i],
                       InputMatrix[3*dimensions0[0] + i]);
      }
    }

  vtkPiecewiseFunction **OutputPort;
  OutputPort = reinterpret_cast<vtkPiecewiseFunction**>(ssGetOutputPortSignal(S, 0));
  OutputPort[0] = filter;
} /* end mdlOutputs */


#define MDL_SET_INPUT_PORT_DIMENSION_INFO
#if defined(MDL_SET_INPUT_PORT_DIMENSION_INFO) && defined(MATLAB_MEX_FILE)
  /* Function: mdlSetInputPortDimensionInfo ====================================
   * Abstract:
   *    This method is called with the candidate dimensions for an input port
   *    with unknown dimensions. If the proposed dimensions are acceptable, the
   *    method should go ahead and set the actual port dimensions.
   *    If they are unacceptable an error should be generated via
   *    ssSetErrorStatus.
   */
static void mdlSetInputPortDimensionInfo(SimStruct *S, int_T port, const DimsInfo_T *dimsInfo)
{
  /* dynamically set input port dimensions from the input signal at runtime */
  if(!ssSetInputPortDimensionInfo(S, port, dimsInfo)) return;
}
#endif /* MDL_SET_INPUT_PORT_DIMENSION_INFO */

#define MDL_SET_OUTPUT_PORT_DIMENSION_INFO
#if defined(MDL_SET_OUTPUT_PORT_DIMENSION_INFO) && defined(MATLAB_MEX_FILE)
  /* Function: mdlSetOutputPortDimensionInfo ===================================
   * Abstract:
   *    This method is called with the candidate dimensions for an output port
   *    with unknown dimensions. If the proposed dimensions are acceptable, the
   *    method should go ahead and set the actual port dimensions.
   *    If they are unacceptable an error should be generated via
   *    ssSetErrorStatus.
   */
static void mdlSetOutputPortDimensionInfo(SimStruct *S, int_T port, const DimsInfo_T *dimsInfo)
{
  /* dynamically set ouput port dimensions from the ouput signal at runtime */
  if(!ssSetOutputPortDimensionInfo(S, port, dimsInfo)) return;
}
#endif /* MDL_SET_OUTPUT_PORT_DIMENSION_INFO */

/* Function: mdlTerminate =====================================================
 * Abstract:
 *    In this function, you should perform any actions that are necessary
 *    at the termination of a simulation.  For example, if memory was allocated
 *    in mdlStart, this is the place to free it.
 *
 */
static void mdlTerminate(SimStruct *S)
{
  /* Free memory used by filter */
  vtkPiecewiseFunction *filter =
    reinterpret_cast<vtkPiecewiseFunction*> (ssGetUserData(S));
  if (filter != NULL)
    {
    filter->Delete();
    }
}

/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif

#ifdef __cplusplus
} // end of extern "C" scope
#endif

