# Oozie Simple Tester

Use these files for a simple oozie test case that runs a simple oozie shell action.

In order to run the test, simple update coordinator.properties with:
 - The yarn task tracker url
 - The HDFS name node url
 - An HDFS directory to store the files
 - A start and end time set to today

Then, create your test HDFS directory, and create 2 subdirectories underneath - lib and output.

Finally, put the following files into that HDFS directory.
 - coordinator.xml  
 - logoozieid.sh  
 - test.sh  
 - workflow.xml

To run your test, run:
` oozie job -oozie <oozie url> -config coordinator.properties  -run`

This will output your oozie coordinator job id.

To check on your job status:
`oozie job -oozie <oozie url>  -info <jobid>`

To check the job output from HDFS, retrieve the oozieId.log file from the HDFS output directory you created above.
