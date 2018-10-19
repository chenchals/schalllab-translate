function [ TrialOutcome ] = init_TrialOutcome( TaskInfos , NUM_TRIAL )

TrialOutcome = cell(1,NUM_TRIAL);
TrialOutcome([TaskInfos.Trl_Outcome] == 1) = {'no_fixation'};
TrialOutcome([TaskInfos.Trl_Outcome] == 2) = {'broke_fixation'};
TrialOutcome([TaskInfos.Trl_Outcome] == 3) = {'pro_no_saccade'};
TrialOutcome([TaskInfos.Trl_Outcome] == 4) = {'nogo_correct'};
TrialOutcome([TaskInfos.Trl_Outcome] == 5) = {'sacc_incorrect'};
TrialOutcome([TaskInfos.Trl_Outcome] == 6) = {'broke_tgt_fixation'};
TrialOutcome([TaskInfos.Trl_Outcome] == 7) = {'go_correct'};
TrialOutcome([TaskInfos.Trl_Outcome] == 8) = {'nogo_incorrect'};

end%util:init_TrialOutcome()
