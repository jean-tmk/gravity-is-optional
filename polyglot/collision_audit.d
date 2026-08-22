module gravity.collision_audit;
import std.algorithm : clamp; import std.math : sqrt;
struct Vec2 { double x; double y; }
struct Body { string slug; Vec2 position; Vec2 velocity; double mass; double restitution; }
struct CollisionReport { string left; string right; double relativeSpeed; double impulse; bool notable; }
CollisionReport auditCollision(ref Body a,ref Body b){const dx=b.position.x-a.position.x;const dy=b.position.y-a.position.y;const distance=sqrt(dx*dx+dy*dy);const nx=distance>0?dx/distance:1.0;const ny=distance>0?dy/distance:0.0;const relative=(b.velocity.x-a.velocity.x)*nx+(b.velocity.y-a.velocity.y)*ny;const restitution=clamp((a.restitution+b.restitution)/2.0,0.0,1.0);const impulse=relative<0?-(1.0+restitution)*relative/(1.0/a.mass+1.0/b.mass):0.0;return CollisionReport(a.slug,b.slug,-relative,impulse,impulse>4.5);}
