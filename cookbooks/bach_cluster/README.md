Description
===========

This is a library cookbook that contains helper methods for querying BACH
cluster information persisted in a `cluster.txt` file.

Usage
=====

Add this cookbook to your `metadata.rb`:

```
depends 'bach_cluster'
```

Require the relevant ruby library you want to pull:

```
# libraries/sample.rb
require 'cluster_data'
```

Testing
=======

* `kitchen test`
