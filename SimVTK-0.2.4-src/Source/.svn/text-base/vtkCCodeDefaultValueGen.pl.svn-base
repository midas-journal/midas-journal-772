#!/usr/bin/perl

# =================
# Copyright (c) Queen's University
# All rights reserved.

# See Copyright.txt for more details.
# =================

###############################################
# SIMVTK Project
#
#
# USAGE:
# vtkCCodeDefaultValueGen.pl <library_name> <XML_directory> <source_directory>
#                            <output_directory> <list_of_classes>
#
#<library_name> is the name of the vtk Library the file will be a part of
# <XML_directory> is the location where all the .xml files are located
#             (same as build directory for vtkBlockGenerator.pl)
# <source_directory> is the location where the ".in" files are located
# <output_directory> is the location the C code will be placed
# <list_of_classes> is the CMake style list of classes that belong to the
#             library
#
# ASSUMPTIONS:
# 1. The List of Classes will be a list of the full vtk names separated
#    solely by ';' (the way the CMake lists are stored)
#
# Created by Adam Campigotto on July 22nd 2008
# to be used with SimVTK
###############################################

use strict;
use XML::DOM;

# Check that 5 arguments are given
my $numArgs = $#ARGV + 1;  #ARGV is subscript of last element in list
die "\nUSAGE:" .
  "vtkLibraryGen.pl <library_name> <XML_directory> <source_directory>" .
  " <output_directory> <list_of_classes>"
    unless $numArgs == 5;

#The first argument is the library name
my $libraryName = shift;

#The second argument is the directory where the .mdlparts files are located
my $XMLDirectory = shift;

#The third argument is the source directory where this file is located
# (as well as the .cpp.in file)
my $sourceDirectory = shift;

#The fourth argument is the output directory where the .mdl file will be placed
my $outputDirectory = shift;

#The fifth argument is the list of classes that belong to this class
my $classesList = shift;

my @classes = split(/;/, $classesList);

my $defaultValuesContent = "";

my $headers = "";
#   "#include \"vtkInformation.h\"\n";

foreach my $class (@classes)
{
  #parse the XML file
  if (-f $XMLDirectory . "/" . $class . ".xml")
  {
    my %filterHash;
    my $isvtkAlgorithmSubclass;
    my %flagHash;
    # Read the input file and create an XML DOM data structure
    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parsefile ($XMLDirectory . "/" . $class . ".xml");

    my $filtersNodeList = $doc->getElementsByTagName("Filter");
    my $filterNode = $filtersNodeList->item (0);

    my ($returnStatus, $filterName) = findFilterName($filterNode,
                                                     \%filterHash);

    # get a hash of the class' functions and an indicator to know if it is a
    # subclass of vtkAlgorithm
    $isvtkAlgorithmSubclass =
      vtkCombineSuperclasses(\%filterHash,
                               "$filterHash{\"Filter_Name\"}.xml",
                               $xmlDirectory, 2);

    $headers .= "\n#include \"$filterHash{\"Filter_Name\"}.h\"\n";

    $defaultValuesContent .=
      setupDefaultValueCheckString(\%filterHash, $isvtkAlgorithmSubclass);

    $doc->dispose;
  }
}

#open the .ccp.in file that will be updated with the headers and content
open (INFILE, "<",  $sourceDirectory . "/vtkCCodeDefaultGen.cpp.in");

undef $/;
my $content = <INFILE>;
$/ = "\n";
close INFILE;

#HEADERS
$content =~ s/\@HEADERS\@/$headers/g;

#DEFAULT_VALUE_CHECKS
$content =~ s/\@DEFAULT_VALUE_CHECKS\@/$defaultValuesContent/g;

# Create the output .cpp file
open (OUTFILE, ">$outputDirectory/Simvtk" . $libraryName . "DefaultGen.cpp");
print OUTFILE $libraryContent;
close OUTFILE;


##########################################################
# setupDefaultValueCheckString subroutine
# Creates the string used in the C++ code to get the default values for the
# functions and print out an xml description
#
# Input: 1. reference to %filterHash
#        2. flag for if is a vtkAlgorithm subclass (uses 1 for true and 0
#           for false)
# Returns: string that will be added to the C++ code
##########################################################
sub setupDefaultValueCheckString {

  my ($filterHash, $isvtkAlgorithmSubclass) = @_;
  my $string = "";

  #check for proper name
  $string .= "  if (strcmp(\"$filterHash->{\"Filter_Name\"}\", argv[1])" .
    " == 0)\n" .
    "  {\n" .
    #CHANGE HERE  have to make it so that fout actually is file of specific
    # class and not directory only
    "    " . $filterHash->{"Filter_Name"} . " *o = " .
    ($filterHash->{"Filter_Name"}) . "::New();\n" . # instantiate object
    "    indent(indentation);\n" .
    "    fprintf(fout, \"<Filter>\\n\");\n" . #print filter header
    "    indentation++;\n" .
    "    indent(indentation);\n" .
    "    fprintf(fout, \"<Filter_Name>" . ($filterHash->{"Filter_Name"}) .
    "</Filter_Name>\\n\");\n" .
    "    indent(indentation);\n" .
    "    fprintf(fout, \"<Filter_Parameters>\\n\");\n" ;
  $string .= setupParametersString($filterHash);
  $string .= "    fprintf(fout, \"</Filter_Parameters>\\n\");\n" .
    "  }\n" ;

  return $string;
}

##########################################################
# setupParametersString subroutine
# Creates the string used in the C++ code to get the default values for the
# functions and print out an xml description for each parameter in the list
# of parameters for a given function
#
# Input: 1. reference to %filterHash
#        2. flag for if is a vtkAlgorithm subclass (uses 1 for true and 0
#           for false)
# Returns: string that will be added to the C++ code
##########################################################
sub setupParametersString {

  my ($filterHash) = @_;
  my $string = "";

  $string .=   "    indentation++;\n" ;

  foreach my $param (@{$filterHash->{"Filter_Parameters"}})
  {
    my $paramName = $param->{"Parameter_Name"};
    my $paramFlag = $param->{"Parameter_Flag"};
    my $paramTypesTotal = $param->{"Parameter_Type"};
    my $paramSizesTotal = $param->{"Parameter_Size"};
    my @paramTypes = split(/,/ , $paramTypesTotal);
    my @paramSizes = split(/,/ , $paramSizesTotal);
    my $paramType = $paramTypes[0];
    my $paramSizes = $paramSizes[0];

    #only can get default parameters for functions that have both a get and
    #set function associated with the value and that are not indexed (which
    # all should be set only anyways)
    if (@paramSizes == 1 && $paramFlag eq "Both")
    {
      $string .= "    indent(indentation);\n" .
        "    fprintf(fout, \"<Parameter>\\n\");\n" .
        "    indentation++;\n" .
        "    indent(indentation);\n" .
        "    fprintf(fout, \"<Parameter_Name>" . ($paramName) .
        "</Parameter_Name>\\n\");\n" .
        "    " .
    }

  }

  return $string;
}



# # # # #how to deal with arrays
# # # # # double *val = new double[3];
# # # # # val = cone->GetCenter();

# # # # # cout << val[0] << "\n";
# # # # # cout << val[1] ;
# # # # # cout << val[2];
# # # # # delete val;

# # # # # # # if (properClassName)
# # # # # # # {
# # # # # # # Instantiate object;
# # # # # # # print( <FILTER>
# # # # # # # <FILTER_NAME> properClassName </FILTER_NAME> )
# # # # # # # default = object->get___();
# # # # # # # print (<PARAMETER>)
# # # # # # # print (<PARAMETER_NAME> copy over from real XML </PARAMETER_NAME>)
# # # # # # # print ("<PARAMETER_DEFAULT>%(i|s)</PARAMETER_DEFAULT>", default)
# # # # # # # print (</PARAMETER>)
# # # # # # # }
