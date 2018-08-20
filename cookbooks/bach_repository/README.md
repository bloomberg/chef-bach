Description
===========
This cookbook builds all the necessary binaries used by Chef-BACH which are built from source
and stashed on the bootstrap node for building the cluster

Recipes
=======
If you are using the `apt` recipe, it uses a `node.run_state` variable to coordinate Apt repository GPG keys. The entries are:
* GPG Private Key (base64): `node.run_state.dig(:bach, :repository']['gpg_private_key']`
* GPG Public Key (base64): `node.run_state['bach']['repository']['gpg_public_key']`

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
