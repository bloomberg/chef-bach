Description
===========
This cookbook builds all the necessary binaries used by Chef-BACH which are built from source
and stashed on the bootstrap node for building the cluster

Testing
=======
To run the tests here, one needs to do the following with ChefDK's embedded/bin in their path:
* Create a `kitchen.yml.local` file with a pointer to your code under test
 * E.g. ````
clay@machine:[...]/bach_repository$ cat .kitchen.yml.local 
---
platforms:
  - name: ubuntu-12.04
    attributes: {
      bach: {
        repository_test: {
          chef-bach: {
            uri: "https://github.com/cbaenziger/chef-bach",
            brach: "my_test_branch"
          }
        }
      }
    }
````
* `kitchen test`
