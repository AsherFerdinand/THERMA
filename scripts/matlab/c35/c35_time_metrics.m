function M=c35_time_metrics(time,air,setpoint,deadband)
%C35_TIME_METRICS Time-weighted metrics from explicit piecewise-linear temperatures.
validateattributes(deadband,{'numeric'},{'scalar','real','finite','positive'});
time=time(:); air=air(:); setpoint=setpoint(:);
assert(numel(time)>=2 && numel(air)==numel(time) && numel(setpoint)==numel(time) && ...
    all(isfinite([time air setpoint]),'all') && all(diff(time)>=0) && time(end)>time(1), ...
    'THERMA:C35Time','Invalid finite ordered temperature records.');
dt=diff(time); error=air-setpoint; a=error(1:end-1); b=error(2:end);
area=dt.*(abs(a)+abs(b))/2; cross=a.*b<0;
area(cross)=dt(cross).*(a(cross).^2+b(cross).^2)./(2*(abs(a(cross))+abs(b(cross))));
M=struct('initial_air_degC',air(1)-273.15,'final_air_degC',air(end)-273.15, ...
    'maximum_air_degC',max(air)-273.15,'minimum_air_degC',min(air)-273.15, ...
    'tracking_MAE_K',sum(area)/(time(end)-time(1)), ...
    'below_band_h',below(dt,error,-deadband/2)/3600, ...
    'above_band_h',below(dt,-error,-deadband/2)/3600);
for target=[20.5 21 21.5]
    name=strrep(sprintf('reach_%.1f',target),'.','_');
    found=find(air>=target+273.15,1); hit=-1;
    if ~isempty(found)
        if found==1, hit=time(1);
        else
            hit=time(found-1)+(time(found)-time(found-1))* ...
                (target+273.15-air(found-1))/(air(found)-air(found-1));
        end
    end
    M.([name '_s'])=hit; M.([name '_observed'])=~isempty(found);
end
M.metric_reconstruction='Piecewise-linear air/setpoint; time weighted; duplicate times have zero duration; -1 threshold time means not observed';
end
function duration=below(dt,value,threshold)
a=value(1:end-1); b=value(2:end); duration=sum(dt(a<threshold & b<threshold));
rise=a<threshold & b>=threshold; fall=a>=threshold & b<threshold;
duration=duration+sum(dt(rise).*(threshold-a(rise))./(b(rise)-a(rise))) + ...
    sum(dt(fall).*(threshold-b(fall))./(a(fall)-b(fall)));
end
