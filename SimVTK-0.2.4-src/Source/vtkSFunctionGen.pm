package vtkSFunctionGen;


# =================
# Copyright (c) Queen's University
# All rights reserved.

# See Copyright.txt for more details.
# =================

###############################################
# SIMITK Project
# Karen Li and Jing Xiang
# February 20, 2008
#
# Modified by Adam Campigotto on June 10th 2008
# to be used with VTK
###############################################

use strict;
use Switch;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(vtkSFunctionGen);

# Generates S-Function file.
# Inputs: 1. filterHash reference
#         2. directory
sub vtkSFunctionGen {

  my ($filterHash, $directory, $isvtkAlgorithmSubclass, $sourceDirectory,
      $buildDirectory) = @_;
  
  die "ERROR: SimvtkTemplate.cpp.in file not found"
  unless -f $sourceDirectory . "/SimvtkTemplate.cpp.in";
  # Read the input file into a single string
  open (INFILE, "<", $sourceDirectory . "/SimvtkTemplate.cpp.in");
  undef $/;
  my $content = <INFILE>;
  
  $/ = "\n";
  close INFILE;
  
  # if is not on Windows, remove the control-M characters
  if ($^O ne "MSWin32") {
    $content =~ s/\r//g;
  }
  
  # Create the output file
  open (OUTFILE,
        ">$buildDirectory/Sim" . $filterHash->{"Filter_Name"} . "Mat.cpp");
  
  my $extraHeader = "";
 
  if ($isvtkAlgorithmSubclass)
  {
    $extraHeader .= "\n#include \"vtkInformation.h\"\n";
  }
  
  # Fix headers for Linux systems for  RenderWindow and Interactor 
  if ($^O eq "linux")
  {
    if (($filterHash->{"Filter_Name"} =~ /RenderWindowInteractor$/) ||
        ($filterHash->{"Filter_Name"} =~ /RenderWindow$/) ||
        ($filterHash->{"Filter_Name"} =~ /ImageViewer$/) ||
        ($filterHash->{"Filter_Name"} =~ /ImageViewer2$/))
    {
    $extraHeader .= setupLinuxHeader();
    }
  }
  else
  {
    # Create a special callback for vtkRenderWindowInteractor
    if ($filterHash->{"Filter_Name"} =~ /RenderWindowInteractor$/)
    {
      $extraHeader .= setupInteractorCallback();
    }
    elsif (($filterHash->{"Filter_Name"} =~ /ImageViewer$/) ||
           ($filterHash->{"Filter_Name"} =~ /ImageViewer2$/))
    {
      $extraHeader .= "#include \"vtkRenderWindow.h\"\n";
    }
  }

  $content =~ s/\@EXTRA_HEADER\@/$extraHeader/g;
  
  # FILTER_NAME
  my $filterName = $filterHash->{"Filter_Name"};
  my $realFilterName = $filterName;
  if ($^O eq "darwin")
  {
    if ($filterName eq "vtkRenderWindowInteractor")
    {
      $realFilterName = "vtkSimCocoaRenderWindowInteractor";
    }
    if ($filterName eq "vtkRenderWindow")
    {
      $realFilterName = "vtkSimCocoaRenderWindow";
    }
  }
  $content =~ s/\@FILTER_NAME\@/$filterName/g;
  $content =~ s/\@REAL_FILTER_NAME\@/$realFilterName/g;
  
  # OBJECT_MODIFICATION
  # any special changes made to object afer New() is called
  my $objectModification = "";

  if ($^O eq "linux")
  {
    # nothing special to do for linux
  }
  else
  {
    # Add observer for vtkRenderWindowInteractor
    if ($filterHash->{"Filter_Name"} =~ /RenderWindowInteractor$/)
    {
      $objectModification .= setupInteractorObserver();
    }
  }

  $content =~ s/\@OBJECT_MODIFICATION\@/$objectModification/g;

  #NUM_INPUTS
  my $numInputs = 0;
  $numInputs = scalar @{$filterHash->{"Inputs"}} if $filterHash->{"Inputs"};
  $content =~ s/\@NUM_INPUTS\@/$numInputs/g;
  
  #NUM_OUTPUTS
  my $numOutputs = 0;
  $numOutputs = scalar @{$filterHash->{"Outputs"}} if $filterHash->{"Outputs"};
  $content =~ s/\@NUM_OUTPUTS\@/$numOutputs/g;
  
  # NUM_PARAMETERS
  my $numParams = 0;
  $numParams = scalar @{$filterHash->{"Filter_Parameters"}}
    if $filterHash->{"Filter_Parameters"};

  $content =~ s/\@NUM_PARAMETERS\@/$numParams/g;
  
  #NUM_INPUTS + PARAMETERS
  #CHANGE HERE! (3 to 2)
  my $numInputsAndParameters = $numParams * 2 + $numInputs;
  $content =~ s/\@NUM_INPUTS_PARAMETERS\@/$numInputsAndParameters/g;
  
  #NUM_INPUTS_PARAMETERS_OUTPUTS
  #CHANGE HERE! (3 to 2)
  my $numInAndParametersAndOut = $numParams * 2 + $numInputs + $numOutputs;
  $content =~ s/\@NUM_INPUTS_PARAMETERS_OUTPUTS\@/$numInAndParametersAndOut/g;
  
  #ALGORITHM_STRINGS
  my $algorithmInitializeSizes = "";
  my $algorithmStartInputString = "";
  my $algorithmStartOutputString = "";
  my $algorithmUpdateInputString = "";
  my $algorithmUpdateOutputString = "";
  if ($isvtkAlgorithmSubclass)
  {
  $algorithmInitializeSizes = setupAlgorithmInitializeSizesString($filterHash);
  $algorithmStartInputString = setupAlgorithmStartInputString();
  $algorithmStartOutputString = setupAlgorithmStartOutputString();
  $algorithmUpdateInputString = setupAlgorithmUpdateInputString();
  $algorithmUpdateOutputString = setupAlgorithmUpdateOutputString();
  }
  $content =~ s/\@ALGORITHM_INITIALIZE_SIZES\@/$algorithmInitializeSizes/g;
  $content =~ s/\@ALGORITHM_START_INPUT\@/$algorithmStartInputString/g;
  $content =~ s/\@ALGORITHM_START_OUTPUT\@/$algorithmStartOutputString/g;
  $content =~ s/\@ALGORITHM_UPDATE_INPUTS\@/$algorithmUpdateInputString/g;
  $content =~ s/\@ALGORITHM_UPDATE_OUTPUTS\@/$algorithmUpdateOutputString/g;
  
  #----------mdlInitializeSizes function----------#

  #PREPARATIONS_PORTS
  
  my %sizesHash = ();
  my $dynamic = setupParameterSizeHash($filterHash, $numInputs, \%sizesHash);
  $content =~ s/\@DYNAMIC\@/$dynamic/g;
  my %typesHash = ();
  setupParameterTypeHash($filterHash, $numInputs, \%typesHash);
  my %flagsHash = ();
  setupParameterFlagHash($filterHash, $numInputs, \%flagsHash);
  my $parameterInputCheckString =
    setupParameterInputCheckString($filterHash, \%flagsHash);
  $content =~ s/\@PARAMETER_INPUT_CHECK\@/$parameterInputCheckString/g;
  my $parameterOutputCheckString =
    setupParameterOutputCheckString($filterHash, \%flagsHash);
  $content =~ s/\@PARAMETER_OUTPUT_CHECK\@/$parameterOutputCheckString/g;
  
  # SETUP_PORTS
  
  my $setupInputArrayString =
    setupInputArrayString($filterHash, \%sizesHash,
                          \%typesHash, \%flagsHash)
    if (scalar @{$filterHash->{"Filter_Parameters"}} > 0);

  $content =~ s/\@INPUT_ARRAY\@/$setupInputArrayString/g;
  
  my $setupOutputArrayString =
      setupOutputArrayString($filterHash, \%sizesHash,
                             \%typesHash, \%flagsHash)
      if (scalar @{$filterHash->{"Filter_Parameters"}} > 0);

  $content =~ s/\@OUTPUT_ARRAY\@/$setupOutputArrayString/g;
  
  # my $setupOutputArraySizesString =
  #   setupOutputArraySizesString($filterHash, \%sizesHash, \%flagsHash)
  #   if (scalar @{$filterHash->{"Filter_Parameters"}} > 0);
  # $content =~ s/\@OUTPUT_ARRAY_SIZES\@/$setupOutputArraySizesString/g;
  
  # my $setupOutputArrayTypesString =
  #   setupOutputArrayTypesString($filterHash, \%typesHash, \%flagsHash)
  #   if (scalar @{$filterHash->{"Filter_Parameters"}} > 0);

  # $content =~ s/\@OUTPUT_ARRAY_TYPES\@/$setupOutputArrayTypesString/g;
  
  #----------mdlStart function-------------#
  #SET_INPUTS
   my $index = 0;
  my $selfInputLocation = 1;
  my $setupProcessInputString =
    setupProcessInputString($filterHash, \$index, \$selfInputLocation);
  $content =~ s/\@SELF_INPUT_LOCATION\@/$selfInputLocation/g;
  $content =~ s/\@PROCESS_INPUT\@/$setupProcessInputString/g;

  #SET_PARAMETERS
  my $setupProcessParameterStartString =
    setupProcessParameterStartString($filterHash, \$index);
  $content =~
    s/\@PROCESS_PARAMETERS_START\@/$setupProcessParameterStartString/g;

  #SET_OUTPUT
  my $setupProcessOutputString =
    setupProcessOutputString($filterHash, \$index);
  $content =~ s/\@PROCESS_OUTPUT\@/$setupProcessOutputString/g;
  
  
  #----------mdlOutputs function----------#
  # SET_PARAMETERS
  my $setupProcessParameterOutputString =
    setupProcessParameterOutputString($filterHash);
  $content =~
    s/\@PROCESS_PARAMETERS_OUTPUT\@/$setupProcessParameterOutputString/g;
  
  #RENDER_WINDOW
  my $filterType = "";
  my $filterName = $filterHash->{"Filter_Name"};
  if ($filterName =~ /RenderWindow$/ ||
      ($filterName =~ /ImageViewer$/ || $filterName =~ /ImageViewer2$/))
  {
    if ($^O eq "linux")
    {
      if ($filterName =~ /RenderWindow$/)
      {
        $filterType = "  vtkXOpenGLRenderWindow *window =\n" .
                      "    vtkXOpenGLRenderWindow::SafeDownCast(filter);\n";
      }
      else
      {
        $filterType = "  vtkXOpenGLRenderWindow *window =\n" .
                      "    vtkXOpenGLRenderWindow::SafeDownCast(\n" .
                      "    filter->GetRenderWindow());\n" 
      }    

      $filterType .=
        "  if (window->GetInteractor() == 0)\n" .
        "  {\n" .
        "    if (window->GetDisplayId() == 0)\n" .
        "    {\n" .
        "      filter->Render();\n" .
        "      Display *display = window->GetDisplayId();\n" .
        "      Atom atom = XInternAtom(display, \"WM_DELETE_WINDOW\", False);\n" .

        "      XSetWMProtocols(display, window->GetWindowId(), &atom, 1);\n" .
        "    }\n" .
        "    else\n" .
        "    {\n" .
        "      filter->Render();\n" .
        "    }\n" .
        "  }\n";
    }
    else
    {
      if ($filterName =~ /RenderWindow$/)
      {
        $filterType =
          "  if (filter->GetInteractor() == 0)\n" .
          "  {\n" .
          "    filter->Render();\n" .
          "  }\n";
      }
      else
      {
        $filterType =
          "  if (filter->GetRenderWindow()->GetInteractor() == 0)\n" .
          "  {\n" .
          "    filter->Render();\n" .
          "  }\n";
      }
    }
  }
  if ($filterName =~ /Writer$/ || $filterName =~ /Writer2$/ )
  {
    $filterType = "  filter->Write();\n";
  }
  $content =~ s/\@RENDER_WINDOW\@/$filterType/g;
  $filterType = "";
  if ($filterName =~ /RenderWindowInteractor$/)
  {
    $filterType = setupInitialize($filterName);
  }
  $content =~ s/\@RENDER_WINDOW_INTERACTOR\@/$filterType/g;
  
  
  print OUTFILE $content;
  close OUTFILE;
}

# Returns the Simulink datatype corresponding to a given C++ datatype
# Returns empty string for unrecognized C++ datatypes
sub simulinkDatatype {
  my $cppType = shift;
  switch ($cppType) {
  case "float" { return "SS_SINGLE"; }
  case "char" { return "SS_INT8"; }
  case "unsigned char" { return "SS_UINT8"; }
  case "short" { return "SS_INT16"; }
  case "unsigned short" { return "SS_UINT16"; }
  case "double" { return "SS_DOUBLE"; }
  case "int" { return "SS_INT32"; }
  case "long" { return "SS_INT32"; }
  case "unsigned int" { return "SS_UINT32"; }
  case "unsigned long" { return "SS_UINT32"; }
  case "bool" { return "SS_BOOLEAN"; }
  else { return ""; }
  }
}

# Returns the Simulink datatype index corresponding to a given C++ datatype
# Returns empty string for unrecognized C++ datatypes
sub simulinkDatatypeIndex {
  my $simType = simulinkDatatype(shift);
  switch ($simType) {
  case "SS_DOUBLE" { return "0"; }
  case "SS_SINGLE" { return "1"; }
  case "SS_INT8" { return "2"; }
  case "SS_UINT8" { return "3"; }
  case "SS_INT16" { return "4"; }
  case "SS_UINT16" { return "5"; }
  case "SS_INT32" { return "6"; }
  case "SS_UINT32" { return "7"; }
  case "SS_BOOLEAN" { return "8"; }
  else { return ""; }
  }
}

##########################################################
#setupLinuxHeader
# string that will include necessary files for RenderWindowInteractor on Linux
##########################################################
sub setupLinuxHeader{
  my $string = "#include \"vtkXRenderWindowInteractor.h\"\n" .
               "#include \"vtkXOpenGLRenderWindow.h\"\n" .
               "#include <X11/X.h>\n";
  return $string;
}

##########################################################
#setupInteractorCallback
# string that will include necessary additions for RenderWindowInteractor
# so that closing the window will stop the model
##########################################################
sub setupInteractorCallback{
  my $string =
  "#include \"vtkCommand.h\"\n" .
  "\n" .
  "class vtkCloseWindowCallback : public vtkCommand\n" .
  "{\n" .
  "public:\n" .
  "  static vtkCloseWindowCallback *New()\n" .
  "    {\n" .
  "    vtkCloseWindowCallback *obj = new vtkCloseWindowCallback;\n" .
  "    //ssPrintf(\"Created Callback\\n\");\n" .
  "    return obj;\n" .
  "    }\n" .
  "\n" .
  "  virtual void Execute(vtkObject *caller, unsigned long eventId, void *)\n" .
  "    {\n" .
  "    //ssPrintf(\"Closed Window\\n\");\n" .
  "    if (caller->IsA(\"vtkRenderWindowInteractor\") &&\n" .
  "        eventId == vtkCommand::ExitEvent)\n" .
  "      {\n" .
  "      // stop the simulation\n" .
  "      ssSetStopRequested(this->S, 1);\n" .
  "      }\n" .
  "    }\n" .
  "\n" .
  "  void SetSimStruct(SimStruct *simStruct)\n" .
  "    {\n" .
  "    this->S = simStruct;\n" .
  "    }\n" .
  "\n" .
  "private:\n" .
  "  SimStruct *S;\n" .
  "};\n\n";
  
  return $string;
}

##########################################################
#setupInteractorObserver
# string that will include necessary additions for RenderWindowInteractor
# so that closing the window will stop the model
##########################################################
sub setupInteractorObserver{
  my $string = "";

  $string = 
  "  vtkCloseWindowCallback *closeCallback = vtkCloseWindowCallback::New();\n" .
  "  closeCallback->SetSimStruct(S);\n" .
  "  filter->AddObserver(vtkCommand::ExitEvent, closeCallback);\n" .
  "  closeCallback->Delete();\n";

  return $string;
}

##########################################################
#setupAlgorithmInitializeSizesString
# string that will get number of input and output types of a vtkObject
# related to input and output ports
##########################################################
sub setupAlgorithmInitializeSizesString{
  my $filterHash = shift;
  my $string = "";
  
  my $filterName = $filterHash->{"Filter_Name"};
  
  $string = $string . "  " . $filterName . " *temporary = " .
    $filterName . "::New();\n" .
    "  nRealInputPorts += temporary->GetNumberOfInputPorts();\n" .
    "  nOutputPorts += temporary->GetNumberOfOutputPorts();\n" .
    "  for (i = 0; i < nRealInputPorts; i++)\n" . 
    "    {\n" .
    "    if (temporary->GetInputPortInformation(i)->\n" .
    "       Get(vtkAlgorithm::INPUT_IS_OPTIONAL()))\n" .
    "      {\n" .
    "      nRealInputPorts = i;\n" .
    "      break;\n" .
    "      }\n" .
    "    }\n" .
    "  temporary->Delete();\n" ;

  return $string;
}


##########################################################
#setupAlgorithmStartInputString
# string that will be used to set up input ports of algorithm
##########################################################
sub setupAlgorithmStartInputString{
  my $string = "";
  
  $string = $string . "  vtkAlgorithmOutput **nextInput;\n" . 
    "  for (i = 0; i <filter->GetNumberOfInputPorts() &&" .
    " ssGetInputPortConnected(S, i); i++)\n" .
    "  {\n" .
    "    void *point = const_cast<void*>(ssGetInputPortSignal(S,i));\n" .
    "    nextInput = reinterpret_cast<vtkAlgorithmOutput**>(point);\n" .
    "    filter->SetInputConnection(i, nextInput[0]);\n" .
    "  }\n";
    
  return $string;
}

##########################################################
#setupAlgorithmStartOutputString
# string that will be used to set up output ports of algorithm
##########################################################
sub setupAlgorithmStartOutputString{
  my $string = "";
  
  $string = $string . "  for (i = 0; i <filter->GetNumberOfOutputPorts()" .
    " && ssGetOutputPortConnected(S, outputPortIndex); i++)\n" .
    "  {\n" .
    "    vtkAlgorithmOutput **OutputPort;\n" .
    "    OutputPort = reinterpret_cast<vtkAlgorithmOutput**>" .
    "(ssGetOutputPortSignal(S,outputPortIndex));\n" .
    "    OutputPort[0] =  filter->GetOutputPort(i);\n" .
    "    outputPortIndex++;\n" .
    "  }\n" ;
    
  return $string;
}

##########################################################
#setupAlgorithmUpdateInputString
# string that will be used to set update input port number in MDL outputs
##########################################################
sub setupAlgorithmUpdateInputString{
  my $string = "";
  
  $string = $string .
    "  inputPortIndex += filter->GetNumberOfInputPorts();\n" ;
    
  return $string;
}

##########################################################
#setupAlgorithmUpdateOutputString
# string that will be used to set update output port number in MDL Outputs
##########################################################
sub setupAlgorithmUpdateOutputString{
  my $string = "";
  
  $string = $string .
    "  outputPortIndex += filter->GetNumberOfOutputPorts();\n" ;
    
  return $string;
}

##########################################################
#setupParameterSizeHash
# will list the start position for the doublet of (indicator,  parameter)
# in the S-function  parameter list.  (so if need  indicator will return
# that value,  and if want parameter location must add 1 to the stored value).
# Stores the parameters with common size in an array in a hash.
##########################################################
sub setupParameterSizeHash{
  my ($filterHash, $numInputs, $sizesHash) = @_;
  my $count = $numInputs;
  my $dynamic = "#undef";
  
  foreach my $param (@{$filterHash->{"Filter_Parameters"}} )
    {
    # one of Set, Get, or Both (may change to Indexed if is an
    # indexed function)
    my $paramFlag = $param->{"Parameter_Flag"};
    my $paramSizeTotal = $param->{"Parameter_Size"};
    my @paramSizes = split(/,/, $paramSizeTotal);
    # used to know if at second item in a list of 2 (ie. for functions that
    # used an index and a value want to only know the size of the value
    # since index is always 1)
    my $location = 0;
    foreach my $paramSize (@paramSizes)
      {
      # value will be the number stored in the XML and $arrayCheck
      # will be either '*' if is an array, or empty if not
      my ($value, $arrayCheck) = ($paramSize =~ /(\w*)(\*$|)/);
      # add size to the hash if is the only item (for most functions)
      # or the second item (for functions that take an index as the first item)
      if (@paramSizes == 1 || $location == 1)
      {
      # $array stores the size as an int with the * for array removed
      push (@{$sizesHash->{$value}},
            {"Count", $count, "Designation", $paramFlag});
      }
      $location++;
      # will be indexed type if XML gave 2 values in the parameter_type
      # and parameter_size tags
      $paramFlag = "Indexed";
      $dynamic = "#define" if (($value eq "N"));
      }
    $count += 2;
    }
  return $dynamic;
  }

##########################################################
#setupParameterTypeHash
# will list the start position for the doublet of (indicator, parameter)
# in the S-function parameter list.  (so if need indicator will return
# that value, and if want parameter location must add 1 to the stored value.)
# Stores the parameters with common data type in an array in a hash.
# typesHash will hold a hash based on types as keys, where each points to
# an array containing hashes of Type (ex. double, int, float)
# and Designation ( indexed, get,  set, or both)
##########################################################
sub setupParameterTypeHash{
  my ($filterHash, $numInputs, $typesHash) = @_;
  my $count = $numInputs;
  
  foreach my $param (@{$filterHash->{"Filter_Parameters"}} )
  {
    # one of Set, Get, or Both (may change to Indexed if is an
    # indexed function)
    my $paramFlag = $param->{"Parameter_Flag"};
    my $paramTypeTotal = $param->{"Parameter_Type"};
    my @paramTypes = split(/,/, $paramTypeTotal);
    # used to know if at second item in a list of 2 (ie. for functions
    # that used an index and a value want to only know the type of the
    # value since index is always int)
    my $location = 0;
    foreach my $paramType (@paramTypes)
    {
      if (@paramTypes == 1 || $location == 1)
      {
        # add type to the hash if is the only item (for most functions)
        # or the second item (for functions that take an index as the
        # first item)
        push (@{$typesHash->{$paramType}},
              {"Count", $count, "Designation", $paramFlag});
      }
      $location++;
      # only used in next loop so only if XML had 2 items in parameter_type
      # or parameter_size tag which would indicate was of the index function
      # variety
      $paramFlag = "Indexed";
    }
  $count += 2;
  }
}

##########################################################
#setupParameterFlagHash
# will list the start position for the doublet of (indicator, parameter)
# in the S-function parameter list.  (so if need indicator will return
# that value, and if want parameter location must add 1 to the stored value.)
# Stores the parameters with common usage (get/set/both/indexed) in an array
# in a hash.
# flagsHash will hold a hash based on flags as keys, where each points to
# an array containing hashes of the count location in the S-function dialog
# parameter box
##########################################################
sub setupParameterFlagHash{
  my ($filterHash, $numInputs, $flagsHash) = @_;
  my $count = $numInputs;
  
  foreach my $param (@{$filterHash->{"Filter_Parameters"}} )
  {
    # one of Set, Get, or Both (may change to Indexed if is an
    # indexed function)
    my $paramFlag = $param->{"Parameter_Flag"};
    my $paramTypeTotal = $param->{"Parameter_Type"};
    my @paramTypes = split(/,/, $paramTypeTotal);
    # used to know if at second item in a list of 2 (ie. for functions that
    # used an index and a value want to only know the type of the value since
    # index is always int)
    my $location = $#paramTypes;
    $paramFlag = "Indexed" if $location == 1;
    push (@{$flagsHash->{$paramFlag}}, {"Count", $count});
    $count += 2;
  }
}

##########################################################
# setupParameterInputCheckString
# Set up string for template to allow for the checking of inputs that must
# be added.  Will have a common setup that will vary based on the location
# in the popup menu of where As Input is located.  For indexed the setup
# will be quite different.  All will be done based on a Switch Case use.
# (grouped based on Parameter_Flag)
##########################################################
sub setupParameterInputCheckString {
  my ($filterHash, $flagsHash) = @_;
  my $string = "";
  my $casesStrings = "";
  
  $string .= "     switch(i) //divide items based on how can be used\n" .
    "      {\n";
  
  foreach my $flag (keys %$flagsHash)
  {
    # get will have no inputs so ignore and only do if actually have some
    # with that flag
    if ($flag ne "Get" && ((scalar @{$flagsHash->{$flag}}) > 0))
    {
      #make sure proper indentation 
      $casesStrings = $casesStrings . "      ";
      for (my $i = 0; $i < @{$flagsHash->{$flag}}; $i++)    
      {
        # make all the right cases for one flag
        $casesStrings .=
          "case " . ($flagsHash->{$flag}->[$i]->{"Count"}) . ": ";
      }
      #only add things that are not of the indexed format or are get only
      #(for similarity reasons)
      if ($flag ne "Indexed" )
      {
        $casesStrings .= "\n      ((int)mxGetScalar(ssGetSFcnParam(S,i)) == ";
        $casesStrings .= "2" if ($flag eq "Set");
        $casesStrings .= "2" if ($flag eq "Both");
        $casesStrings .= ") ? nPromotedInputPorts++ : nPromotedInputPorts;\n" .
          "      break;\n";
      }

      #now handle how the indexed functions have to add input numbers
      if ($flag eq "Indexed" )
      {
        $casesStrings .=
          "      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == 1) \n" .
          "      {\n" .
          "        nPromotedInputPorts += (static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i+1))));\n" .
          "      }\n" .
          "      break;\n";
      }
    }
  }
  
  # was no parameters so can leave it blank
  return $casesStrings if $casesStrings eq "";
  
  $string .= $casesStrings . "      }\n";
  
  return $string;
  
}

##########################################################
# setupParameterOutputCheckString
# Set up string for template to allow for the checking of outputs that must
# be added.  Will have a common setup that will vary based on the location
# in the popup menu of where As Output is located.  
# All will be done based on a Switch Case use.  (grouped based on
# Parameter_Flag).
# Only needed for get only and both flags.
##########################################################
sub setupParameterOutputCheckString {
  my ($filterHash, $flagsHash) = @_;
  my $string = "";
  my $casesStrings = "";
  
  $string .= "     switch(i) //divide items based on how can be used\n" .
    "      {\n";
  
  foreach my $flag (keys %$flagsHash)
  {
    # set and indexed will have no output so ignore
    if ($flag ne "Set" && $flag ne "Indexed" &&
        ((scalar @{$flagsHash->{$flag}}) > 0))
    {
      #make sure proper indentation 
      $casesStrings = $casesStrings . "      ";
      for (my $i = 0; $i < @{$flagsHash->{$flag}}; $i++)    
      {
        # make all the right cases for one flag
        $casesStrings .=
          "case " . ($flagsHash->{$flag}->[$i]->{"Count"}) . ": ";
      }
      $casesStrings .= "\n      ((int)mxGetScalar(ssGetSFcnParam(S,i)) == ";
      $casesStrings .= "4" if ($flag eq "Both");
      $casesStrings .= "1" if ($flag eq "Get");
      $casesStrings .=
        ") ? nPromotedOutputPorts++ : nPromotedOutputPorts; \n" .
        "      break;\n";
    }
  }
  
  # were no parameters so can leave it blank
  return $casesStrings if $casesStrings eq "";
  
  $string .= $casesStrings . "      }\n";
  
  return $string;
  
}

##########################################################
# setupInputArrayString
# Set up string for template to handle array dimensionality, and type for
# parameters that will be promoted inputs
# This will handle things that will be common for all templates and call
# functions to handle the specifics for each class
##########################################################
sub setupInputArrayString {
  my ($filterHash, $sizesHash, $typesHash, $flagsHash) = @_;
  my $string = "";
  my $casesStrings = "";
  my $extraString = "";
  
  $string = $string . "  for (i = ParameterListInputPortEndLocation; i < ParameterListOutputPortStartLocation" .
    " && InputPortIndex < ssGetNumInputPorts(S); i = i + 2) //because want to skip actual value\n" .
    "  {\n" .
    "    AsInputOutputCheck = 0;\n" .
    "    switch (i) \n" .
    "    {\n" ;
  foreach my $flag (keys %$flagsHash)
  {
    if ($flag ne "Get" && ((scalar @{$flagsHash->{$flag}}) > 0))
    {
      # get will have no input so ignore

      #make sure proper indentation 
      $casesStrings = $casesStrings . "      ";
      for (my $i = 0; $i < @{$flagsHash->{$flag}}; $i++)    
      {
        $casesStrings .= "case " . ($flagsHash->{$flag}->[$i]->{"Count"}) . ": "; # make all the right cases for one flag
      }
      $casesStrings .=
        "\n      if(static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == ";
      $casesStrings .= "2" if ($flag eq "Both");
      $casesStrings .= "2" if ($flag eq "Set");
      $casesStrings .= "1" if ($flag eq "Indexed");
      $casesStrings .= ") \n" .
        "      {\n" .
        "        AsInputOutputCheck = 1;\n" .
        "      }\n" .
        "      break;\n";
    }
  }
  
  if ($casesStrings ne "")
  {
    $casesStrings .= "    }\n" .
      "    if(AsInputOutputCheck == 1) \n" .
      "    {\n" ;
      
    $casesStrings .= setupInputArraySizesString($filterHash, $sizesHash);
    $casesStrings .= setupInputArrayTypesString($filterHash, $typesHash);
    
    $casesStrings .= "    }\n" ;
    
    $extraString =
      setupInputArrayForIndexedFunctionsString($filterHash, $sizesHash,
                                               $typesHash);
  }
  
  if ($extraString ne "")
  {
    $casesStrings .= "    if (AsInputOutputCheck == 1)\n" .
      "    {\n" . $extraString .
      "    }\n" ;
  }
  return $casesStrings if $casesStrings eq "";  
  $string .= $casesStrings . "  }\n";
  return $string;
}

##########################################################
# setupInputArraySizesString
#Set up array dimensionality for parameters that will be promoted inputs
##########################################################
sub setupInputArraySizesString {
  my ($filterHash, $sizesHash, $flagsHash) = @_;
  my $string = "";
  my $casesStrings = "";
  my $checker = 0;
  
  $string .=  "      switch(i) //divide items based on size of array\n" .
    "      {\n";
 
  foreach my $size (keys %$sizesHash)
  {
    $checker = 0;
    if (((scalar @{$sizesHash->{$size}}) > 0))
    {
      #make sure proper indentation 
      $casesStrings = $casesStrings . "      ";
      for (my $i = 0; $i < @{$sizesHash->{$size}}; $i++)    
      {
        #only add things that are not of the indexed format or are get only
        if ($sizesHash->{$size}->[$i]->{"Designation"} ne "Indexed" &&
            $sizesHash->{$size}->[$i]->{"Designation"} ne "Get")
        {
          $checker = 1;
          # make all the right cases for one size
          $casesStrings .=
            "case " . ($sizesHash->{$size}->[$i]->{"Count"}) . ": ";
        }
      }
      if ($checker)
      {
        $casesStrings = $casesStrings .
          "\n        ssSetInputPortWidth(S, InputPortIndex, ";

        if ($size == "N")
        {
          $casesStrings .= "DYNAMICALLY_SIZED";
        }
        else 
        {
          $casesStrings .= $size;
        }
        $casesStrings = $casesStrings . ");\n        break;\n";
      }
    }
  }
  return $casesStrings if $casesStrings eq "";
  $string .= $casesStrings . "      }\n";
  return $string;
}

##########################################################
# setupInputArrayTypesString
#Set up array type for parameters
##########################################################
sub setupInputArrayTypesString {
  my ($filterHash, $typesHash, $flagsHash) = @_;
  my $casesStrings = "";
  my $string = "";
  my $checker = 0;
  
  $string .= "      switch(i) // divide items based on type of input\n" .
  "      {\n";
  foreach my $type (keys %$typesHash)
  {
    $checker = 0;
    if (((scalar @{$typesHash->{$type}}) > 0))
    {
      #make sure proper indentation
      $casesStrings = $casesStrings . "      ";
      for (my $i = 0; $i < @{$typesHash->{$type}}; $i++)    
      {
        #only add things that are not of the indexed format
        if ($typesHash->{$type}->[$i]->{"Designation"} ne "Indexed" && $typesHash->{$type}->[$i]->{"Designation"} ne "Get")
        {
          $checker = 1;
          # make all the right cases for one size
          $casesStrings .= "case " . ($typesHash->{$type}->[$i]->{"Count"}) . ": ";
        }
      }
      #only print out the special part for the data type if a match was found
      if ($checker)
      {
        $casesStrings = $casesStrings . "\n        ssSetInputPortDataType(S, InputPortIndex, " . simulinkDatatype($type) . ");\n" .
          "        ssSetInputPortDirectFeedThrough(S, InputPortIndex, needsInput);\n" .
          "        ssSetInputPortRequiredContiguous(S, InputPortIndex, 1); //make all required contiguous\n" .
          "        InputPortIndex++;\n" .
          "        break;\n";
      }
    }
  }
  return $casesStrings if $casesStrings eq "";

  $string .= $casesStrings . "      }\n";
  return $string;
}

##########################################################
# setupInputArrayForIndexedFunctionsString
# Set up array dimensionality for parameters that will be promoted inputs
# that take a number of inputs to be determined by the user
# (ex. ContourFilter and SetValue(index, value)... each value will be its own
# input port and the index is entered in the dialog box which determines
# how many ports to add)
##########################################################
sub setupInputArrayForIndexedFunctionsString {
  my ($filterHash, $sizesHash, $typesHash, $flagsHash) = @_;
  my $casesStrings = "";
  # to know if there were any indexed functions at all
  my $indexedTotalCheck = 0;
  # to know if there were any indexed functions for a given size
  my $indexedKeyCheck = 0;
  
  #Handle the inputport sizes
  $casesStrings .= "      switch(i)\n" .
    "      {\n" ;
  foreach my $size (keys %$sizesHash)
  {
  
    $indexedKeyCheck = 0;
    $casesStrings = $casesStrings . "      "; #make sure proper indentation
    for (my $i = 0; $i < @{$sizesHash->{$size}}; $i++)
    {
      if ($sizesHash->{$size}->[$i]->{"Designation"} eq "Indexed")
      {
        $indexedTotalCheck = 1;
        $indexedKeyCheck = 1;
        $casesStrings .= "case " . ($sizesHash->{$size}->[$i]->{"Count"}) . ": ";
      }
    }
    if ($indexedKeyCheck == 1)
    {
      $casesStrings .= "          for (j = 0; j < static_cast<int>(mxGetScalar(ssGetSFcnParam(S, i+1))); j++)// will go through and add 1 input for each item user wants\n" .
        "          {\n" .
        "            ssSetInputPortWidth(S, InputPortIndex + j, " . $size . ");\n" .
        "          }\n" .
        "        break;\n";
    }
  }
  $casesStrings .= "      }\n"; # close off the switch/case
  
  #if went through the list and found no indexed functions then can
  #return with an empty string as nothing needs to be added to deal with them
  if ($indexedTotalCheck == 0)
  {
    return "";
  }
  
  #handle the input port types and flags
    $casesStrings .= "      switch(i)\n" .
      "      {\n" ;
  foreach my $type (keys %$typesHash)
  {
    $indexedKeyCheck = 0;
    #make sure proper indentation
    $casesStrings = $casesStrings . "      ";
    for (my $i = 0; $i < @{$typesHash->{$type}}; $i++)
    {
      if ($typesHash->{$type}->[$i]->{"Designation"} eq "Indexed")
      {
        $indexedKeyCheck = 1;
        $casesStrings .= "case " . ($typesHash->{$type}->[$i]->{"Count"}) . ": ";
      }
    }
    if ($indexedKeyCheck == 1)
    {
      $casesStrings .= "        for (j = 0; j < static_cast<int>(mxGetScalar(ssGetSFcnParam(S, i+1))); j++) // goes through and adds one for each input user wants\n" .
        "        {\n" .
        "          ssSetInputPortDataType(S, InputPortIndex + j, " . simulinkDatatype($type) . ");\n" .
        "          ssSetInputPortDirectFeedThrough(S, InputPortIndex + j, needsInput);\n" .
        "          ssSetInputPortRequiredContiguous(S, InputPortIndex + j, 1); // make all required contiguous\n" .
        "        }\n" .
        "        InputPortIndex += static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i+1)));\n" .
        "        break;\n";
    }
  }
  
  $casesStrings .= "      }\n";
  
  return $casesStrings;
}

##########################################################
# setupOutputArrayString
# Set up array dimensionality and type for parameters that will be promoted
# outputs
##########################################################
sub setupOutputArrayString {
  my ($filterHash, $sizesHash, $typesHash, $flagsHash) = @_;
  my $casesStrings = "";
  my $string = "";
  
  $string = $string . "  for (i = ParameterListInputPortEndLocation; i < ParameterListOutputPortStartLocation" .
    " && OutputPortIndex < ssGetNumOutputPorts(S); i = i + 2) //because want to skip actual value\n" .
    "  {\n" . 
    "    AsInputOutputCheck = 0;\n" .
    "    switch (i) \n" .
    "    {\n" ;
  foreach my $flag (keys %$flagsHash)
  {
    # set and indexed will have no outputs so ignore
    if ($flag ne "Set" && $flag ne "Indexed" &&
        ((scalar @{$flagsHash->{$flag}}) > 0))
    {
      #make sure proper indentation 
      $casesStrings = $casesStrings . "      ";
      for (my $i = 0; $i < @{$flagsHash->{$flag}}; $i++)    
      {
        # make all the right cases for one flag
        $casesStrings .= "case " . ($flagsHash->{$flag}->[$i]->{"Count"}) . ": ";
      }
      $casesStrings .= "\n      if(static_cast<int>(mxGetScalar(ssGetSFcnParam(S,i))) == ";
      $casesStrings .= "1" if ($flag eq "Get");
      $casesStrings .= "4" if ($flag eq "Both");
      $casesStrings .= ") \n" .
        "      {\n" .
        "        AsInputOutputCheck = 1;\n" .
        "      }\n" .
        "      break;\n";
    }
  }
  
  return $casesStrings if $casesStrings eq "";
    
  $string .= $casesStrings . "    }\n" .
    "    if(AsInputOutputCheck == 1) \n" .
    "    {\n" ;
    
  $string .= setupOutputArraySizesString($filterHash, $sizesHash);
  $string .= setupOutputArrayTypesString($filterHash, $typesHash);
  $string .= "      OutputPortIndex++;\n" .
    "    }\n" . 
    "  }\n";
  return $string;
}

##########################################################
# setupOutputArraySizesString
#Set up array dimensionality for parameters that will be promoted outputs
##########################################################
sub setupOutputArraySizesString {
  my ($filterHash, $sizesHash) = @_;
  my $casesStrings = "";
  my $string = "";
  my $checker = 0;
  
  $string .=  "      switch(i) //divide items based on size of array\n" .
    "      {\n";
  
  foreach my $size (keys %$sizesHash)
  {
    $checker = 0;
    if ((scalar @{$sizesHash->{$size}}) > 0)
    {
      $casesStrings = $casesStrings . "      "; #make sure proper indentation
      for (my $i = 0; $i < @{$sizesHash->{$size}}; $i++)    
      {
        #only add things that are not of the indexed format or Set only
        #functions
        if ($sizesHash->{$size}->[$i]->{"Designation"} ne "Indexed" && $sizesHash->{$size}->[$i]->{"Designation"} ne "Set")
        {
          $checker = 1;
          # make all the right cases for one size
          $casesStrings .= "case " . ($sizesHash->{$size}->[$i]->{"Count"}) . ": ";
        }
      }
      if ($checker)
      {
        $casesStrings = $casesStrings . "\n        ssSetOutputPortWidth(S, OutputPortIndex, ";
        if ($size == "N")
        {
          $casesStrings .= "DYNAMICALLY_SIZED";
        }
        else 
        {
          $casesStrings .= $size;
        }
        $casesStrings = $casesStrings . ");\n        break;\n";
      }
    }
  }
  
  return $casesStrings if $casesStrings eq "";
  $string .= $casesStrings . "      }\n";
  return $string;
}

##########################################################
# setupOutputArrayTypesString
#Set up array type for parameters that were promoted to outputs
##########################################################
sub setupOutputArrayTypesString {
  my ($filterHash, $typesHash) = @_;
  my $casesStrings = "";
  my $string = "";
  
  $string .= "      switch(i) // divide items based on type of input\n" .
  "      {\n";
  
  foreach my $type (keys %$typesHash)
  {
    if ((scalar @{$typesHash->{$type}}) > 0)
    {
      #make sure proper indentation
      $casesStrings = $casesStrings . "      ";
      for (my $i = 0; $i < @{$typesHash->{$type}}; $i++)    
      {
        #only add things that are not of the indexed format
        if ($typesHash->{$type}->[$i]->{"Designation"} ne "Indexed"
            && $typesHash->{$type}->[$i]->{"Designation"} ne "Set")
        {
          # make all the right cases for one size
          $casesStrings .= "case " . ($typesHash->{$type}->[$i]->{"Count"}) . ": ";
        }
      }
      $casesStrings = $casesStrings . "\n        ssSetOutputPortDataType(S, OutputPortIndex, " . simulinkDatatype($type) . ");\n";
      $casesStrings = $casesStrings . "        break;\n";
    }
  }
  
  return $casesStrings if $casesStrings eq "";
  $string .= $casesStrings . "      }\n" ;

  return $string;
}

###########################################################
# setupProcessInputString
# process the inputs of all input ports
###########################################################
sub setupProcessInputString{
  my ($filterHash, $index, $selfInputLocation) = @_;
  my $inputString = "";
  
  foreach my $input (@{$filterHash->{"Inputs"}})
  {
    my $inputFlags = $input->{"Input_Flags"};
    my $inputType = $input->{"Input_Type"};
    my $inputName = $input->{"Input_Name"};
    if ($inputName eq "Self"){
      $$selfInputLocation = $$index;
    }
    else {
      if ($inputFlags eq "Repeatable,Optional")
      {
        $inputString = $inputString . "      for (j = 0; j < static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $$index . "))) && ssGetInputPortConnected(S,inputPortIndex); j++)\n"
      }
      else 
      {
        $inputString = $inputString . "      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $$index . "))) == 1 && ssGetInputPortConnected(S, inputPortIndex))\n";
      }
      $inputString = $inputString . "        {\n" .
      "          void* point = const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex));\n" .
      "          vtkObject *o = reinterpret_cast<vtkObject **>(point)[0] ;\n" .
      "          int typeIsCorrect = o->IsA(\"" . $inputType . "\");\n";

      # if inputType ends in "Data", check for vtkAlgorithmOutput
      if ($inputType =~ /Data$/)
      {
      $inputString = $inputString .
      "          if (!typeIsCorrect && o->IsA(\"vtkAlgorithmOutput\"))\n" .
      "          {\n" .
      "            vtkAlgorithmOutput *ao = static_cast<vtkAlgorithmOutput *>(o);\n" .

      "            o = ao->GetProducer()->GetOutputDataObject(ao->GetIndex());\n" .
      "            typeIsCorrect = o->IsA(\"" . $inputType . "\");\n" .
      "          }\n";
      }

      $inputString = $inputString .
      "          if (typeIsCorrect)\n" .
      "          {\n" .
      "            filter->";
      if ($inputFlags eq "Repeatable,Optional")
      {
        $inputString .= "Add";
      }
      else 
      {
        $inputString .= "Set";
      }
      $inputString = $inputString . $inputName . "(reinterpret_cast<" . $inputType . "*>(o));\n" .
      "          }\n" .
      "          else\n" .
      "          {\n" .
      "            ssSetErrorStatus(S, \"Bad input type: needs " . $inputType . "\");\n" .
      "          }\n" .
      "          inputPortIndex++;\n" .
      "        }\n" ;
    }
    $$index++;
  }
  return $inputString;
}

#########################################################################
# setupProcessParameterStartString
# sets up the string for the parameters in the mdlStart Simulink function
# for those parameters that stay parameters
#########################################################################
sub setupProcessParameterStartString{
  my ($filterHash, $index) = @_;
  my $string = "";
  
  foreach my $param (@{$filterHash->{"Filter_Parameters"}})
  {
    my $paramName = $param->{"Parameter_Name"};
    my $paramFlag = $param->{"Parameter_Flag"};
    my $paramSizeTotal = $param->{"Parameter_Size"};
    my @paramSizes = split(/,/, $paramSizeTotal);

    #only want to add normal functions (so do not add indexed functions)

    # do not deal with indexed functions or get only functions in the
    # mdlStart section
    if (@paramSizes == 1 && $paramFlag ne "Get")
    {
      # only need the last item in array as if sizes is 2 know it is indexed
      # type and therefore to be ignored here

      # value will be the number stored in the XML and $arrayCheck will be
      # either '*' if is an array, or empty if not
      my ($paramSize, $arrayCheck) = ($paramSizes[$#paramSizes] =~ /(\w*)(\*$|)/);
      # since know must only be 1 type in the tag can use this instead of
      # having to split
      my $paramType = $param->{"Parameter_Type"};
      # if the function expects individual arguments, then this variable
      # will hold "Single"
      my $paramArray = "Single";
      
      if ($arrayCheck eq "*")
      {
        # if the function expects an array, then this variable will
        # indicate that by holding "Array"
        $paramArray = "Array";
      }
      
      # would need to change here if order of set and Both change
      $string .= "      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $$index . "))) == 1)\n" .
      "      {\n";
      if (($paramType =~ m/char/))
      {
        $string .= setupCharParameterStartString($paramName, $paramSize,
                                                 $paramType, $index);
      }
      else
      {
        $string .= setupNumericParameterStartString($paramName, $paramSize,
                                                    $paramArray, $paramType,
                                                    $index);
      }
      $string .= "      }\n" ;
    }
    # need to add 2 regardless of whether or not the parameter was used
    # here as still would have a location in the dialog box
    $$index = $$index + 2;
  }
  return $string;
}

##########################################################################
# setupNumericParameterStartString
# setup strings for all parameters that are of any numeric type (ie. not chars)
##########################################################################
sub setupNumericParameterStartString{
  my ($name, $size, $array, $type, $index) = @_;
  my $string = "";
  
  if ($size == 1) #is a function that takes a single scalar
  {
   $string .= "        filter->Set" . $name . "((" . $type . ")mxGetScalar(ssGetSFcnParam(S, " . $$index . " + 1)));\n";
  }
  else
  {
    $string .= "        double *ptr = mxGetPr(ssGetSFcnParam(S, " . $$index . " + 1));\n";
    
    if ($type ne "double")
    {
      $string .= "        " . $type . " param[" . $size . "];\n" .
        "        for (j = 0; j < " . $size . "; j++)\n" .
        "          {\n" .
        "          param[j] = static_cast<" . $type . ">(ptr[j]);\n" .
        "          }\n";
    }

    $string = $string . "        filter->Set" . $name . "(";
    if ($array eq "Single")
    {
      #is a function expecting input with multiple values given as
      # individual arguments
      for (my $i = 0; $i < $size; $i++)
      {
        if ($type eq "double")
        {
          $string .= " ptr[" . $i . "],";
        }
        else 
        {
          $string .= " param[" . $i . "],";
        }
      }
      chop( $string); #removes the last ',' 
    }
    else #is expecting an array
    {
      if ($type eq "double")
      {
        $string .= "ptr";
      }
      else 
      {
        $string .= "param";
      }
    }
    $string .= ");\n";
  }
  return $string;
}


##########################################################################
# setupCharParameterStartString
# setup all inputs that must be of type char*
##########################################################################
sub setupCharParameterStartString{
  
  my ($name, $size, $type, $index) = @_;
  my $string = "";
  
  if ($size != 1)
  {
    $string = $string .
    "        " . $type . " stackspace[128];\n" .
    "        " . $type . " *stringbuf = stackspace;\n" .
    "        int buflen = mxGetN((ssGetSFcnParam(S, " . $$index ."+1)))+1;\n" .
    "        if (buflen > 128) {\n" .
    "          // use malloc for oversize strings\n" .
    "          stringbuf = reinterpret_cast<" . $type . " *>(mxMalloc(buflen));\n" .
    "        }\n" .
    "        mxGetString((ssGetSFcnParam(S, " . $$index . "+1)), reinterpret_cast<char*>(stringbuf), buflen);\n" .
    "        filter->Set" . $name . "(stringbuf); // wanted as parameter\n" .
    "        if (buflen > 128) {\n" .
    "          mxFree(stringbuf);\n" .
    "        }\n";
  }
  else 
  {
    $string = $string .
    "        " . $type . " stringbuf = static_cast<" . $type . ">((mxGetChars(ssGetSFcnParam(S," . $$index . "+1)))[0]);\n" .
    "        filter->Set". $name . "(stringbuf); //wanted as parameter\n" ;
  }
  return $string;
}

###########################################################
# setupProcessOutputString
# process the inputs of all input ports
###########################################################
sub setupProcessOutputString{
  my ($filterHash, $index) = @_;
  my $outputString = "";
  
  my $filterName = $filterHash->{"Filter_Name"};
  
  foreach my $output (@{$filterHash->{"Outputs"}})
  {
    my $outputType = $output->{"Output_Type"};
    my $outputName = $output->{"Output_Name"};
    $outputString = $outputString .
    "      if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $$index . "))) == 1)\n";
    $outputString = $outputString . "      {\n" .
    "        " . $outputType . " **OutputPort;\n" .
    "        OutputPort = reinterpret_cast<" . $outputType . "**>(ssGetOutputPortSignal(S, outputPortIndex));\n" .
    "        OutputPort[0] = filter";
    if ($outputName eq "Self")
    {
      $outputString .= ";\n";
    }
    else 
    {
      $outputString = $outputString . "->Get" . $outputName . "();\n";
    }
    $outputString = $outputString .
    "        outputPortIndex++;\n" .
    "      }\n" ;
    $$index++;
  }
  return $outputString;
}

#########################################################################
# setupProcessParameterOutputString
# the string to be used in mdlOutput that will allow any parameters
# that are being used as inputs to change throughout the simulation
#########################################################################
sub setupProcessParameterOutputString{
  my $filterHash = shift;
  my $string = "";
  my $index = 0;
  $index = scalar @{$filterHash->{"Inputs"}} if $filterHash->{"Inputs"};

  foreach my $param (@{$filterHash->{"Filter_Parameters"}})
  {
    my $paramName = $param->{"Parameter_Name"};
    my $paramFlag = $param->{"Parameter_Flag"};
    my $paramSizeTotal = $param->{"Parameter_Size"};
    my @paramSizes = split(/,/, $paramSizeTotal);
    if (@paramSizes == 2)
    {
      $paramFlag = "Indexed";
    }
    # only need to know the values of the last item in the array as it
    # will either be the only 1 (for most) or the non-index value for
    # indexed functions

    # value will be the number stored in the XML and $arrayCheck will be
    # either '*' if is an array, or empty if not
    my ($paramSize, $arrayCheck) =
        ($paramSizes[$#paramSizes] =~ /(\w*)(\*$|)/);
    my $paramArrayOrSingles = "Single";
    if ($arrayCheck eq "*")
    {
      $paramArrayOrSingles = "Array";
    }
    my $paramTypeTotal = $param->{"Parameter_Type"};
    #array of 1 item for most, but 2 for indexed (with first item
    # being 'int' and second being something else)
    my @paramTypes = split(/,/, $paramTypeTotal);
    my $paramType = $paramTypes[$#paramTypes];

    if (!($paramType =~ m/char/))
    {
      $string = $string . setupProcessParameterOutputNumericString($paramName, $paramType, $paramArrayOrSingles, $paramSize, $index, $paramFlag);
    }
    else 
    {
      $string = $string . setupProcessParameterOutputCharString($paramName, $paramType, $paramSize, $index, $paramFlag);
    }
    
    #always add 2 regardless of how it is treated as will always have 2
    #spots saved for each parameter (even if the second one is only a
    #placeholder so that the rest of the code does not have to be modified
    #completely
    $index = $index + 2; 
  }
  return $string;
}


##########################################################################
# setupProcessParameterOutputNumericString
# setup the string that will handle the case that a numeric parameter is
# promoted to be an input or output in mdlOutputs
##########################################################################
sub setupProcessParameterOutputNumericString{
  my ($paramName, $paramType, $paramArray, $paramSize, $index, $paramFlag) = @_;
  my $string = "";
  
  if ($paramFlag ne "Get") # all functions that are not just gets should be set somehow
  {
    $string .= setupProcessParameterOutputNumericSetString($paramName, $paramType, $paramArray, $paramSize, $index, $paramFlag);
  }
  if ($paramFlag ne "Set" && $paramFlag ne "Indexed") # all functions that are not just set should be gettable
  {
    $string .= setupProcessParameterOutputNumericGetString($paramName, $paramType, $paramArray, $paramSize, $index, $paramFlag);
  }
  return $string;
  
}

##########################################################################
# setupProcessParameterOutputNumericSetString
# setup the string that will handle the case that a numeric parameter
# is promoted to be an input in mdlOutputs
##########################################################################
sub setupProcessParameterOutputNumericSetString{
  my ($paramName, $paramType, $paramArray, $paramSize, $index, $paramFlag) = @_;
  my $string = "";
  
  $string = $string .
  "    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $index . "))) == ";
  $string .= "2" if ($paramFlag eq "Set");
  $string .= "2" if ($paramFlag eq "Both");
  $string .= "1" if ($paramFlag eq "Indexed");
  $string .= ") // wanted as input\n" .
  "    {\n";
  if ($paramFlag eq "Indexed")
  {
    $string .= "      for (k = 0; k < static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $index . "+1))); k++)\n" .
    "      {\n" ;
  }
  if ($paramSize != 1 && $paramArray eq "Single") #for the functions where input is expected as to be inputted as individual values into VTK
  {
    $string = $string .
    "      " . $paramType . " *arr = (reinterpret_cast<" . $paramType . "*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))));\n";
  }
  $string .=  "      filter->Set" . $paramName . "(";
  if ($paramFlag eq "Indexed")
  {
    $string .= "k, ";
  }
  if ($paramSize != 1 && $paramArray eq "Single")
  {
    for (my $i = 0; $i < $paramSize; $i++)
    {
      $string .= " arr[" . $i . "],";
    }
    chop($string); #removes the last ',' 
    $string .= ");\n";
  }
  else #for non-arrays and functions that are expected to be passed arrays
  {
    $string .= "(reinterpret_cast<" . $paramType . "*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex))))" ;
    if ($paramSize == 1 ) #if is a non-array can deal with by taking first element of Simulink's returned array
    { 
      $string .= "[0]";
    }
    $string .= ");\n";
  }
  $string = $string . "      inputPortIndex++;\n" ;
  if ($paramFlag eq "Indexed")
  {
    $string .= "    }\n";
  }
  $string .=  "    }\n" ;
  return $string;
} 

##########################################################################
# setupProcessParameterOutputNumericGetString
# setup the string that will handle the case that a numeric parameter
# is promoted to be an output in mdlOutputs
##########################################################################
sub setupProcessParameterOutputNumericGetString{
  my ($paramName, $paramType, $paramArray, $paramSize, $index, $paramFlag) = @_;
  my $string = "";
  
  $string = $string . "    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $index ."))) == ";
  $string .= "4" if ($paramFlag eq "Both");
  $string .= "1" if ($paramFlag eq "Get");
  $string .= ") // wanted as output\n" .
    "    {\n" .
    "      " . $paramType . " ";
  if ($paramSize != 1)
  {
    $string .= "*"; 
  }
  $string = $string . "parameter;\n" .
    "      parameter = filter->Get" . $paramName . "();\n" .
    "      " . $paramType . " *outputValue = reinterpret_cast<" . $paramType . "*>(ssGetOutputPortSignal(S, outputPortIndex));\n" ;
  if ($paramSize == 1)
  {
    $string = $string . "      outputValue[0] = parameter;\n";
  }
  else 
  {
    $string = $string . "      for (j = 0; j < " . $paramSize . "; j++){\n" .
    "        outputValue[j] = parameter[j];\n" .
    "      }\n";
  }
  $string = $string . "      outputPortIndex++;\n" .
  "    }\n" ;
    
  return $string;
}


##########################################################################
# setupProcessParameterOutputCharString
# setup the string that will handle the case that a char parameter is
# promoted to be an input
# Newly added... not tested... should fix so not so much repetitiveness
# going on
##########################################################################
sub setupProcessParameterOutputCharString{
  my ($paramName, $paramType, $paramSize, $index, $paramFlag) = @_;
  my $string = "";
  
  if ($paramSize != 1)
  {
    if ($paramFlag ne "Get")
    {
      $string = $string . "    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $index . "))) == ";
    $string .= "2" if ($paramFlag eq "Set");
    $string .= "2" if ($paramFlag eq "Both");
    $string .= "1" if ($paramFlag eq "Indexed");
    $string .= ") // wanted as input\n" .
        "    {\n" . 
        "      " . $paramType . " **pointer = reinterpret_cast<" . $paramType . "**>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex)));\n" .
        "      filter->Set" . $paramName . "(pointer[0]);\n" .
        "      inputPortIndex++;\n" .
        "    }\n" ;
    }
    if ($paramFlag ne "Set")
    {
      $string = $string . "    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $index . "))) == ";
      $string .= "4" if ($paramFlag eq "Both");
      $string .= "1" if ($paramFlag eq "Get");
      $string .= ") // wanted as output\n" .
        "    {\n" .
        "      " . $paramType . " *parameter;\n" .
        "      parameter = (" . $paramType . "*)( filter->Get" . $paramName . "() );\n" .
        "      " . $paramType . " **outputValue = reinterpret_cast<" . $paramType . " **>(ssGetOutputPortSignal(S, outputPortIndex));\n" .
        "      outputValue[0] = parameter;\n" .
        "      outputPortIndex++;\n" .
        "    }\n" ;
    }
  }
  else
  {
    if ($paramFlag ne "Get")
    {
      $string = $string . "    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $index . "))) == ";
      $string .= "2" if ($paramFlag eq "Set");
      $string .= "2" if ($paramFlag eq "Both");
      $string .= "1" if ($paramFlag eq "Indexed");
      $string .= ") // wanted as input\n" .
        "    {\n" . 
        "      " . $paramType . " *pointer = reinterpret_cast<" . $paramType . "*>(const_cast<void*>(ssGetInputPortSignal(S, inputPortIndex)));\n" .
        "      filter->Set" . $paramName . "(pointer[0]);\n" .
        "        inputPortIndex++;\n" .
        "    }\n" ;
    }
    if ($paramFlag ne "Set")
    {
      $string = $string . "    if (static_cast<int>(mxGetScalar(ssGetSFcnParam(S," . $index . "))) == ";
      $string .= "4" if ($paramFlag eq "Both");
      $string .= "1" if ($paramFlag eq "Get");
      $string .= ") // wanted as output\n" .
        "    {\n" .
        "      " . $paramType . " parameter;\n" .
        "      parameter = filter->Get" . $paramName . "();\n" .
        "      " . $paramType . " *outputValue = reinterpret_cast<" . $paramType . "*>(ssGetOutputPortSignal(S, outputPortIndex));\n" .
        "      outputValue[0] = parameter;\n" .
        "      outputPortIndex++;\n" .
        "    }\n";
    }
  }
  return $string;
}
 
#########################################################################
# setupInitialize
# the string to be used in mdlOutput that will allow interactors to be
# initialized (for either windows or linux)
#########################################################################
sub setupInitialize{
  my $filterName = shift;
  my $string = "";
  
  if ($^O eq "linux")
  {
    $string .=
      "  filter->Initialize();\n" .
      "  vtkXRenderWindowInteractor *iren =\n" .
      "    vtkXRenderWindowInteractor::SafeDownCast(filter);\n" .
      "  XtAppContext app = iren->GetApp();\n" .
      "  XEvent event;\n" .
      "  if (XtAppPending(app))\n" .
      "  {\n" .
      "    int stopSimulation = 0;\n" .
      "\n" .
      "    XtAppNextEvent(app, &event);\n" .
      "\n" .
      "    // Check for window close or other termination event\n" .
      "    if (event.type == ClientMessage)\n" .
      "    {\n" .
      "      vtkXOpenGLRenderWindow *renwin =\n" .
      "        vtkXOpenGLRenderWindow::SafeDownCast(iren->GetRenderWindow());\n" .
      "      Display *displayId = renwin->GetDisplayId();\n" .
      "      char *name = XGetAtomName(displayId, event.xclient.data.l[0]);\n" .
      "      stopSimulation = (strcmp(name, \"WM_DELETE_WINDOW\") == 0 ||\n" .
      "                        strcmp(name, \"VTK_BreakXtLoop\") == 0);\n" .
      "      XFree(name);\n" .
      "    }\n" .
      "\n" .
      "    if (stopSimulation)\n" .
      "    {\n" .
      "      ssSetStopRequested(S, 1);\n" .
      "    }\n" .
      "    else\n" .
      "    {\n" .
      "      XtDispatchEvent(&event);\n" .
      "    }\n" .
      "  }\n" .
      "  else\n" .
      "  {\n" .
      "    filter->Render();\n" .
      "  }\n";
  }
  else
  {
    $string .=  
      "  filter->Initialize();\n" .
      "  filter->Render();\n";
  }

  return $string;
}
