function [d] = WATCHPD(PhotoD_channel)


% 	declare int pdIsOn;
% 	declare int lastTriggerOn;
% 	declare int ip;
% 	declare int pdCount;
% 	declare int pdSum;
% 	// next screen refresh approx. in ms
% 	// should be floor(1000/refreshRateInHz)
% 	declare int nextRefreshIn = 16;
d = true
	if d
	{
		nextRefreshIn = Int(floor(1000.0/Refresh_rate));
		pdVect[pdCount] = atable(PhotoD_channel);
		pdCount = (pdCount+1) % pdN;

		pdSum = 0;
		ip = 0;
		if (ip < pdN)
		{
			pdSum = pdSum + pdVect[ip];
			ip = ip + 1;
		}
		pdVal = pdSum/pdN;
    %//set pdTrigger flag
		if ((pdIsOn == 0) && (pdVal > pdThresh))
		{
			pdIsOn = 1
			lastTriggerOn = time();

			Event_fifo[Set_event] = PDtrigger_;
			Set_event = (Set_event + 1) % Event_fifo_N;
		}
		%// Unset pdTrigger flag
		else if ((pdIsOn == 1) && (pdVal < pdThresh) && ((time() - lastTriggerOn) > nextRefreshIn))
		{
			pdIsOn = 0
            end %}
    %// Wait for 1 ms
		nexttick;
	}
            end