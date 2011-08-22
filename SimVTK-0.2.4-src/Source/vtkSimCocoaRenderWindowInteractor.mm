/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkSimCocoaRenderWindowInteractor.mm,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
#import "vtkSimCocoaRenderWindowInteractor.h"
#import "vtkSimCocoaNSView.h"
#import "vtkCocoaRenderWindow.h"
#import "vtkCommand.h"
#import "vtkObjectFactory.h"
#import "vtkMutexLock.h"

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

#import <sys/time.h>

//----------------------------------------------------------------------------
// Override the window "close" so that it calls Exit

@interface vtkSimCocoaWindow : NSWindow
{
  vtkSimCocoaRenderWindowInteractor *interactor;
}

- (id)initWithInteractor:(vtkSimCocoaRenderWindowInteractor *)iren
      contentRect:(NSRect)ctRect;
- (void)clearInteractor;
- (void)close;

@end

@implementation vtkSimCocoaWindow

- (id)initWithInteractor:(vtkSimCocoaRenderWindowInteractor *)iren
      contentRect:(NSRect)ctRect
{
  self = [super initWithContentRect:ctRect
                styleMask:NSTitledWindowMask |
                          NSClosableWindowMask |
                          NSMiniaturizableWindowMask |
                          NSResizableWindowMask
                backing:NSBackingStoreBuffered
                defer:NO];

  if (self)
    {
    interactor = iren;
    }

  return self;
}

- (void)clearInteractor
{
  interactor = nil;
}

- (void)close
{
  vtkSimCocoaRenderWindowInteractor *iren = interactor;
  interactor = nil;

  [super close];

  if (iren)
    {
    iren->ExitCallback();
    }
}

@end

//----------------------------------------------------------------------------
// vtkSimTimer is a simple timer object that must be driven externally.

class vtkSimTimer
{
public:
  vtkSimTimer(int timerId=0, int repeating=0, unsigned long duration=0);
  int CheckTime(vtkSimTimer &timer);
  void Increment(vtkSimTimer &timer);

  int TimerId;
  int Repeating;

  int Active;
  int Deleted;

  vtkSimTimer *Next;
  vtkSimTimer *Prev;

private:
  unsigned long Duration;
  struct timeval NextTime;
};

// Constructor
vtkSimTimer::vtkSimTimer(int timerId, int repeating, unsigned long duration)
{
  this->TimerId = timerId;
  this->Repeating = repeating;
  this->Duration = duration;

  this->Active = 0;
  this->Deleted = 0;

  // Get the current time
  struct timeval currTime;
  gettimeofday(&currTime, NULL);

  // Increment by the duration minus the remainder
  unsigned long secs = duration/1000;
  unsigned long msecs = duration - secs*1000;

  this->NextTime.tv_sec = currTime.tv_sec + secs;
  this->NextTime.tv_usec = currTime.tv_usec + msecs*1000;
  if (this->NextTime.tv_usec > 1000000)
    {
    this->NextTime.tv_sec += 1;
    this->NextTime.tv_usec -= 1000000;
    }

  this->Next = 0;
  this->Prev = 0;
}

// Increment by the duration
void vtkSimTimer::Increment(vtkSimTimer& timer)
{
  // Find out how much time has already passed
  unsigned long elapsedSecs = 0;
  unsigned long elapsedUsecs = 0;

  elapsedSecs = timer.NextTime.tv_sec - this->NextTime.tv_sec;
  if (timer.NextTime.tv_usec >= this->NextTime.tv_usec)
    {
    elapsedUsecs = timer.NextTime.tv_usec - this->NextTime.tv_usec;
    }
  else
    {
    elapsedUsecs = 1000000 + timer.NextTime.tv_usec - this->NextTime.tv_usec;
    elapsedSecs -= 1;
    }

  // Convert to milliseconds, find the remainder
  unsigned long elapsedMSecs = elapsedSecs*1000 + elapsedUsecs/1000;
  unsigned long remainder = elapsedMSecs % this->Duration;

  // Increment by the duration minus the remainder
  unsigned long secs = (this->Duration - remainder)/1000;
  unsigned long msecs = this->Duration - remainder - secs*1000;

  this->NextTime.tv_sec = timer.NextTime.tv_sec + secs;
  this->NextTime.tv_usec = timer.NextTime.tv_usec + msecs*1000;
  if (this->NextTime.tv_usec > 1000000)
    {
    this->NextTime.tv_sec += 1;
    this->NextTime.tv_usec -= 1000000;
    }
}

// Check if NextTime has exceeded "timer"
int vtkSimTimer::CheckTime(vtkSimTimer& timer)
{
  if (timer.NextTime.tv_sec > this->NextTime.tv_sec ||
      (timer.NextTime.tv_sec == this->NextTime.tv_sec &&
       timer.NextTime.tv_usec > this->NextTime.tv_usec))
    {
    return 1;
    }

  return 0;
}

//-------------------------------------------------------------
// The vtkNSViewInteractorEventNode class is a container for
// all the information that can be carried by an interaction event.
// It is meant to be stored on a queue.

// Some macros to reduce typing later:

#define vtkSetEventInfoMacro(name, type) \
void Set##name (type _arg) { \
/*  cout << "q Set" #name" (" << _arg << ")" << endl;*/ \
  this->name = _arg; this->InfoBitfield |= (1 << name##Bit); }

#define vtkSetEventInfo2Macro(name, type) \
void Set##name (type *_arg) { \
/*  cout << "q Set" #name" (" << _arg[0] << ", " << _arg[1] << ")" << endl;*/ \
  this->name[0] = _arg[0]; this->name[1] = _arg[1]; \
  this->InfoBitfield |= (1 << name##Bit); }

#define vtkCopyEventInfoIfSetMacro(name, iren) \
    if ( ((this->InfoBitfield >> name##Bit) & 1) ) { \
/*      cout << "f Set" #name" (" << this->name << ")" << endl;*/ \
      iren->vtkRenderWindowInteractor::Set##name ( this->name ); }

#define vtkCopyEventInfoIfSet2Macro(name, iren) \
    if ( ((this->InfoBitfield >> name##Bit) & 1) ) { \
/*      cout << "f Set" #name" (" << this->name[0] << ", " << this->name[1] << ")" << endl;*/ \
      iren->vtkRenderWindowInteractor::Set##name ( this->name[0], this->name[1] ); }

//----------------------------------------------------------------------------
// The vtkNSViewInteractorEventNode is a storage node for a queued event.
// Also see the above macros.

class vtkNSViewInteractorEventNode
{
public:
  enum EventInfoBits {
    EventPositionBit = 0,
    ControlKeyBit,
    ShiftKeyBit,
    KeyCodeBit,
    RepeatCountBit,
    KeySymBit,
    AltKeyBit,
  };

  static vtkNSViewInteractorEventNode *New() {
    return new vtkNSViewInteractorEventNode; };

  void Delete() { delete this; };

  void Initialize() {
    this->Event = 0; this->CallData = 0; this->InfoBitfield = 0;
    this->Prev = 0; this->Next = 0; };

  void SetEvent(unsigned long event) { this->Event = event; };
  void SetCallData(void *data) { this->CallData = data; };
  void InvokeEventOnInteractor(vtkRenderWindowInteractor *iren);

  vtkSetEventInfo2Macro(EventPosition, int);
  vtkSetEventInfoMacro(ControlKey, int);
  vtkSetEventInfoMacro(ShiftKey, int);
  vtkSetEventInfoMacro(KeyCode, char);
  vtkSetEventInfoMacro(RepeatCount, int);
  vtkSetEventInfoMacro(KeySym, const char *);
  vtkSetEventInfoMacro(AltKey, int);

  // List stuff
  vtkNSViewInteractorEventNode *Prev;
  vtkNSViewInteractorEventNode *Next;

protected:

  // Event information
  unsigned long Event;
  void *CallData;
  unsigned int InfoBitfield;
  int   EventPosition[2];
  int   ControlKey;
  int   ShiftKey;
  char  KeyCode;
  int   RepeatCount;
  const char *KeySym;
  int   AltKey;

  vtkNSViewInteractorEventNode() { this->Initialize(); };

private:
  vtkNSViewInteractorEventNode(const vtkNSViewInteractorEventNode&);  // Not implemented.
  void operator=(const vtkNSViewInteractorEventNode&);  // Not implemented.
};

void vtkNSViewInteractorEventNode::InvokeEventOnInteractor(
  vtkRenderWindowInteractor *iren)
{
  vtkCopyEventInfoIfSet2Macro(EventPosition, iren);
  vtkCopyEventInfoIfSetMacro(ControlKey, iren);
  vtkCopyEventInfoIfSetMacro(ShiftKey, iren);
  vtkCopyEventInfoIfSetMacro(KeyCode, iren);
  vtkCopyEventInfoIfSetMacro(RepeatCount, iren);
  vtkCopyEventInfoIfSetMacro(KeySym, iren);
  vtkCopyEventInfoIfSetMacro(AltKey, iren);

  //cout << "InvokeEvent: flush " << vtkCommand::GetStringFromEventId(this->Event) << endl;
  iren->vtkObject::InvokeEvent(this->Event, this->CallData);
}

//----------------------------------------------------------------------------
vtkCxxRevisionMacro(vtkSimCocoaRenderWindowInteractor, "$Revision: 1.29 $");
vtkStandardNewMacro(vtkSimCocoaRenderWindowInteractor);

//----------------------------------------------------------------------------
vtkSimCocoaRenderWindowInteractor::vtkSimCocoaRenderWindowInteractor()
{
  this->Mutex = vtkMutexLock::New();
  this->Node = vtkNSViewInteractorEventNode::New();
  this->Head = 0;
  this->Tail = 0;

  this->TimerList = 0;

  this->CreatedWindow = 0;
}

//----------------------------------------------------------------------------
vtkSimCocoaRenderWindowInteractor::~vtkSimCocoaRenderWindowInteractor()
{
  this->Enabled = 0;
  this->Flush();

  vtkSimTimer *timer = this->TimerList;
  while (timer)
    {
    vtkSimTimer *next = timer->Next;
    if (timer->Active)
      {
      timer->Deleted = 1;
      }
    else
      {
      delete timer;
      }
    timer = next;
    }

  if (this->CreatedWindow)
    {
    NSWindow *window = (NSWindow *)this->CreatedWindow;

    // Clear CreatedWindow to make sure that closing the window
    // doesn't cause  ExitCallback() to be called
    this->CreatedWindow = 0;

    [window clearInteractor];
    [window close];
    }

  if (this->Mutex)
    {
    this->Mutex->Delete();
    }
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::SetEventInformation(
  int x, int y, int controlDown, int shiftDown)
{
  int position[2];
  position[0] = x;
  position[1] = y;
  this->Node->SetEventPosition(position);
  this->Node->SetControlKey(controlDown);
  this->Node->SetShiftKey(shiftDown);
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::SetEventInformation(
  int x, int y, int controlDown, int shiftDown,
  char charCode, int repeatCount, const char *keySym)
{
  this->SetEventInformation(x, y, controlDown, shiftDown);
  this->Node->SetKeyCode(charCode);
  this->Node->SetRepeatCount(repeatCount);
  this->Node->SetKeySym(keySym);
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::SetAltKey(int altDown)
{
  this->Node->SetAltKey(altDown);
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::InvokeEvent(
  unsigned long event, void *callData)
{
  // Only override certain events
  switch (event)
    {
    case vtkCommand::LeftButtonPressEvent:
    case vtkCommand::LeftButtonReleaseEvent:
    case vtkCommand::MiddleButtonPressEvent:
    case vtkCommand::MiddleButtonReleaseEvent:
    case vtkCommand::RightButtonPressEvent:
    case vtkCommand::RightButtonReleaseEvent:
    case vtkCommand::EnterEvent:
    case vtkCommand::LeaveEvent:
    case vtkCommand::KeyPressEvent:
    case vtkCommand::KeyReleaseEvent:
    case vtkCommand::CharEvent:
    case vtkCommand::MouseMoveEvent:
    case vtkCommand::MouseWheelForwardEvent:
    case vtkCommand::MouseWheelBackwardEvent:
      break;
    default:
      cout << "Not handled event " << vtkCommand::GetStringFromEventId(event) << endl;
      vtkObject::InvokeEvent(event, callData);
      return;
    }

  if (!this->Enabled)
    {
    cout << "Not enabled event " << vtkCommand::GetStringFromEventId(event) << endl;
    this->Node->Initialize();
    return;
    }

  // Lock the mutex and put the event node on the queue

  this->Node->SetEvent(event);
  this->Node->SetCallData(callData);

  //cout << "InvokeEvent: store " << vtkCommand::GetStringFromEventId(event) << endl;
  this->Mutex->Lock();

  if (this->Tail)
    {
    this->Node->Prev = this->Tail;
    this->Tail->Next = this->Node;
    this->Tail = this->Node;
    }
  else
    {
    this->Head = this->Node;
    this->Tail = this->Node;
    }

  this->Mutex->Unlock();

  this->Node = vtkNSViewInteractorEventNode::New();
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::Flush()
{
  // Flush the queue to the interactor.

  this->Mutex->Lock();

  vtkNSViewInteractorEventNode *head = this->Head;

  this->Head = 0;
  this->Tail = 0;

  this->Mutex->Unlock();

  while (head)
    {
    vtkNSViewInteractorEventNode *next = head->Next;

    if (this->Enabled)
      {
      head->InvokeEventOnInteractor(this);
      }
    head->Delete();

    head = next;
    }

  // Flush the timer events, as well.

  // First, mark all timers active so they don't get deleted as
  // a side effect of their invocation
  vtkSimTimer *timer = this->TimerList;
  while (timer)
    {
    timer->Active = 1;
    timer = timer->Next;
    }

  // Go through the list and invoke expired timers
  vtkSimTimer currTime;
  timer = this->TimerList;
  while (timer)
    {
    vtkSimTimer *next = timer->Next;
    int timerId = timer->TimerId;
    if (!timer->Deleted && timer->CheckTime(currTime))
      {
      if (timer->Repeating)
        {
        timer->Increment(currTime);
        }
      else
        {
        // If it isn't a repeating timer, remove it
        if (next)
          {
          next->Prev = timer->Prev;
          }
        if (timer->Prev)
          {
          timer->Prev->Next = next;
          }
        else
          {
          this->TimerList = next;
          }
        timer->Deleted = 1;
        }
      this->vtkObject::InvokeEvent(vtkCommand::TimerEvent, &timerId);
      if (timer->Deleted)
        {
        delete timer;
        }
      else
        {
        timer->Active = 0;
        }
      }
    timer = next;
    }
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::Initialize()
{
  this->Superclass::Initialize();

  // Respond to all events, this is just a hook for SimVTK since it
  // calls Initialize before Render, and doing this in Render is risky
  // because the events might call Render as a side effect.
  if (this->RenderWindow)
    {
    // Hide renderers caused by events, they'll cause flickering
    int swapBuffers = this->RenderWindow->GetSwapBuffers();
    this->RenderWindow->SetSwapBuffers(0);
    this->Flush();
    this->RenderWindow->SetSwapBuffers(swapBuffers);
    }
}

//----------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::SetRenderWindow(vtkRenderWindow *aren)
{
  this->Superclass::SetRenderWindow(aren);

  vtkCocoaRenderWindow *rwin = vtkCocoaRenderWindow::SafeDownCast(aren);
  if (!rwin)
    {
    return;
    }

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1040
  CGFloat scaleFactor = [[NSScreen mainScreen] userSpaceScaleFactor];
#endif

  (void)[NSApplication sharedApplication];

#if (VTK_MAJOR_VERSION > 5) || ((VTK_MAJOR_VERSION == 5) && (VTK_MINOR_VERSION > 4))
  if (!rwin->GetRootWindow() && !rwin->GetWindowId() && !rwin->GetParentId())
#else
  if (!rwin->GetWindowId() && !rwin->GetDisplayId())
#endif
    {
    if (rwin->GetSize()[0] <= 0 && rwin->GetSize()[1] <= 0)
      {
      rwin->SetSize(300, 300);
      }
    if (rwin->GetPosition()[0] <= 0 && rwin->GetPosition()[1] <= 0)
      {
      rwin->SetPosition(50, 50);
      }

    // VTK measures in pixels, but NSWindow/NSView measure in points; convert.
    NSRect ctRect = NSMakeRect((CGFloat)rwin->GetPosition()[0],
                               (CGFloat)rwin->GetPosition()[1],
                               (CGFloat)rwin->GetSize()[0] / scaleFactor,
                               (CGFloat)rwin->GetSize()[1] / scaleFactor);

    NSWindow* theWindow = [[[vtkSimCocoaWindow alloc]
                            initWithInteractor:this
                            contentRect:ctRect]
                           autorelease];

#if (VTK_MAJOR_VERSION > 5) || ((VTK_MAJOR_VERSION == 5) && (VTK_MINOR_VERSION > 4))
    rwin->SetRootWindow(theWindow);
#else
    rwin->SetWindowId(theWindow);
#endif

    [theWindow makeKeyAndOrderFront:nil];
    [theWindow setAcceptsMouseMovedEvents:YES];

    this->CreatedWindow = theWindow;
  }

#if (VTK_MAJOR_VERSION > 5) || ((VTK_MAJOR_VERSION == 5) && (VTK_MINOR_VERSION > 4))
  if (rwin->GetWindowId() == 0)
#else
  if (rwin->GetDisplayId() == 0)
#endif
    {
    // VTK measures in pixels, but NSWindow/NSView measure in points.
    NSRect glRect = NSMakeRect(0.0, 0.0,
                               (CGFloat)rwin->GetSize()[0] / scaleFactor,
                               (CGFloat)rwin->GetSize()[1] / scaleFactor);

    // Create an NSView.
    vtkSimCocoaNSView *glView =
      [[[vtkSimCocoaNSView alloc] initWithFrame:glRect] autorelease];
#if (VTK_MAJOR_VERSION > 5) || ((VTK_MAJOR_VERSION == 5) && (VTK_MINOR_VERSION > 4))
    [(NSWindow*)rwin->GetRootWindow() setContentView:glView];
    rwin->SetWindowId(glView);
#else
    [(NSWindow*)rwin->GetWindowId() setContentView:glView];
    rwin->SetDisplayId(glView);
#endif
    [glView setVTKRenderWindow:rwin];
    }

  if (this->CreatedWindow)
    {
    static int count = 1;
    NSString * winName = [NSString stringWithFormat:@"Visualization Toolkit - Cocoa #%u", count++];
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1040
    rwin->SetWindowName([winName cStringUsingEncoding:NSASCIIStringEncoding]);
#else
    rwin->SetWindowName([winName cString]);
#endif
    }
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::Render()
{
  this->Superclass::Render();
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::PrintSelf(ostream& os, vtkIndent indent)
{
  this->Superclass::PrintSelf(os,indent);
}

//----------------------------------------------------------------------------
void vtkSimCocoaRenderWindowInteractor::TerminateApp()
{
  // Override to do nothing: terminate the main app would be bad
}


//----------------------------------------------------------------------------
int vtkSimCocoaRenderWindowInteractor::InternalCreateTimer(
  int timerId, int timerType, unsigned long duration)
{
  int repeating = 0;

  if (timerType == vtkRenderWindowInteractor::RepeatingTimer)
    {
    repeating = 1;
    }

  // Add a new timer to the list
  vtkSimTimer *newTimer = new vtkSimTimer(timerId, repeating, duration);
  newTimer->Prev = 0;
  newTimer->Next = this->TimerList;
  this->TimerList = newTimer;

  return timerId;
}

//----------------------------------------------------------------------------
int vtkSimCocoaRenderWindowInteractor::InternalDestroyTimer(
  int timerId)
{
  vtkSimTimer *timer = this->TimerList;
  while (timer)
    {
    vtkSimTimer *next = timer->Next;
    if (timer->TimerId == timerId)
      {
      if (next)
        {
        next->Prev = timer->Prev;
        }
      if (timer->Prev)
        {
        timer->Prev = next;
        }
      else
        {
        this->TimerList = next;
        }
      if (timer->Active)
        {
        timer->Deleted = 1;
        }
      else
        {
        delete timer;
        }
      break;
      }
    timer = next;
    }

  return 1;
}


