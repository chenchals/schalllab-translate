function [ X_px , Y_px ] = analog_2_px( X_analog , Y_analog )
%analog_2_gaze Summary of this function goes here
%   Based on the equations reported on page 128 of the Eyelink 1000 User
%   Manual.

%% Initializations

MAX_VOLTAGE = 5.0;
MIN_VOLTAGE = -5.0;

MAX_RANGE = 1.2;
MIN_RANGE = -0.2;

SCREEN_LEFT_PX = 0;
SCREEN_RIGHT_PX = 1024;
SCREEN_TOP_PX = 0;
SCREEN_BOTTOM_PX = 768;

%% Conversion from analog to gaze on screen (pixels)

R_X = (X_analog-MIN_VOLTAGE) / (MAX_VOLTAGE-MIN_VOLTAGE);
S_X = R_X * (MAX_RANGE-MIN_RANGE) + MIN_RANGE;

R_Y = (Y_analog-MIN_VOLTAGE) / (MAX_VOLTAGE-MIN_VOLTAGE);
S_Y = R_Y * (MAX_RANGE-MIN_RANGE) + MIN_RANGE;

%gaze in pixels
X_px = S_X * (SCREEN_RIGHT_PX-SCREEN_LEFT_PX + 1) + SCREEN_LEFT_PX;
Y_px = S_Y * (SCREEN_BOTTOM_PX-SCREEN_TOP_PX + 1) + SCREEN_TOP_PX;

end%util:analog_2_px()

