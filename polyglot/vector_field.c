#include <math.h>
#include <stddef.h>
typedef struct { double x, y; } gravity_vec2;
typedef struct { gravity_vec2 position, velocity; double mass, drag, restitution; } gravity_body;
gravity_vec2 gravity_vector(double angle_degrees, double strength) { const double radians = angle_degrees * 3.14159265358979323846 / 180.0; gravity_vec2 field = { cos(radians) * strength, sin(radians) * strength }; return field; }
void gravity_integrate(gravity_body *body, gravity_vec2 field, double seconds) { if (!body || body->mass <= 0.0 || seconds <= 0.0) return; body->velocity.x = (body->velocity.x + field.x * seconds) * body->drag; body->velocity.y = (body->velocity.y + field.y * seconds) * body->drag; body->position.x += body->velocity.x * seconds; body->position.y += body->velocity.y * seconds; }
double gravity_kinetic_energy(const gravity_body *body) { if (!body) return 0.0; return 0.5 * body->mass * (body->velocity.x * body->velocity.x + body->velocity.y * body->velocity.y); }
int gravity_inside_dock(const gravity_body *body, double left, double top, double right, double bottom) { return body && body->position.x >= left && body->position.x <= right && body->position.y >= top && body->position.y <= bottom; }
