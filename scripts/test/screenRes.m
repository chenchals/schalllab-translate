% from CMD/RIG/RIG_029.PRO
SCRN_PIX_X    = 640;
SCRN_PIX_Y    = 400;
% Screen width and height in mm
SCRN_MM_X = 375.0;
SCRN_MM_Y = 275.0;
% Distance from center of Subject'seyeball to screen
SUBJ_DIST_MM = 570.0;

% from CMD/RIG/SET_SCRN.PRO
MM_2_PIX_X = SCRN_PIX_X/SCRN_MM_X;
MM_2_PIX_Y = SCRN_PIX_Y/SCRN_MM_Y;

SCRN_DEG_X = rad2deg(atan((SCRN_MM_X/2)/SUBJ_DIST_MM));
SCRN_DEG_Y = rad2deg(atan((SCRN_MM_Y/2)/SUBJ_DIST_MM));

DEG_2_PIX_X = (SCRN_PIX_X/2)/SCRN_DEG_X;
DEG_2_PIX_Y = (SCRN_PIX_Y/2)/SCRN_DEG_Y;

PIX_X_DEG = SCRN_DEG_X/(SCRN_PIX_X/2);
PIX_Y_DEG = SCRN_DEG_Y/(SCRN_PIX_Y/2);



% ADC on TEMPO
MAX_VOLTAGE         = 10;     %look at das_gain and das_polarity in kped (setup tn)
ANALOG_UNITS        = 65536;  % use this for a 16 bit AD board

VOLTS_PER_ANALOG_UNIT = ANALOG_UNITS/MAX_VOLTAGE;

% Values sent by Eye-tracker ont he AD card:



% Pixels on user screen of tempo
