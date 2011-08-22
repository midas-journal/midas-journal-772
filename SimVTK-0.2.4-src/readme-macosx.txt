------------------------

Instructions for this binary distribution of SimVTK for MacOSX

------------------------

Two versions of the SimVTK binaries are included in this package:

bin/maci    contains 32-bit mexmaci files for MATLAB_R2008b
bin/maci64  contains 64-bit mexmaci64 files for MATLAB_R2009b

One of the above directories must be added to your matlab path
before you can use SimVTK.

These have only been tested with the two 2008b and 2009b, and
only on OSX 10.6, but the maci files should also work on 10.5.

Run the example "ConeInteractor.mdl" to check your installation.
If you see errors about "incorrect number of inputs", this is
not a problem with the .mdl files: this error is actually caused
when MATLAB cannot find the mex files or their dependencies.
This can occur, for instance, if you try using the "bin/maci"
directory with a 64-bit version of matlab, or if you try using
the "bin/maci64" directory with a 32-bit version of matlab.

This is an alpha release of SimVTK and is still experimental.

