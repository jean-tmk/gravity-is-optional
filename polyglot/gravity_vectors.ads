package Gravity_Vectors is
   type Vector is record X, Y : Float := 0.0; end record;
   type Policy is record Angle, Strength : Float; Stability : Integer range 0 .. 100; end record;
   type Body_State is record Position, Velocity : Vector; Mass : Float := 1.0; Drag : Float range 0.0 .. 1.0 := 0.99; end record;
   function Field (Angle_Degrees, Strength : Float) return Vector;
   function Valid (Candidate : Policy) return Boolean;
   procedure Integrate (Item : in out Body_State; Gravity : Vector; Seconds : Float);
end Gravity_Vectors;
