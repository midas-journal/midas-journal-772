package vtkCombineSuperclasses;


# =================
# Copyright (c) Queen's University
# All rights reserved.

# See Copyright.txt for more details.
# =================

###############################################
# SIMVTK 
# Adam Campigotto
# July 7, 2008
#
# vtkCombineSuperclasses.pm
#
###############################################

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(vtkCombineSuperclasses);

##########################################################
# vtkCombineSuperclasses subroutine
# Updates XML Filter node (ie. it will contain all info on superclass inputs,
# parameters, and outputs by recursively adding the super class data to the
# hash). 
#
# Input: 1. reference to %filterHash
#        2. Name of class file
#        3. directory where the xml files are located
#        4. one of 0, 1, or 2, with 0 meaning add the superclass functions
#           to the hash (for when making the s-functions, and callbacks)
#           or 1 meaning to not add the superclass functions (used in Default
#           value generating, so only have default values for its own
#           functions but can still get information about being vtkAlgorithm
#           or not) and 2 meaning to add the current class' functions to the
#           hash but none others (for the first class called for getting
#           default values)
# Returns: updated filter node
##########################################################
sub vtkCombineSuperclasses {

  my ($filterHash, $xmlFile, $sourceDirectory, $addSuperclassFunctions) = @_;

  #all should have XML that need it, as all (?) classes that are superclasses
  #of another or are wrapped themselves should have had an XML made (but just
  #warn if not as not really a serious problem but would be nice to know if
  #class is not wrapped or not found for some reason.)
  warn "ERROR: " . $xmlFile . " file not found"
    unless -f $sourceDirectory . "/" . $xmlFile;
  my $isvtkAlgorithm = 0;
  if (-f $sourceDirectory . "/" . $xmlFile) 
  {
    # Read the input file and create an XML DOM data structure
    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parsefile ($sourceDirectory . "/" . $xmlFile);

    my $filtersNodeList = $doc->getElementsByTagName("Filter");
    my $filterNode = $filtersNodeList->item (0);
    
    my $superClass = findSuperClass($filterNode);
    
    if ($superClass eq "vtkAlgorithm")
    {
      $isvtkAlgorithm = 1;
    }
    
    if ($addSuperclassFunctions != 1)
    {
      addInputs($filterNode, $filterHash);
      if ( !addFilterParameters($filterNode, $filterHash) ) 
      {
        die "ERROR: Invalid Filter_Parameter element found for filter " . 
          $xmlFile; 
      }
      addOutputs($filterNode, $filterHash);  
    }
    
    #if is used in default, here will make it so that only add the first
    #class' functions to the hash
    if ($addSuperclassFunctions == 2)
    {
      $addSuperclassFunctions = 1;
    }
    
    if ($superClass ne "" &&
        $superClass ne "vtkObject" &&
        $superClass ne "vtkAlgorithm")
    {
      $isvtkAlgorithm = vtkCombineSuperclasses($filterHash,
                                               "$superClass.xml",
                                               $sourceDirectory,
                                               $addSuperclassFunctions);
    }
      
    $doc->dispose;
  }
  return $isvtkAlgorithm;
}

##########################################################
# findSuperClass
# Extracts the filter's superclass
# Input: 1. an XML::DOM::NodeList
#          2. reference to %filterHash
# Returns: Empty string if a Super_Class element is not found
#              Else name of superclass
#
##########################################################
sub findSuperClass {

  my ($filterNode) = @_;
  if ($filterNode->getElementsByTagName("Super_Class")->getLength <= 0) {
    return "";
  }
  return $filterNode->getElementsByTagName("Super_Class")->item(0)->
      getFirstChild->getNodeValue;
}

##########################################################
# addInputs
# Extracts the Inputs for the filter and stores them as
# an array of hashes in %filterHash
#
# Input:   1. an XML::DOM::NodeList
#          2. reference to %filterHash
# Returns: False if no Input element is found or an input has no Input_Name,
#          input_Flags or Input_Type
#          Else true
##########################################################
sub addInputs {

  my ($filterNode, $filterHash) = @_;

  my $numInputs = $filterNode->getElementsByTagName("Input")->getLength;
  if ($numInputs < 0) {
    return 0;
  }

  my $inputNodes = $filterNode->getElementsByTagName("Input");
  my $numberPreviousInputs =  ($#{$filterHash->{"Inputs"}} + 1);
  for (my $i=0; $i < $numInputs; $i++) {
    my $inputNames = $inputNodes->item($i)->getElementsByTagName("Input_Name");
    if ($inputNames->getLength < 0) {
      return 0;
    }

    $filterHash->{"Inputs"}->[$i + $numberPreviousInputs]->{"Input_Name"} =
      $inputNames->item(0)->getFirstChild->getNodeValue;

    # Set input type and flags
    if ($inputNodes->item($i)->getElementsByTagName("Input_Type")->getLength
        > 0)
    {
      $filterHash->{"Inputs"}->[$i + $numberPreviousInputs]->{"Input_Type"} =
        $inputNodes->item($i)->getElementsByTagName("Input_Type")->
        item(0)->getFirstChild->getNodeValue;
    }
    else
    {
      # there is no Input_Type specified
      return 0;
    }
    if ($inputNodes->item($i)->getElementsByTagName("Input_Flags")->getLength
        > 0)
    {
      $filterHash->{"Inputs"}->[$i + $numberPreviousInputs]->{"Input_Flags"} =
        $inputNodes->item($i)->getElementsByTagName("Input_Flags")->item(0)->
        getFirstChild->getNodeValue;
    }
    else
    {
      # there is no Input_Flags specified
      return 0;
    }
  }
  if ($numberPreviousInputs == 0){
    #set up an input for self if is the base class (all really need
    #is the name)
    $filterHash->{"Inputs"}->[$numInputs]->{"Input_Name"} = "Self";
    $filterHash->{"Inputs"}->[$numInputs]->{"Input_Flags"} = "Optional";
  }
  return $numInputs;
}

##########################################################
# addFilterParameters
# Extracts the Filter_Parameters for the filter and stores 
# them as an array of hashes in %filterHash
#
# Input:   1. an XML::DOM::NodeList
#          2. reference to %filterHash
# Returns: False if a parameter does not have a Parameter_Name, Parameter_Type
#          and Parameter_Size
#          Else true
##########################################################
sub addFilterParameters {

  my ($filterNode, $filterHash) = @_;

  if ($filterNode->getElementsByTagName("Filter_Parameters")->getLength > 0) {
    my $parameterNodes =
      $filterNode->getElementsByTagName("Filter_Parameters")->item(0)->
      getElementsByTagName("Parameter");
    my $numParameters = $parameterNodes->getLength;

    # Get the number of Parameters hash already has so easy to add to end
    my $numberPreviousParameters =
      ($#{$filterHash->{"Filter_Parameters"}} + 1);
    
  # Process each parameter in turn
    for (my $i=0; $i < $numParameters; $i++) {

      # Set Parameter_Name
      my $parameterNames =
        $parameterNodes->item($i)->getElementsByTagName("Parameter_Name");

      if ($parameterNames->getLength <= 0) {
        return 0;
      }
      $filterHash->{"Filter_Parameters"}->
        [$i + $numberPreviousParameters]->{"Parameter_Name"} =
        $parameterNames->item(0)->getFirstChild->getNodeValue;

      # Set Parameter_Type
      my $parameterTypes =
        $parameterNodes->item($i)->getElementsByTagName("Parameter_Type");
      if ($parameterTypes->getLength <= 0) {
        return 0;
      }
      $filterHash->{"Filter_Parameters"}->
        [$i + $numberPreviousParameters]->{"Parameter_Type"} =
        $parameterTypes->item(0)->getFirstChild->getNodeValue;
      
      # Set Parameter_Size
      my $parameterSizes =
        $parameterNodes->item($i)->getElementsByTagName("Parameter_Size");
      if ($parameterSizes->getLength <= 0) {
        return 0;
      }
      $filterHash->{"Filter_Parameters"}->
        [$i + $numberPreviousParameters]->{"Parameter_Size"} =
        $parameterSizes->item(0)->getFirstChild->getNodeValue;
        
      # Set Parameter_Flag
      my $parameterFlags =
        $parameterNodes->item($i)->getElementsByTagName("Parameter_Flag");
      if ($parameterFlags->getLength <= 0) {
        return 0;
      }
      $filterHash->{"Filter_Parameters"}->
        [$i + $numberPreviousParameters]->{"Parameter_Flag"} =
        $parameterFlags->item(0)->getFirstChild->getNodeValue;
    }
  }
  return 1;
}

##########################################################
# addOutputs
# Extracts the Outputs for the filter and stores them as
# an array of hashes in %filterHash
#
# Input: 1. an XML::DOM::NodeList
#        2. reference to %filterHash
# Returns: False if no Output element is found or an output has no
#            Output_Name or Output_Type
#          Else true
##########################################################
sub addOutputs {

  my ($filterNode, $filterHash) = @_;

  my $numOutputs = $filterNode->getElementsByTagName("Output")->getLength;
  if ($numOutputs < 0) {
    return 0;
  }
  
  # Get the number of Outputs the hash has originally 
  my $numberPreviousOutputs = ($#{$filterHash->{"Outputs"}} + 1);
  my $outputNodes = $filterNode->getElementsByTagName("Output");
  for (my $i=0; $i < $numOutputs; $i++) {
    my $outputNames =
      $outputNodes->item($i)->getElementsByTagName("Output_Name");

    if ($outputNames->getLength < 0) {
      return 0;
    }

    $filterHash->{"Outputs"}->[$i + $numberPreviousOutputs]->{"Output_Name"} =
      $outputNames->item(0)->getFirstChild->getNodeValue;

    # Set output type
    if ($outputNodes->item($i)->getElementsByTagName("Output_Type")->getLength
        > 0)
    {
      $filterHash->{"Outputs"}->
        [$i + $numberPreviousOutputs]->{"Output_Type"} =
        $outputNodes->item($i)->getElementsByTagName("Output_Type")->
        item(0)->getFirstChild->getNodeValue;
    }
    else
    {
      # there is no Output_Type specified
      return 0;
    }
  }
  if ($numberPreviousOutputs == 0){
    #set up an input for self if is the base class (all really need
    #is the name)
    $filterHash->{"Outputs"}->[$numOutputs]->{"Output_Name"} = "Self";
    $filterHash->{"Outputs"}->[$numOutputs]->{"Output_Type"} =
      $filterHash->{"Filter_Name"};
  }
  return $numOutputs;
}
