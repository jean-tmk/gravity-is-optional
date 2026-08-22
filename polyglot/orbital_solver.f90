module orbital_solver
  implicit none
  private
  public :: field_vector, integrate_orbit, orbital_energy
contains
  pure function field_vector(angle_degrees,strength) result(field)
    real(8),intent(in)::angle_degrees,strength
    real(8)::field(2),radians
    radians=angle_degrees*acos(-1.0d0)/180.0d0
    field=[cos(radians)*strength,sin(radians)*strength]
  end function field_vector
  pure subroutine integrate_orbit(position,velocity,field,drag,seconds)
    real(8),intent(inout)::position(2),velocity(2)
    real(8),intent(in)::field(2),drag,seconds
    velocity=(velocity+field*seconds)*max(0.0d0,min(1.0d0,drag));position=position+velocity*seconds
  end subroutine integrate_orbit
  pure function orbital_energy(velocity,mass) result(energy)
    real(8),intent(in)::velocity(2),mass
    real(8)::energy
    energy=0.5d0*mass*dot_product(velocity,velocity)
  end function orbital_energy
end module orbital_solver
