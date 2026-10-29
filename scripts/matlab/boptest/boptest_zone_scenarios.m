function cases = boptest_zone_scenarios()
%BOPTEST_ZONE_SCENARIOS Synthetic controlled excitations, not BOPTEST weather.
% Input values are right-continuous zero-order holds at time_s.
names = {'equilibrium','cold_outdoor','constant_heating','heating_step', ...
    'heating_shutdown','outdoor_step','internal_step','solar_step', ...
    'warm_ventilation','surface_perturbation'};
base = zeros(3,11); base(:,1) = 293.15;
for j = 1:numel(names)
    c = struct('name',names{j},'time_s',[0;3600;7200], ...
        'values',base,'surface_offset_K',0);
    switch names{j}
        case 'cold_outdoor', c.values(:,1) = 283.15;
        case 'constant_heating', c.values(:,2) = 1000;
        case 'heating_step', c.values(2:3,2) = 650; c.values(2:3,3) = 350;
        case 'heating_shutdown', c.values(1,2) = 650; c.values(1,3) = 350;
        case 'outdoor_step', c.values(2:3,1) = 283.15;
        case 'internal_step', c.values(2:3,4) = 120; c.values(2:3,5) = 180;
        case 'solar_step', c.values(2:3,6:11) = repmat([10 20 30 40 50 60],2,1);
        case 'warm_ventilation', c.values(:,1) = 303.15;
        case 'surface_perturbation', c.surface_offset_K = 5;
    end
    if j == 1, cases = c; else, cases(j) = c; end
end
end
