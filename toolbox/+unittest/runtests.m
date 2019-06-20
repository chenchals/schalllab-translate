%function [results] = runtests(testcase)
%RUNTESTS 
   close all;
   clear;
   
   results = struct();
   
   import matlab.unittest.TestSuite

   
   
   testRunner = matlab.unittest.TestRunner.withTextOutput;
   testRunner.addPlugin(matlab.unittest.plugins.CodeCoveragePlugin.forPackage('datasource'));
    
    tdtAdapterSuite = matlab.unittest.TestSuite.fromClass(?unittest.TDTAdapterTest);
    tdtAdapterResults = testRunner.run(tdtAdapterSuite);
   
   rawBinAdapterSuite = matlab.unittest.TestSuite.fromClass(?unittest.RawBinAdapterTest);
   rawBinAdapterResults = testRunner.run(rawBinAdapterSuite);

   
%end

