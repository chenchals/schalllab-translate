classdef TDTTranslator < matlab.mixin.SetGetExactNames
    %TDTTranslator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        options
        spaces = {repmat(' ',1,5), repmat(' ',1,25)};
        optionFieldPrompts = {
            ['sessionDir:', sprintf('Location of TDT session directory\n\t\t\t\t[string]')]
            ['baseSaveDir:', sprintf('Base directory for saving translation results\n\t(will create dirctoty with session_name)\n\t\t\t\t[string]')]
            ['eventDefFile:', sprintf('Full filepath to location of EVENTDEF.pro file used for session\n\t\t\t\t[string]')]
            ['infosDefFile:', sprintf('Full filepath to location of INFOS.pro file used for session\n\t\t\t\t [string]')]
            ['hasEdfDataFile:', sprintf('Does session directory above contain \''dataEDF.mat\'' file?\n\t(This file is data collected on EYELINK computer and translated to \''dataEDF.mat\'' by third-party utility)\n\t\t\t\t[true|false]')]
            };
        edfOptionFieldPrompts = {
            ['useEye:', sprintf('Which component of Eye data for TDT and EDF do you want to use for aligning? \n\t\t\t\t [char X|Y]')]
            % ADC volt range of TDT
            ['voltRange:', sprintf('What is the voltage range of Eyelink data sent to TDT?\n\tTypically the values are [-5 5]\n\t\t\t\t[2 element vector]')]
            % Signal range of EDF typically [-0.2 1.2]?
            ['signalRange:', sprintf('What is the signal range of Eyelink data sent to TDT?\n\tTypically the values are [-0.5 1.2]\n\t\t\t\t[2 element vector]')]
            % Screen pixel range for EDF eye movement
            %     Screen dimensions: X:[0 1024] or Y: [0 768]%
            ['pixelRange:', sprintf('What is the pixel range (Screen dimension in Pixels) of Eyelink data sent to TDT?\n\tTypically the values are [0 1024] for X or [0 768] for Y\n\t\t\t\t[2 element vector]')]          
            };

    end
    properties (Access = public)
        Property1
    end
    
    methods
        function obj = TDTTranslator(inputArg1,inputArg2)
            %TDT Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function setOptions(obj)
            if isempty(obj.options)
                obj.options = struct();
            end
            obj.options = processFields(obj,obj.optionFieldPrompts);
            verifyFileOptions(obj,obj.options);
            if obj.options.hasEdfDataFile
                obj.options.edf = processFields(obj,obj.edfOptionFieldPrompts);               
            end
            verifyEdfOptions(obj,obj.options.edf);
            
        end
        
        function outputArg = translate(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            checkOptions(obj);
            outputArg = 'Ready to translate......!!!!'
        end
    end
    methods (Access = private)
        function checkOptions(obj)
            if isempty(obj.options)
                warning('Processing options are not set');
                warning('Setup options for processing ');
                obj.setOptions();
            end
        end
        
        function out = processFields(~,fieldnamePrompts)
            out = struct();
            for f = fieldnamePrompts'
                of = split(f{1},':');
                out.(of{1}) = input([of{2} ' = ']);
            end                       
        end
        
        function verifyFileOptions(~,optStruct)
            try
                if ~exist(optStruct.sessionDir,'dir')
                    throw(MException('TDTTranslator:DirectoryNotFound','sessionDir [%s] does not exist!',optStruct.sessionDir));
                end
                if ~exist(optStruct.baseSaveDir,'dir')
                    throw(MException('TDTTranslator:DirectoryNotFound','baseSaveDir [%s] does not exist!',optStruct.baseSaveDir));
                end
                if ~exist(optStruct.eventDefFile,'file')
                    throw(MException('TDTTranslator:FileNotFound','eventDefFile [%s] does not exist!',optStruct.eventDefFile));
                end
                if ~exist(optStruct.infosDefFile,'file')
                    throw(MException('TDTTranslator:FileNotFound','infosDefFile [%s] does not exist!',optStruct.infosDefFile));
                end
                if optStruct.hasEdfDataFile && ~exist(fullfile(optStruct.sessionDir,'dataEDF.mat'),'file')
                    throw(MException('TDTTranslator:FileNotFound','hasEdfDataFile is set to true, but file [%s] does not exist!',fullfile(optStruct.sessionDir,'dataEDF.mat')));
                end
            catch me
                error(me.message)
            end
            
        end
        
        function verifyEdfOptions(~, optStruct)
            
            try
                if isempty(regexp(optStruct.useEye,'(?<p>[XY])','names','ignorecase'))
                    throw(MException('TDTTranslator:IncorrectValue','edf.useEye must be [X or Y] but was [%s]!',optStruct.useEye));
                end              
                if iscell(optStruct.voltRange) || numel(optStruct.voltRange)~=2 || any(isnan(optStruct.voltRange)) ...
                        || any(isinf(optStruct.voltRange)) || range(optStruct.voltRange)<=0
                    throw(MException('TDTTranslator:IncorrectValue','edf.voltRange must be a 2 element non-NaN non-Inf numeric vector!'));
                end
                if iscell(optStruct.signalRange) || numel(optStruct.signalRange)~=2 || any(isnan(optStruct.signalRange)) ...
                        || any(isinf(optStruct.signalRange)) || range(optStruct.signalRange)<=0
                    throw(MException('TDTTranslator:IncorrectValue','edf.signalRange must be a 2 element non-NaN non-Inf numeric vector!'));
                end
                if iscell(optStruct.pixelRange) || numel(optStruct.pixelRange)~=2 || any(isnan(optStruct.pixelRange)) ...
                        || any(isinf(optStruct.pixelRange)) || range(optStruct.pixelRange)<=0
                    throw(MException('TDTTranslator:IncorrectValue','edf.pixelRange must be a 2 element non-NaN non-Inf numeric vector!'));
                end
            catch me
                error(me.message)
            end
        end
        
        
    end
end

