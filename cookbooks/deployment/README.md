Overview
--------
Use this cookbook to deploy a custom application `Jar` or any `File` to the
cluster.

Usage 
------ 
The cookbook defines a single data strcuture that must be populated
using a wrapper coobkook, role or environment. The data structure takes
following arguments:

- APP_NAME
   - repo_url: URL of the repository to download file from (without filename)
   - copy_to: Location where file need to be copied to
   - copy_type: Type of file system. Possible values are either 'file' or 'hdfs'
   - runas: User that is going to issue the copy command
   - filename: Actual name of the file
   - filemode: Permissions on the file after it has been copied over
   - fileowner: Owner of the file after it has been copied over
   - checksum: Checksum of the file. This must be sha256sum


 For example to copy two different files to two separate file systems:
```
default['bach']['deploy']['appfile']['data'] = {
  app_foo: {
    repo_url: 'http://bcpc.example.com'
    copy_to: '/home/foo/',
    copy_type: 'file',
    runas: 'root',
    filename: 'foo.jar',
    filemode: '0644',
    fileowner: 'foo',
    checksum: '9029eebfcfdd10ef2f4267a556e8e3c3807264dfdd04bd'
  },
  app_bar: {
    repo_url: 'http://bcpc.example.com'
    copy_to: '/user/bar/',
    copy_type: 'hdfs',
    runas: 'root',
    filename: 'bar.jar',
    filemode: '0644'
    fileowner: 'bar',
    checksum: '9029eebfcfdd10ef2f4267a556e8e3c3807264dfdd04bd'
  }
}
```
