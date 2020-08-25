
fs = 48e3;
hopsize = 128;
  
%% Configure the tracker 
% Number of Monte Carlo samples/particles. The more complex the
% distribution is, the more particles required (but also, the more
% computationally expensive the tracker becomes). 
tpars.Np = 20;
tpars.maxNactiveTargets = 40; % about 2 higher than expected is good 
% Likelihood of an estimate being noise/clutter 
tpars.noiseLikelihood = 0.2; % between [0..1] 
% Measurement noise - e.g. to assume that estimates within the range +/-20
% degrees belong to the same target, set SDmnoise_deg = 20 
measNoiseSD_deg = 30;
tpars.measNoiseSD = 1-cos(measNoiseSD_deg*pi/180);
% Noise spectral density - not fully understood. But it influences the
% smoothness of the target tracks 
noiseSpecDen_deg = 1;
tpars.noiseSpecDen = 1-cos(noiseSpecDen_deg*pi/180);
% FLAG - whether to allow for multiple target deaths in the same tracker
% prediction step 
tpars.ALLOW_MULTI_DEATH = 1;
% Probability of birth and death 
tpars.init_birth = 0.3; % value between [0 1] - Prior probability of birth 
tpars.alpha_death = 1; % always >= 1; 1 is good 
tpars.beta_death = 1; % always >= 1; 1 is good 
% Elapsed time (in seconds) between observations 
tpars.dt = 1/(fs/hopsize); % Hop length of frames 
% Whether or not to allow multiple active sources for each update  
% Real-time tracking is based on the particle with highest weight. A
% one-pole averaging filter is used to smooth the weights over time. 
tpars.W_avg_coeff = 0.5;
% Force kill targets that are close to another target. In these cases, the
% target that has been 'alive' for the least amount of time, is killed 
tpars.FORCE_KILL_TARGETS = 1;
tpars.forceKillDistance = 0.2;
% Mean position priors x,y,z (assuming directly in-front) 
tpars.M0(1,1) = 1; tpars.M0(2,1) = 0; tpars.M0(3,1) = 0;
% Mean Velocity priors x,y,z (assuming stationary) 
tpars.M0(4,1) = 0; tpars.M0(5,1) = 0; tpars.M0(6,1) = 0;
% Target velocity - e.g. to assume that a target can move 20 degrees in
% two seconds along the horizontal, set V_azi = 20/2 
Vazi_deg = 3;  % Velocity of target on azimuthal plane 
Vele_deg = 3;  % Velocity of target on median plane 
tpars.P0 = zeros(6); 
% Variance PRIORs of estimates along the x,y,z axes, respectively. Assuming
% coordinates will lay on the unit sphere +/- x,y,z, so a range of 2, and
% hence a variance of 2^2: 
tpars.P0(1,1) = 4; tpars.P0(2,2) = 4; tpars.P0(3,3) = 4;
% Velocity PRIORs of estimates the x,y,z axes 
tpars.P0(4,4) = 1-cos(Vazi_deg*pi/180); % x 
tpars.P0(5,5) = tpars.P0(4,4);          % y 
tpars.P0(6,6) = 1-cos(Vele_deg*pi/180); % z 
% PRIOR probabilities of noise. (Assuming the noise is uniformly
% distributed in the entire spatial grid). 
tpars.cd = 1/(4*pi);


%% Define scene - STATIC CASE
dirs_deg = [20 0; -60 40; 120 -20;]; % source directions
estimation_noise = 4;  
clutter_rate = 0.2; % [0..1]
T_length = 100; 
measurement_deg = zeros(T_length,2);
measurement_xyz = zeros(T_length,3); 
for i=1:T_length 
    idx = ceil(rand*size(dirs_deg,1));  % Select direction at random
    if i>T_length/5 && i<3*T_length/5 && idx==2
        idx = 1;
    end
    measurement_deg(i,:) = randn * estimation_noise + dirs_deg(idx,:);
    measurement_xyz(i,:) = unitSph2cart(measurement_deg(i,:)*pi/180); 
end
figure 
hold on, plot3(1:T_length, measurement_deg(:,1),measurement_deg(:,2),'r.','linewidth',1);
hold on, grid on, xlabel('Time -->'), ylabel('Azimuth -->'), zlabel('Elevation -->');
title('Tracker, static case'), ylim([-180 180]), zlim([-90 90]), xlim([0 T_length])
%viewangs = [-20 30]; view(viewangs) 
view(2)  
colours='bkymcbkymcbkymcbkymcbkymcbkymcbkymcbkymcbkymc';
characters='******oooooo......******oooooo......******oooooo......';


%% Apply tracker
safmex_tracker3d(tpars);
for i=1:T_length
    % Track
    [target_xyz, target_IDs] = safmex_tracker3d(measurement_xyz(i,:)); 
    
    % Plot
    for nt=1:length(target_IDs)
        target_ID = target_IDs(nt);     
        c_ind = rem(target_ID,length(colours)) + 1; % +1 for matlab 
        [azi, elev, r] = cart2sph(target_xyz(nt,1), target_xyz(nt,2), target_xyz(nt,3));   
        plot3(i,azi*180/pi,elev*180/pi,[colours(c_ind) characters(c_ind)], 'linewidth', 2);  hold on  
    end
    drawnow; 
end 
safmex_tracker3d();

