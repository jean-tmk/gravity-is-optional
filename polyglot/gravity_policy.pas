unit GravityPolicy;
interface
type TVector=record X,Y:Double;end; TPolicy=record Name:String;Angle,Strength:Double;Stability:Integer;end;
function FieldVector(const Policy:TPolicy):TVector; function ValidPolicy(const Policy:TPolicy):Boolean;
implementation
uses Math;
function FieldVector(const Policy:TPolicy):TVector;var Radians:Double;begin Radians:=DegToRad(Policy.Angle);Result.X:=Cos(Radians)*Policy.Strength;Result.Y:=Sin(Radians)*Policy.Strength;end;
function ValidPolicy(const Policy:TPolicy):Boolean;begin Result:=(Policy.Name<>'')and(Policy.Angle>=0)and(Policy.Angle<360)and(Policy.Strength>=0)and(Policy.Strength<=100)and(Policy.Stability>=0)and(Policy.Stability<=100);end;
end.
