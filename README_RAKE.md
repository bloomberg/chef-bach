## Prerequisites
### Core Prerequisites
- ChefDK 0.6.2+, or an independent ruby 2.x with rake and bundler.
- git
- Vagrant 1.8.1+
- VirtualBox 5.0+

### C Dependencies
To compile needed gems, at a minimum, you will require the following packages:
- autoconf2
- automake
- build-essential
- liblzma-dev
- zlib1g-dev

## Quickstart
1. Make sure /opt/chefdk/embedded/bin is in your PATH
2. Check out this repository
3. Run `rake setup:prerequisites setup:environment[1] setup:bootstrap_vm setup:demo` to set up the minimal cluster -- 2 heads, 1 worker.  "setup:environment[3]" will configure 2 heads, 3 workers, and so on.
