/*=========================================================================

Program:   Visualization Toolkit
Module:    $RCSfile: vtkSimCocoaRenderWindow.mm,v $

Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
All rights reserved.
See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

#import "vtkCocoaMacOSXSDKCompatibility.h" // Needed to support old SDKs
#import "vtkSimCocoaRenderWindow.h"
#import "vtkObjectFactory.h"

#import <Cocoa/Cocoa.h>

vtkCxxRevisionMacro(vtkSimCocoaRenderWindow, "$Revision: 1.70 $");
vtkStandardNewMacro(vtkSimCocoaRenderWindow);


//----------------------------------------------------------------------------
vtkSimCocoaRenderWindow::vtkSimCocoaRenderWindow()
{
}

//----------------------------------------------------------------------------
vtkSimCocoaRenderWindow::~vtkSimCocoaRenderWindow()
{
#if (VTK_MAJOR_VERSION > 5) || ((VTK_MAJOR_VERSION == 5) && (VTK_MINOR_VERSION > 4))
  NSWindow *window = (NSWindow *)this->GetRootWindow();
#else
  NSWindow *window = (NSWindow *)this->GetWindowId();
#endif

  // Close the window, because VTK doesn't do this for Cocoa
  if (window && this->OnScreenInitialized)
    {
#if (VTK_MAJOR_VERSION > 5) || ((VTK_MAJOR_VERSION == 5) && (VTK_MINOR_VERSION > 4))
    this->SetRootWindow(0);
    this->SetWindowId(0);
#else
    this->SetWindowId(0);
    this->SetDisplayId(0);
#endif

    if (this->GetWindowCreated())
      {
      [window close];
      }
    }
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindow::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os, indent);
}
