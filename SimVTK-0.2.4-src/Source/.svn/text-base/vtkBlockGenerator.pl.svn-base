#!/usr/bin/perl


# =================
# Copyright (c) Queen's University
# All rights reserved.

# See Copyright.txt for more details.
# =================

###############################################
# SIMITK Project
# Karen Li and Jing Xiang
# May 9, 2008
#
# BlockGenerator.pl
#
# Automatically lists the filter names inside the XML or  generates the
# code given an XML description
#
#  Modified by Adam Campigotto on June 5th 2008
#
# USAGE:
# vtkBlockGenerator.pl <flag> <XML_file> <directory> <build_file_directory>
#                      <library> <xml_directory> <source_directory> <counter>
# where <flag> is
# -LIST: results in a list of all filter names in the XML file.
# -GENERATE: generate the code
# <directory> is the directory where the generated code should be placed
# <library> is the name of the vtk Library the file will be a part of
# <xml_directory> is the location where all the XML files that are needed are
#           placed
# <source_directory> is the location where the ".in" files are located
#
# BEHAVIOUR AND ASSUMPTIONS:
# 1. When looking for tagnames, only the first matching element is used.
# 2. Elements which are expected to contain data must contain
#    non-empty data. As well, unexpected behaviour will occur if the
#    elements contain anything else besides data (i.e. child elements,
#    attributes or comments).
###############################################

use strict;
use Switch;
use XML::DOM;
use POSIX;
use vtkSFunctionGen;
use vtkFilterMaskGen;
use vtkMatlabCallbackGen;
use vtkCombineSuperclasses;
use vtkProtectedFunctionsHashGen;

# Check that 8 arguments are given
my $numArgs = $#ARGV + 1;  #ARGV is subscript of last element in list
die "\nUSAGE:" .
  "vtkBlockGenerator.pl <flag> <XML_file> <output_directory>" .
  " <output_build_directory> <library_name> <xml_directory>" .
  " <perl_module_source_directory> <counter>"
    unless $numArgs == 8;

#The first argument is the flag that determines whether simply a list of
#filter names is required or the full source code
my $flag = shift;
die "\nUSAGE:\n" .
  "<flag> = -LIST to list filter names\n" .
  "or -GENERATE to generate source code\n"
  unless $flag eq "-LIST" || $flag eq "-GENERATE" ;
#if ($flag  eq "-LIST"){
#  print "\"";
#}

# The second argument is the name of the input XML file
my $xmlFile = shift;
die "ERROR: Input file not found"
  unless -f $xmlFile ;

#The third argument is the bin directory where the generated source code
#should be placed
my $directory = shift;

#The fourth argument if the build directory where the cpp, and mdlpart
#should be placed
my $buildDirectory = shift;

#The fifth argument is the library name where the file should be placed
my $libraryName = shift;

# The sixth argument is the location of where the xml files are located
my $xmlDirectory = shift;

# The seventh argument is the location of where the ".in" files are located
my $sourceDirectory = shift;

# The eigth argument is a count to decide where a file is placed in the library
my $count = shift;

my $maskContent = ""; #stores the code for generating mask for each block.



#There are two columns that display the filter masks.  If we're on the left
# column, then  $onLeftColumn is true, = 1
my $onLeftColumn = 0;
$onLeftColumn = 1 if ($count % 2 == 0);

my $top = 50 + 100 * floor($count / 2) ;
my $left = 50;
$left = 300 if ($count % 2 == 1);
my $bottom = $top + 50;
my $right = $left + 125;

#Create hashes to represent the position information of the filter's mask
#in Simulink
my %positionLeftCol = ("top",$top ,"left",$left ,"right",$right ,
                       "bottom",$bottom);

# Read the input file and create an XML DOM data structure

  my $parser = new XML::DOM::Parser;
  my $doc = $parser->parsefile ($xmlFile);


# A nodelist where each node represents a filter description
my $filtersNodeList = $doc->getElementsByTagName("Filter");
my $numFilters = $filtersNodeList->getLength;

#Stores the names of all filters, delimited by semicolon,
#This is then converted into a list in cmake.  (not needed yet)
my $filterNameList = "";

my $isvtkAlgorithmSubclass = 0;

# Loop over each filter in turn
for (my $filterInd=0; $filterInd < $numFilters; $filterInd++) {

  my $filterNode = $filtersNodeList->item ($filterInd);
  #Create a hash to represent the filter information
  my %filterHash = ();
  my %protectedHash = ();

  # Extract the filter names
  my ($returnStatus, $filterName) = findFilterName($filterNode, \%filterHash);
  if ( $returnStatus == 0 ) {
    die "ERROR: No 'Filter_Name' element found for filter " . ($filterInd+1);
  }
  $filterNameList = $filterNameList . $filterName;

  # Extract the documentation
  $returnStatus = findDocumentation($filterNode, \%filterHash);
  if ( $returnStatus == 0 ) {
    die "ERROR: No 'Documentation' element found for filter " . ($filterInd+1);
  }

  #if the GENERATE flag is set, extract filter information, store in hash,
  # and generate all source code
  if ($flag eq "-GENERATE"){

    # Add to the filter, all the super class items that will be needed
    $isvtkAlgorithmSubclass =
        vtkCombineSuperclasses(\%filterHash,
                               "$filterHash{\"Filter_Name\"}.xml",
                               $xmlDirectory, 0);

    # Add to the protected hash the names of all protected functions as keys
    vtkProtectedFunctionsHashGen(\%protectedHash,
                                 "$filterHash{\"Filter_Name\"}.xml",
                                 $xmlDirectory);

    sortAndRemoveDuplicateNamesAndProtectedFunctions(\%filterHash,
                                                     \%protectedHash,
                                                     $isvtkAlgorithmSubclass);

    # To make the library blocks look readable, decide on the maximum number
    # of ports that the block will need
    #CHANGE HERE2 (just make $most ports = 3 as never will have more
    # than that) (allows a lot of other stuff to be removed for convenience)
    my $mostPorts = 3;

    #Add Mask code for the filter, increment the positions for the filter
    #masks
    my $filterMask;
    $filterMask = vtkFilterMaskGen(\%filterHash, \%positionLeftCol,
                                   $sourceDirectory, $isvtkAlgorithmSubclass);

    #create the mdlpart file that stores the mask content for each class
    open (OUTFILE, ">$buildDirectory/Sim" . $filterHash{"Filter_Name"} .
          ".mdlpart");
    print OUTFILE $filterMask;
    close OUTFILE;

    $maskContent = $maskContent . $filterMask;
    # Generate the Matlab callback m file
    vtkMatlabCallbackGen(\%filterHash, $directory, $isvtkAlgorithmSubclass,
                         $sourceDirectory);
    # Generate the SFunction File
    vtkSFunctionGen(\%filterHash, $directory, $isvtkAlgorithmSubclass,
                    $sourceDirectory, $buildDirectory);
  }
 }

if ($flag eq "-LIST"){
  chop($filterNameList);
  print $filterNameList;
}

$doc->dispose;

##########################################################
#sortAndRemoveDuplicateNamesAndProtectedFunctions
# sort the hash alphabetically and remove all duplicates in each array
# (ie. remove extra "Self")
##########################################################
sub sortAndRemoveDuplicateNamesAndProtectedFunctions{
  my ($filterHash, $protectedHash, $isvtkAlgorithmSubclass) = @_;

  my $filterName = $filterHash->{"Filter_Name"};

  foreach my $key (keys %{$filterHash})
  {
    if ($key eq "Inputs" || $key eq "Outputs" || $key eq "Filter_Parameters") {
      my %seen = ();
      my @unique = ();
      my $name;
      for my $i (0.. $#{$filterHash->{$key}})
      {
        # Check for the right key value (since we know it must end with Name
        # to be what we are looking for
        # This allows the subroutine to work with Output_Name, Input_Name,
        # and Parameter_Name
        foreach my $key2 (%{$filterHash->{$key}->[$i]})
        {
          $name = $key2 if ($key2 =~ /.+Name/);
          last if ($key2 =~ /.+Name/);
        }
        if ($name ne "")
        {
          my $word = $filterHash->{$key}[$i]{$name};
          #only add if not added before (so will keep the function closest to
          #the childest class) and make sure is not a protected function
          if ((!exists $seen{$word}) && (!exists $protectedHash->{$word}))
          {
            $seen{$word} = $i;
          }
        }
      }
      if ($name ne ""){
        @unique = keys %seen;
        @unique = sort @unique;

        # temp stores an array that has a sorted list of hash elements
        # (sorted based on Name)
        my @temp = ();
        foreach my $elem (@unique){

          #SPECIAL CASE
          #for subclasses of Collection, they all have AddItem(vtkObject)
          #private, so no way to get into XML or check easily, but all have
          #an AddItem(vtkClassnameLessCollection) so must change type for
          # those classes now
          if ($elem eq "Item" && ($filterName =~ m/^vtk(\w+)Collection$/) &&
              $key eq "Inputs")
          {
            $filterHash->{$key}->[$seen{$elem}]->{"Input_Type"} = "vtk$1";
          }
          #Another special case... private functions cannot be figured out
          #any other way
          if (($elem ne "Item" ||
               $filterName ne "vtkAssemblyPath")  &&
              ($elem ne "InterpolatorPrototype" ||
               $filterName ne "vtkTemporalStreamTracer"))
          {
            #want self at front of array
            if ($elem eq "Self"){
              unshift(@temp, \%{$filterHash->{$key}->[$seen{$elem}]});
            }
            elsif ($elem eq "Input" || $elem eq "Output"){
              #don't include "Input" or "Output" for algorithms
              if (! $isvtkAlgorithmSubclass){
                push(@temp, \%{$filterHash->{$key}->[$seen{$elem}]});
              }
            }
            else {
              push(@temp, \%{$filterHash->{$key}->[$seen{$elem}]});
            }
          }
        }
        #want Self for inputs at end of list and to leave Self for outputs at
        #top of list so remove it from the start and put on end (will have
        #to make it so that inputPortIndex is setup properly too which would
        # require doing a check of all parameters for knowing what is true or
        # false... basically add in initialize sizes stuff... yuck)
        # if ($key eq "Inputs"){
        # push(@temp, (shift(@temp)));
        # }
        #assign to the hash a new ordered list in input/output/parameter names
        ${$filterHash}{$key} = [@temp];
      }
    }
  }
}

##########################################################
# findFilterName
# Extracts Filter_Name for the filter and stores it in %filterHash
#
# Input: 1. an XML::DOM::NodeList
#        2. reference to %filterHash
# Returns: False and empty string if a Filter_Name element is not found
#          Else true and the filter name with a succeeding semicolon
##########################################################
sub findFilterName {

  my ($filterNode, $filterHash) = @_;

  if ($filterNode->getElementsByTagName("Filter_Name")->getLength <= 0) {
    return (0, "");
  }

  $filterHash->{"Filter_Name"} =
    $filterNode->getElementsByTagName("Filter_Name")->item(0)->
      getFirstChild->getNodeValue;

  my $filterName = $filterHash->{"Filter_Name"} . ";";
  return (1, $filterName);
}

##########################################################
# findDocumentation
# Extracts documentation from the xml and stores it in %filterHash
#
# Input: 1. an XML::DOM::NodeList
#        2. reference to %filterHash
# Returns: False if a Documentation element is not found
#          Else true
##########################################################
sub findDocumentation {

  my ($filterNode, $filterHash) = @_;

  if ($filterNode->getElementsByTagName("Documentation")->getLength <= 0) {
    return 0;
  }

  my $docNode = $filterNode->getElementsByTagName("Documentation")->item(0);

  $filterHash->{"Summary"} =
    $docNode->getElementsByTagName("Summary")->item(0)->
      getFirstChild->getNodeValue;

  $filterHash->{"Description"} =
    $docNode->getElementsByTagName("Description")->item(0)->
      getFirstChild->getNodeValue;

  return 1;
}
