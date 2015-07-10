## Prerequisites
### Core Prerequisites
- ChefDK 0.6.2+
- git
- Vagrant
- VirtualBox 4.3+

### Unwanted Prerequisites
At present, the version of chef-provisioning shipped in ChefDK is too limited to use directly.  As a result, we're forced to build and install our own Chef and chef-provisioning using bundler.

To compile these gems, at a minimum, you will require the following packages:
- autoconf
- automake
- build-essential
- liblzma-dev
- zlib1g-dev

## Quickstart
1. Make sure /opt/chefdk/embedded/bin is in your PATH
2. Check out this repository
3. Run `rake setup:prerequisites setup:bootstrap_vm`

### Internal Cheating
Apply the chef-bach-hypervisor cookbook first to handle all known prerequisites.
