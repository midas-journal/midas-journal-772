/*=========================================================================

Program:   Visualization Toolkit
Module:    $RCSfile: vtkSimCocoaRenderWindow.h,v $

Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
All rights reserved.
See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkSimCocoaRenderWindow - Cocoa render window for SimVTK
//
// .SECTION Description
// vtkSimCocoaRenderWindow is a concrete implementation of the abstract
// class vtkOpenGLRenderWindow.

#ifndef __vtkSimCocoaRenderWindow_h
#define __vtkSimCocoaRenderWindow_h

#include "vtkCocoaRenderWindow.h"

class VTK_EXPORT vtkSimCocoaRenderWindow : public vtkCocoaRenderWindow
{
public:
  static vtkSimCocoaRenderWindow *New();
  vtkTypeRevisionMacro(vtkSimCocoaRenderWindow,vtkCocoaRenderWindow);
  void PrintSelf(ostream& os, vtkIndent indent);

protected:
  vtkSimCocoaRenderWindow();
  ~vtkSimCocoaRenderWindow();

private:
  vtkSimCocoaRenderWindow(const vtkSimCocoaRenderWindow&);  // Not implemented.
  void operator=(const vtkSimCocoaRenderWindow&);  // Not implemented.

private:

};

#endif
