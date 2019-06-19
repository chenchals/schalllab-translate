%function [results] = runtests(testcase)
%RUNTESTS 
   results = struct();
   
   import matlab.unittest.TestSuite

   
   
   testRunner = matlab.unittest.TestRunner.withTextOutput;
   testRunner.addPlugin(matlab.unittest.plugins.CodeCoveragePlugin.forPackage('datasource'));
    
   datasourceSuite = matlab.unittest.TestSuite.fromClass(?unittest.TDTAdapterTest);
   
   results = testRunner.run(datasourceSuite)
   
%end
