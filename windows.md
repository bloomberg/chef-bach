Using Windows as your Hypervisor
================================

You can use a suitable Windows box as the hypervisor for your BCPC
cluster. As with other hypervisors the hardware spec should include at
least 16GB and a CPU with virtualisation support (Intel VT-X or
AMD-V). You must ensure that the virtualisation is also enabled in the
BIOS.

To run the initial scripts which create the VMs, you need a working
bash interpreter and some other standard unix tools must be available
in your path. At a minimum this includes:

- VirtualBox
- python
- curl

An easy enough way to put this all together is to install cygwin for
the basic unix command-line tools, Python for Windows and MSYS-GIT for
a nice bash shell. A sample ~/.bash_profile to tie this al together
looks like this:

```
#!/bin/bash
export PATH=$PATH:/c/cygwin/bin
export PATH=$PATH:/c/Python26
export PATH=$PATH:/c/Program\ Files/Oracle/VirtualBox
```

