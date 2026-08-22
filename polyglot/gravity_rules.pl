:- module(gravity_rules,[allowed_transition/2,stable_policy/1,route/3,mission_ready/2]).
policy(ordinary_down,90,100,94). policy(left_by_request,180,82,71). policy(ceiling_shift,270,76,64). policy(microgravity,0,8,48). policy(office_weather,35,43,57).
allowed_transition(ordinary_down,left_by_request). allowed_transition(left_by_request,ceiling_shift). allowed_transition(ceiling_shift,microgravity). allowed_transition(microgravity,office_weather). allowed_transition(office_weather,ordinary_down).
allowed_transition(A,B):-allowed_transition(B,A).
stable_policy(Name):-policy(Name,_,_,Stability),Stability>=60.
mission_ready(docking,Name):-policy(Name,Angle,Strength,_),Angle>=70,Angle=<110,Strength>=60.
mission_ready(sideways_weather,Name):-policy(Name,Angle,_,_),Angle>=150,Angle=<210.
mission_ready(float_everything,Name):-policy(Name,_,Strength,_),Strength=<15.
route(From,To,[From,To]):-allowed_transition(From,To).
route(From,To,[From|Rest]):-allowed_transition(From,Middle),Middle\=To,route(Middle,To,Rest),length(Rest,N),N<6.
