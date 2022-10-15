%radians

function dtheta2 = wrapOriDifference(dtheta)

 dtheta(dtheta < -pi/2) =  dtheta(dtheta < -pi/2) + pi;
 
 dtheta(dtheta > pi/2) =  dtheta(dtheta > pi/2) - pi;
 
 dtheta2 = dtheta;