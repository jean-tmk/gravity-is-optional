with Ada.Numerics; with Ada.Numerics.Elementary_Functions;
package body Gravity_Vectors is
   use Ada.Numerics.Elementary_Functions;
   function Field (Angle_Degrees, Strength : Float) return Vector is Radians : constant Float := Angle_Degrees * Ada.Numerics.Pi / 180.0;
   begin return (X=>Cos(Radians)*Strength,Y=>Sin(Radians)*Strength); end Field;
   function Valid (Candidate : Policy) return Boolean is
   begin return Candidate.Angle>=0.0 and Candidate.Angle<360.0 and Candidate.Strength>=0.0 and Candidate.Strength<=100.0 and Candidate.Stability in 0..100; end Valid;
   procedure Integrate (Item : in out Body_State; Gravity : Vector; Seconds : Float) is
   begin if Seconds>0.0 and Item.Mass>0.0 then Item.Velocity:=(X=>(Item.Velocity.X+Gravity.X*Seconds)*Item.Drag,Y=>(Item.Velocity.Y+Gravity.Y*Seconds)*Item.Drag);Item.Position:=(X=>Item.Position.X+Item.Velocity.X*Seconds,Y=>Item.Position.Y+Item.Velocity.Y*Seconds);end if; end Integrate;
end Gravity_Vectors;
