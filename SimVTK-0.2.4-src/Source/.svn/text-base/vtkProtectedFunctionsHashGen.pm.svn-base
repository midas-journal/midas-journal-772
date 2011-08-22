package vtkProtectedFunctionsHashGen;


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
# vtkProtectedFunctionsHashGen.pm
#
###############################################

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(vtkProtectedFunctionsHashGen);

##########################################################
# vtkProtectedFunctionsHashGen subroutine
# Updates XML Filter node protected hash (ie. it will contain the name of
# all protected functions of a particular class). 
#
# Input: 1. reference to %protectedHash
#        2. Name of class file
#        3. directory where the xml files are located
# Returns: updated filter node
##########################################################
sub vtkProtectedFunctionsHashGen {

  my ($protectedHash, $xmlFile, $sourceDirectory) = @_;

  #all should have XML that need it, as all (?) classes that are superclasses
  #of another or are wrapped themselves should have had an XML made (but just
  #warn if not as not really a serious problem but would be nice to know if
  #class is not wrapped or not found for some reason.)
  warn "ERROR: " . $xmlFile . " file not found"
    unless -f $sourceDirectory . "/" . $xmlFile;
  if (-f $sourceDirectory . "/" . $xmlFile) 
  {
    # Read the input file and create an XML DOM data structure
    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parsefile ($sourceDirectory . "/" . $xmlFile);

    my $filtersNodeList = $doc->getElementsByTagName("Filter");
    my $filterNode = $filtersNodeList->item (0);
    
    warn "ERROR: Bad Protected Function name in " . $xmlFile . "."
      if (!addProtectedFunctions($filterNode, $protectedHash));
      
    $doc->dispose;
  }
}

##########################################################
# addProtectedFunctions
# Extracts the Protected Functions for the filter and stores them in a hash
#
# Input: 1. an XML::DOM::NodeList
#          2. reference to %protectedHash
#Returns : False if find an empty name, and true if no problems encountered.
##########################################################
sub addProtectedFunctions {

  my ($filterNode, $protectedHash) = @_;
  
  my $numFunctions =
    $filterNode->getElementsByTagName("Protected_Function")->getLength;
  
  my $functionNodes = $filterNode->getElementsByTagName("Protected_Function");
  my $numFunctions = $functionNodes->getLength;
  # Process each function in turn
  for (my $i=0; $i < $numFunctions; $i++) 
  {
    # Set Function_Name
    my $functionNames =
      $functionNodes->item($i)->getElementsByTagName("Function_Name");

    if ($functionNames->getLength <= 0) 
    {
      return 0;
    }
    #make sure wasn't just a function named Add,Set, or Get so make sure word
    #length is greater than 3
    if (length($functionNames->item(0)->getFirstChild->getNodeValue) > 3)
    {
      #remove the first 3 letters so that is easy to compare to when removing
      $protectedHash->{(substr($functionNames->item(0)->
                               getFirstChild->getNodeValue, 3))} = 1;
    }
  }
  return 1;
}
