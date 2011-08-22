#!/usr/bin/perl

# =================
# Copyright (c) Queen's University
# All rights reserved.

# See Copyright.txt for more details.
# =================

###############################################
# SIMVTK Project
#
# This is actually the full library gen... the part is already taken care
# of by vtkFilterMaskGen.pm
#
# USAGE:
# vtkLibraryGen.pl <library_name> <mdlParts_directory> <source_directory> \
#                  <output_directory> <list_of_classes>
#
#<library_name> is the name of the vtk Library the file will be a part of
# <mdlParts_directory> is the location where all the .mdlpart files are
#                located (same as build directory for vtkBlockGenerator.pl)
# <source_directory> is the location where the ".in" files are located
# <output_directory> is the location the library model will be placed
# <list_of_classes> is the CMake style list of classes that belong to the
#                library
#
# ASSUMPTIONS:
# 1. The List of Classes will be a list of the full vtk names separated
#    solely by ';' (the way the CMake lists are stored)
#
# Created by Adam Campigotto on July 22nd 2008
# to be used with SimVTK
###############################################

use strict;

# Check that 5 arguments are given
my $numArgs = $#ARGV + 1;  #ARGV is subscript of last element in list
die "\nUSAGE:" .
  "vtkLibraryGen.pl <library_name> <mdlParts_directory> <source_directory>" .
  " <output_directory> <list_of_classes>"
    unless $numArgs == 5;

#The first argument is the library name
my $libraryName = shift;

#The second argument is the directory where the .mdlparts files are located
my $mdlPartsDirectory = shift;

#The third argument is the source directory where this file is located
#(as well as the library.in file)
my $sourceDirectory = shift;

#The fourth argument is the output directory where the .mdl file will be placed
my $outputDirectory = shift;

#The fifth argument is the list of classes that belong to this class
my $classesList = shift;

my @classes = split(/;/, $classesList);

#Store the list of all the masks here

my $maskContent = "";

foreach my $class (@classes)
{
  my $check = open(INFILE, "<",
                   "$mdlPartsDirectory/Sim" . $class . ".mdlpart");

  #make sure opened a file before trying to read it in and adding it to
  #the mask string
  if ($check != undef){
    undef $/;
    my $classContent = <INFILE>;
    $/ = "\n";
    close INFILE;

    # Add the newest class to the end of the string that will be the library
    $maskContent .= $classContent;
  }
}

if ($libraryName eq "Imaging")
{
  open (INFILE, "<",  $sourceDirectory . "/vtkImagingLibrary.mdl.in");
}
elsif ($libraryName eq "Common")
{
  open (INFILE, "<", $sourceDirectory . "/vtkCommonLibrary.mdl.in");
}
elsif ($libraryName eq "Filtering")
{
  open (INFILE, "<", $sourceDirectory . "/vtkFilteringLibrary.mdl.in");
}
else
{
  open (INFILE, "<", $sourceDirectory . "/vtkLibrary.mdl.in");
}

undef $/;
my $libraryContent = <INFILE>;
$/ = "\n";
close INFILE;

 # if is not on Windows, remove the control-M (return) characters
if ($^O ne "MSWin32") {
  $libraryContent =~ s/\cM//g;
}


#LIBRARY_HEADER
$libraryContent =~ s/\@LIBRARY_HEADER\@/$libraryName/g;

#TIMESTAMP
my $timestamp = gmtime();
$libraryContent =~ s/\@TIMESTAMP\@/$timestamp/g;

# Add the filter masks to the library file
$libraryContent =~ s/\@FILTER_MASK_CODE\@/$maskContent/g;

# Create the output model file
open (OUTFILE, ">$outputDirectory/Simvtk" . $libraryName . "Library.mdl");

print OUTFILE $libraryContent;
close OUTFILE;
