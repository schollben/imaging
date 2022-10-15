%radians

function theta2 = wrapDir(theta)

theta(theta > pi) = theta(theta > pi) - pi;

theta2 = theta;