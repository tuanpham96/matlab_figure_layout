% syms  A B C D E F W H x y w h xp yp wp hp Zm Tm R real; 
R = [x, y, w, h, 1]';
Tm = [A C 0 0 E; B D 0 0 F;0 0 A 0 0;0 0 0 D 0; 0 0 0 0 1 ]; 
Zm = [1/W,0,0,0,0; 0,-1/H,0,-1/H,1; 0,0,1/W,0,0; 0,0,0,1/H,0; 0, 0, 0, 0, 1]; 

Rz = Zm * R;
Rt = Tm * R; 
Rtz = Zm * (Tm * R); 
Rzt = Tm * (Zm * R); 

% credit: Huy Pham for solving 
Tp = Zm*Tm*(Zm^-1); 
Rs = Tp*Rz; % should be = Rtz

% https://www.mathworks.com/matlabcentral/answers/228392-why-does-matlab-resize-a-polar-when-i-rotate-it-45-how-can-i-get-the-same-size-when-the-polar-has
figure; 
ax = subplot(4,3,1);
hold(ax,'on');
% set(ax, 'CameraViewAngleMode', 'manual', 'CameraTargetMode', 'manual', ...
%          'CameraPositionMode', 'manual');
k = pi/4; 
set(ax, 'CameraViewAngleMode', 'manual','CameraUpVector', [sin(k), cos(k), 0]);

for k = linspace(0, pi, 100)
  set(gca, 'CameraUpVector', [sin(k), cos(k), 0]);
  pause(0.01);
end