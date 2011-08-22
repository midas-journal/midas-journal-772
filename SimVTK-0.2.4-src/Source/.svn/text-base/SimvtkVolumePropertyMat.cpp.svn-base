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

#define S_FUNCTION_NAME  SimvtkVolumePropertyMat
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
#include "vtkAlgorithmOutput.h"
#include "vtkAlgorithm.h"
#include "vtkDataObject.h"
#include "vtkVolumeProperty.h"


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
  const int ParameterListInputPortEndLocation = 4; /*location in parameter list where XML inputs stop */
  const int ParameterListOutputPortStartLocation = 36; /*inputs + 2*parameters */
  int nInputPorts  = 0;  /* number of input ports  from XML document for optional/repeatable stuff */
  int nPromotedInputPorts = 0; /*number of ports that user wishes to be promoted*/
  int nRealInputPorts = 0; /* number of ports needed for stuff directly from the vtkObject using vtkAlgorithm*/
  int nOutputPorts = 0;  /* number of output ports that the user has specified will be wanted. */
  int nPromotedOutputPorts = 0; /*number of ports that the user wishes to be promoted*/
  int InputPortIndex  = 0; /* current position in input port list */
  int OutputPortIndex = 0; /* current position in output port list */
  int AsInputOutputCheck = 0; /* used to check if a parameter is signalled as input or output when doing input/output types/sizes initializing */

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

  /* Number of expected parameters = number of possible inputs + 2*number of possible parameters in XML + number of outputs
   (2*Parameters as each parameter will have 1 item for indicating how it will be used and 1 for the parameter value itself)*/
  ssSetNumSFcnParams(S, 40);
  if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
    return;
  }

  ssSetNumContStates(    S, 0);   /* number of continuous states           */
  ssSetNumDiscStates(    S, 0);   /* number of discrete states             */

  /*
   * Configure the input ports.
   */

  //check to see what user wants as inputs
  for (i = 0;  i < ParameterListInputPortEndLocation; i++)
  {
    nInputPorts  += (int)mxGetScalar(ssGetSFcnParam(S,i));
  }

  /* check to see which parameters should be promoted as inputs (increase count only if the parameter input indicator
  * is set to AsInput... otherwise leave it alone
  */
  for (i = ParameterListInputPortEndLocation; i < ParameterListOutputPortStartLocation; i = i + 2)
  {
         switch(i) //divide items based on how can be used
      {
      case 4: case 10: case 12: case 14: case 20: case 28: case 30: case 32: case 34:
      ((int)mxGetScalar(ssGetSFcnParam(S,i)) == 2) ? nPromotedInputPorts++ : nPromotedInputPorts;
      break;
      case 8:       if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == 1)
      {
        nPromotedInputPorts += (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i+1))));
      }
      break;
      }

    //((int)mxGetScalar(ssGetSFcnParam(S,i)) == 2) ? nPromotedInputPorts++ : nPromotedInputPorts;
  }

  //check for number of inputs that the vtkObject takes if is part of vtkAlgorithm




  //set Number of input ports
  if (!ssSetNumInputPorts(S, nInputPorts + nPromotedInputPorts + nRealInputPorts)) return;

  for (i = 0; i < nInputPorts + nRealInputPorts; i++) // for all the input ports that will be pointers
  {
    ssSetInputPortWidth(S, i, 1);
    ssSetInputPortDirectFeedThrough(S, i, needsInput);
    ssSetInputPortDataType(S, i, id);
    ssSetInputPortRequiredContiguous(S, i, 1);  // require that all input ports are contiguous
    InputPortIndex++;
  }

  for (i = ParameterListInputPortEndLocation; i < ParameterListOutputPortStartLocation && InputPortIndex < ssGetNumInputPorts(S); i = i + 2) //because want to skip actual value
  {
    AsInputOutputCheck = 0;
    switch (i)
    {
      case 4: case 10: case 12: case 14: case 20: case 28: case 30: case 32: case 34:
      if(static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == 2)
      {
        AsInputOutputCheck = 1;
      }
      break;
      case 8:
      if(static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == 1)
      {
        AsInputOutputCheck = 1;
      }
      break;
    }
    if(AsInputOutputCheck == 1)
    {
      switch(i) //divide items based on size of array
      {
      case 4: case 10: case 12: case 14: case 20: case 28: case 30: case 32: case 34:
        ssSetInputPortWidth(S, InputPortIndex, 1);
        break;
            }
      switch(i) // divide items based on type of input
      {
      case 4: case 10: case 28: case 32: case 34:
        ssSetInputPortDataType(S, InputPortIndex, SS_DOUBLE);
        ssSetInputPortDirectFeedThrough(S, InputPortIndex, needsInput);
        ssSetInputPortRequiredContiguous(S, InputPortIndex, 1); //make all required contiguous
        InputPortIndex++;
        break;
      case 12: case 14: case 20: case 30:
        ssSetInputPortDataType(S, InputPortIndex, SS_INT32);
        ssSetInputPortDirectFeedThrough(S, InputPortIndex, needsInput);
        ssSetInputPortRequiredContiguous(S, InputPortIndex, 1); //make all required contiguous
        InputPortIndex++;
        break;
            }
    }
    if (AsInputOutputCheck == 1)
    {
      switch(i)
      {
      case 8:           for (j = 0; j < static_cast<int>(mxGetScalar(ssGetSFcnParam(S, i+1))); j++)// will go through and add 1 input for each item user wants
          {
            ssSetInputPortWidth(S, InputPortIndex + j, 1);
          }
        break;
            }
      switch(i)
      {
      case 8:         for (j = 0; j < static_cast<int>(mxGetScalar(ssGetSFcnParam(S, i+1))); j++) // goes through and adds one for each input user wants
        {
          ssSetInputPortDataType(S, InputPortIndex + j, SS_DOUBLE);
          ssSetInputPortDirectFeedThrough(S, InputPortIndex + j, needsInput);
          ssSetInputPortRequiredContiguous(S, InputPortIndex + j, 1); // make all required contiguous
        }
        InputPortIndex += static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i+1)));
        break;
                  }
    }
  }


  // check to see what the user wants to be an output
  for (i = ParameterListOutputPortStartLocation; i < ssGetNumSFcnParams(S); i++)
  {
    nOutputPorts += static_cast<int> (mxGetScalar(ssGetSFcnParam(S,i)));
  }

  // check which parameters were promoted to output status
  for (i = ParameterListInputPortEndLocation; i < ParameterListOutputPortStartLocation; i = i + 2)
  {
         switch(i) //divide items based on how can be used
      {
      case 4: case 10: case 12: case 14: case 20: case 28: case 30: case 32: case 34:
      ((int)mxGetScalar(ssGetSFcnParam(S,i)) == 4) ? nPromotedOutputPorts++ : nPromotedOutputPorts;
      break;
      case 6: case 16: case 18: case 22: case 24: case 26:
      ((int)mxGetScalar(ssGetSFcnParam(S,i)) == 1) ? nPromotedOutputPorts++ : nPromotedOutputPorts;
      break;
      }

    //((int)mxGetScalar(ssGetSFcnParam(S,i)) == 4) ? nPromotedOutputPorts++ : nPromotedOutputPorts;
  }

  //setting number of output ports
  if (!ssSetNumOutputPorts(S, nOutputPorts + nPromotedOutputPorts)) return;

  /*
   * Set output port dimensions for each output port.
   * Since each output will always be passed as a pointer, so only need to keep track of current location in simulink port list.
   */
  for (i = 0; i < nOutputPorts; i++) //for outputs that will be pointers
  {
    ssSetOutputPortWidth(S, OutputPortIndex, 1);
    ssSetOutputPortDataType(S, OutputPortIndex, id);
    OutputPortIndex++;
  }

  /* set up all outputs for the parameters that have been promoted to outputs */
  for (i = ParameterListInputPortEndLocation; i < ParameterListOutputPortStartLocation && OutputPortIndex < ssGetNumOutputPorts(S); i = i + 2) //because want to skip actual value
  {
    AsInputOutputCheck = 0;
    switch (i)
    {
      case 4: case 10: case 12: case 14: case 20: case 28: case 30: case 32: case 34:
      if(static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == 4)
      {
        AsInputOutputCheck = 1;
      }
      break;
      case 6: case 16: case 18: case 22: case 24: case 26:
      if(static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == 1)
      {
        AsInputOutputCheck = 1;
      }
      break;
    }
    if(AsInputOutputCheck == 1)
    {
      switch(i) //divide items based on size of array
      {
      case 4: case 6: case 10: case 12: case 14: case 16: case 18: case 20: case 24: case 26: case 28: case 30: case 32: case 34:
        ssSetOutputPortWidth(S, OutputPortIndex, 1);
        break;
      case 22:
        ssSetOutputPortWidth(S, OutputPortIndex, DYNAMICALLY_SIZED);
        break;
      }
      switch(i) // divide items based on type of input
      {
      case 4: case 10: case 28: case 32: case 34:
        ssSetOutputPortDataType(S, OutputPortIndex, SS_DOUBLE);
        break;
      case 6: case 12: case 14: case 16: case 18: case 20: case 24: case 26: case 30:
        ssSetOutputPortDataType(S, OutputPortIndex, SS_INT32);
        break;
      case 22:
        ssSetOutputPortDataType(S, OutputPortIndex, SS_INT8);
        break;
      }
      OutputPortIndex++;
    }
  }




  ssSetNumSampleTimes(   S, 1);   /* number of sample times                */

  ssSetNumRWork(         S, 0);   /* number of real work vector elements   */
  ssSetNumIWork(         S, 0);   /* number of integer work vector elements*/
  ssSetNumPWork(         S, 0);   /* number of pointer work vector elements*/
  ssSetNumModes(         S, 0);   /* number of mode work vector elements   */
  ssSetNumNonsampledZCs( S, 0);   /* number of nonsampled zero crossings   */
  ssSetOptions(          S, SS_OPTION_CALL_TERMINATE_ON_EXIT);   /* since objects are created in mdlStart, always want them deleted at end */

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
  int inputPortIndex = 0, nInputPorts = 0, outputPortIndex = 0, i = 0, j = 0, nRealInputPorts = 0, nOutputPorts = 0; // used to pass through list of parameters and do correct thing with each entered parameter
  //get the number of inputs that the vtkAlgorithm will use (so know location of where self indicator will be)


  //get location of where the input for self should be
  inputPortIndex = nRealInputPorts;

  //create the vtkObject and store pointer in user data
  vtkVolumeProperty *filter;

  if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S, 0))) == 0)
  {
    filter =  vtkVolumeProperty::New();
  }
  else
  {
    void *tempPoint = const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex));
    vtkObject **pointer;
    pointer = reinterpret_cast<vtkObject**>(tempPoint);
    if (pointer[0]->IsA("vtkVolumeProperty"))
    {
      filter = dynamic_cast<vtkVolumeProperty*>( pointer[0] );
      inputPortIndex++;
    }
    else
    {
      ssPrintf("Bad Input for self for %s.\n", "vtkVolumeProperty");
      filter = vtkVolumeProperty::New();
    }
  }

  ssSetUserData(S, reinterpret_cast<void*>(filter));

  //take care of all inputs created by the vtkObject first (so stay at top of list)


  // take care of all outputs created by the vtkObject first (so stay at top of list)


  // Set up all parameters that will be constant throughout the program and all pointers  (which also stay constant)
  /* Set up all inputs and outputs first as they will likely stay as input/output more than parameters so less changing of arrows */

      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,1))) == 1 && ssGetInputPortConnected(S, inputPortIndex))
        {
          void* point = const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex));
          vtkObject *o = reinterpret_cast<vtkObject **>(point)[0] ;
          if (o->IsA("vtkPiecewiseFunction"))
          {
            filter->SetColor(reinterpret_cast<vtkPiecewiseFunction*>(o));
          }
          else if (o->IsA("vtkColorTransferFunction"))
          {
            filter->SetColor(reinterpret_cast<vtkColorTransferFunction*>(o));
          }
          else
          {
            ssSetErrorStatus(S, "Bad input type: needs vtkPiecewiseFunction or vtkColorTransferFunction");
          }
          inputPortIndex++;
        }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,2))) == 1 && ssGetInputPortConnected(S, inputPortIndex))
        {
          void* point = const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex));
          vtkObject *o = reinterpret_cast<vtkObject **>(point)[0] ;
          int typeIsCorrect = o->IsA("vtkPiecewiseFunction");
          if (typeIsCorrect)
          {
            filter->SetGradientOpacity(reinterpret_cast<vtkPiecewiseFunction*>(o));
          }
          else
          {
            ssSetErrorStatus(S, "Bad input type: needs vtkPiecewiseFunction");
          }
          inputPortIndex++;
        }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,3))) == 1 && ssGetInputPortConnected(S, inputPortIndex))
        {
          void* point = const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex));
          vtkObject *o = reinterpret_cast<vtkObject **>(point)[0] ;
          int typeIsCorrect = o->IsA("vtkPiecewiseFunction");
          if (typeIsCorrect)
          {
            filter->SetScalarOpacity(reinterpret_cast<vtkPiecewiseFunction*>(o));
          }
          else
          {
            ssSetErrorStatus(S, "Bad input type: needs vtkPiecewiseFunction");
          }
          inputPortIndex++;
        }

      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,36))) == 1)
      {
        vtkVolumeProperty **OutputPort;
        OutputPort = reinterpret_cast<vtkVolumeProperty**>(ssGetOutputPortSignal(S, outputPortIndex));
        OutputPort[0] = filter;
        outputPortIndex++;
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,37))) == 1)
      {
        vtkPiecewiseFunction **OutputPort;
        OutputPort = reinterpret_cast<vtkPiecewiseFunction**>(ssGetOutputPortSignal(S, outputPortIndex));
        OutputPort[0] = filter->GetGrayTransferFunction();
        outputPortIndex++;
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,38))) == 1)
      {
        vtkColorTransferFunction **OutputPort;
        OutputPort = reinterpret_cast<vtkColorTransferFunction**>(ssGetOutputPortSignal(S, outputPortIndex));
        OutputPort[0] = filter->GetRGBTransferFunction();
        outputPortIndex++;
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,39))) == 1)
      {
        vtkPiecewiseFunction **OutputPort;
        OutputPort = reinterpret_cast<vtkPiecewiseFunction**>(ssGetOutputPortSignal(S, outputPortIndex));
        OutputPort[0] = filter->GetStoredGradientOpacity();
        outputPortIndex++;
      }

      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,4))) == 1)
      {
        filter->SetAmbient((double)mxGetScalar(ssGetSFcnParam(S, 4 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,10))) == 1)
      {
        filter->SetDiffuse((double)mxGetScalar(ssGetSFcnParam(S, 10 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,12))) == 1)
      {
        filter->SetDisableGradientOpacity((int)mxGetScalar(ssGetSFcnParam(S, 12 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,14))) == 1)
      {
        filter->SetIndependentComponents((int)mxGetScalar(ssGetSFcnParam(S, 14 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,20))) == 1)
      {
        filter->SetInterpolationType((int)mxGetScalar(ssGetSFcnParam(S, 20 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,28))) == 1)
      {
        filter->SetScalarOpacityUnitDistance((double)mxGetScalar(ssGetSFcnParam(S, 28 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,30))) == 1)
      {
        filter->SetShade((int)mxGetScalar(ssGetSFcnParam(S, 30 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,32))) == 1)
      {
        filter->SetSpecular((double)mxGetScalar(ssGetSFcnParam(S, 32 + 1)));
      }
      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,34))) == 1)
      {
        filter->SetSpecularPower((double)mxGetScalar(ssGetSFcnParam(S, 34 + 1)));
      }


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
  int inputPortIndex = 0, outputPortIndex = 0, nInputPortIDX = 4, nOutputPortIDX = 36, nInputPorts = 0, i = 0, j = 0, k = 0;
  /* set up the vtkObject with all the proper parameters if parameters can change and render/initialize/etc. here */

  vtkVolumeProperty *filter = reinterpret_cast<vtkVolumeProperty *> (ssGetUserData(S));

  UNUSED_ARG(tid);

  /*Check to see where the parameter inputs start in the port listing*/
  for (i = 0; i < nInputPortIDX; i++)
  {
    inputPortIndex += static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i)));
  }



  /*Check to see where the parameter outputs start in the port listing*/
  for (i = nOutputPortIDX; i < ssGetNumSFcnParams(S); i++)
  {
    outputPortIndex += static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i)));
  }



  /*Set up all parameters that have been promoted to inputs or outputs*/

    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,4))) == 2) // wanted as input
    {
      filter->SetAmbient((reinterpret_cast<double*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,4))) == 4) // wanted as output
    {
      double parameter;
      parameter = filter->GetAmbient();
      double *outputValue = reinterpret_cast<double*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,6))) == 1) // wanted as output
    {
      int parameter;
      parameter = filter->GetColorChannels();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,8))) == 1) // wanted as input
    {
      for (k = 0; k < static_cast<int>(mxGetScalar(ssGetSFcnParam(S,8+1))); k++)
      {
      filter->SetComponentWeight(k, (reinterpret_cast<double*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,10))) == 2) // wanted as input
    {
      filter->SetDiffuse((reinterpret_cast<double*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,10))) == 4) // wanted as output
    {
      double parameter;
      parameter = filter->GetDiffuse();
      double *outputValue = reinterpret_cast<double*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,12))) == 2) // wanted as input
    {
      filter->SetDisableGradientOpacity((reinterpret_cast<int*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,12))) == 4) // wanted as output
    {
      int parameter;
      parameter = filter->GetDisableGradientOpacity();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,14))) == 2) // wanted as input
    {
      filter->SetIndependentComponents((reinterpret_cast<int*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,14))) == 4) // wanted as output
    {
      int parameter;
      parameter = filter->GetIndependentComponents();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,16))) == 1) // wanted as output
    {
      int parameter;
      parameter = filter->GetIndependentComponentsMaxValue();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,18))) == 1) // wanted as output
    {
      int parameter;
      parameter = filter->GetIndependentComponentsMinValue();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,20))) == 2) // wanted as input
    {
      filter->SetInterpolationType((reinterpret_cast<int*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,20))) == 4) // wanted as output
    {
      int parameter;
      parameter = filter->GetInterpolationType();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,22))) == 1) // wanted as output
    {
      char *parameter;
      parameter = (char*)( filter->GetInterpolationTypeAsString() );
      char **outputValue = reinterpret_cast<char **>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,24))) == 1) // wanted as output
    {
      int parameter;
      parameter = filter->GetInterpolationTypeMaxValue();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,26))) == 1) // wanted as output
    {
      int parameter;
      parameter = filter->GetInterpolationTypeMinValue();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,28))) == 2) // wanted as input
    {
      filter->SetScalarOpacityUnitDistance((reinterpret_cast<double*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,28))) == 4) // wanted as output
    {
      double parameter;
      parameter = filter->GetScalarOpacityUnitDistance();
      double *outputValue = reinterpret_cast<double*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,30))) == 2) // wanted as input
    {
      filter->SetShade((reinterpret_cast<int*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,30))) == 4) // wanted as output
    {
      int parameter;
      parameter = filter->GetShade();
      int *outputValue = reinterpret_cast<int*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,32))) == 2) // wanted as input
    {
      filter->SetSpecular((reinterpret_cast<double*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,32))) == 4) // wanted as output
    {
      double parameter;
      parameter = filter->GetSpecular();
      double *outputValue = reinterpret_cast<double*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,34))) == 2) // wanted as input
    {
      filter->SetSpecularPower((reinterpret_cast<double*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))[0]);
      inputPortIndex++;
    }
    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,34))) == 4) // wanted as output
    {
      double parameter;
      parameter = filter->GetSpecularPower();
      double *outputValue = reinterpret_cast<double*>(ssGetOutputPortSignal(S, outputPortIndex));
      outputValue[0] = parameter;
      outputPortIndex++;
    }


  //filter->Render() if is a render window


  //filter->Initialize() if is a render window interactor


} /* end mdlOutputs */

#define MDL_SET_INPUT_PORT_DIMENSION_INFO  // do same for output
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
  //dynamically set input port dimensions from the input signal at runtime
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
  //dynamically set ouput port dimensions from the ouput signal at runtime
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
  //Free memory used by filter
  vtkVolumeProperty *filter = reinterpret_cast<vtkVolumeProperty*> (ssGetUserData(S));
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
