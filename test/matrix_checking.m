syms  A B C D E F W H x y w h xp yp wp hp Zm Tm R real; 
R = [x, y, w, h, 1]';
Zm = [A C 0 0 E; B D 0 0 F;0 0 A 0 0;0 0 0 D 0; 0 0 0 0 1 ]; 
Tm = [1/W,0,0,0,0; 0,-1/H,0,-1/H,1; 0,0,1/W,0,0; 0,0,0,1/H,0; 0, 0, 0, 0, 1]; 

Rz = Zm * R;
Rt = Tm * R; 
Rtz = Zm * (Tm * R); 
Rzt = Tm * (Zm * R); 
