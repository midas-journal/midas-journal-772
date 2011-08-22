/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkSimCocoaRenderWindowInteractor.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkSimCocoaRenderWindowInteractor - Cocoa interactor for SimVTK
//
// .SECTION Description
// The interactor interfaces with vtkSimCocoaRenderWindow and
// vtkSimCocoaNSView to trap messages from the Cocoa window manager
// and send them to vtk.

#ifndef __vtkSimCocoaRenderWindowInteractor_h
#define __vtkSimCocoaRenderWindowInteractor_h

#include "vtkCocoaRenderWindowInteractor.h"

class vtkNSViewInteractorEventNode;
class vtkMutexLock;
class vtkSimTimer;

class VTK_EXPORT vtkSimCocoaRenderWindowInteractor :
  public vtkCocoaRenderWindowInteractor
{
public:
  static vtkSimCocoaRenderWindowInteractor *New();
  vtkTypeRevisionMacro(vtkSimCocoaRenderWindowInteractor,vtkCocoaRenderWindowInteractor);
  void PrintSelf(ostream& os, vtkIndent indent);

  void SetRenderWindow(vtkRenderWindow *renwin);

  void Initialize();

  void Render();

  void InvokeEvent(unsigned long event, void *callData);

  void Flush();

  void SetEventInformation(int x, int y,
                           int controlDown, int shiftDown);
   
  void SetEventInformation(int x, int y,
                           int controlDown, int shiftDown,
                           char charCode, int repeatCount,
                           const char *keySym);
    
  void SetAltKey(int altDown);

  void TerminateApp();

protected:
  vtkSimCocoaRenderWindowInteractor();
  ~vtkSimCocoaRenderWindowInteractor();

  int InternalCreateTimer(int timerId, int timerType,
                          unsigned long duration);

  int InternalDestroyTimer(int platformTimerId);

  void *CreatedWindow;

  vtkSimTimer *TimerList;
  int TimerListLen;

  vtkMutexLock *Mutex;
  vtkNSViewInteractorEventNode *Node;
  vtkNSViewInteractorEventNode *Head;
  vtkNSViewInteractorEventNode *Tail;

private:
  vtkSimCocoaRenderWindowInteractor(const vtkSimCocoaRenderWindowInteractor&);  // Not implemented.
  void operator=(const vtkSimCocoaRenderWindowInteractor&);  // Not implemented.
};

#endif
