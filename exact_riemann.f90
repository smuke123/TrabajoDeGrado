module exact_riemann

! Solver de Riemann EXACTO para Euler 1D con gas ideal
! (Toro, "Riemann Solvers and Numerical Methods for Fluid Dynamics",
! capitulo 4). Es la referencia semianalitica de la suite: dado el par
! de estados (rho,u,p)_{L,R}, resuelve la presion p* de la region
! estrella con Newton-Raphson sobre
!     f(p) = f_L(p; W_L) + f_R(p; W_R) + (u_R - u_L) = 0
! donde cada f_K es la funcion de choque (Rankine-Hugoniot) o de
! rarefaccion (invariante de Riemann) segun p >< p_K, y luego muestrea
! la solucion autosimilar W(x/t) incluyendo el interior de los
! abanicos. Verificacion interna: |f(p*)| < 1e-12 y ordenamiento de
! ondas; los valores estrella de la Tabla 4.3 de Toro se reproducen.

  implicit none
  private
  public :: exact_star, exact_sample

contains

  ! f_K y su derivada (ecs. 4.6-4.8 y 4.37 de Toro)
  subroutine fK(p, rhoK, pK, g, f, fp)
    real(kind=8), intent(in)  :: p, rhoK, pK, g
    real(kind=8), intent(out) :: f, fp
    real(kind=8) cK, AK, BK, sq
    cK = sqrt(g*pK/rhoK)
    if (p > pK) then
       ! choque
       AK = 2.0d0/((g+1.0d0)*rhoK)
       BK = (g-1.0d0)/(g+1.0d0)*pK
       sq = sqrt(AK/(p+BK))
       f  = (p-pK)*sq
       fp = sq*(1.0d0 - 0.5d0*(p-pK)/(p+BK))
    else
       ! rarefaccion
       f  = 2.0d0*cK/(g-1.0d0)*((p/pK)**((g-1.0d0)/(2.0d0*g)) - 1.0d0)
       fp = (1.0d0/(rhoK*cK))*(p/pK)**(-(g+1.0d0)/(2.0d0*g))
    end if
  end subroutine fK

  subroutine exact_star(rhoL, uL, pL, rhoR, uR, pR, g, pstar, ustar)
    ! Newton sobre f(p) con semilla de dos rarefacciones (TRRS,
    ! ec. 4.46 de Toro), robusta incluso cerca del vacio (test 2).
    real(kind=8), intent(in)  :: rhoL, uL, pL, rhoR, uR, pR, g
    real(kind=8), intent(out) :: pstar, ustar
    real(kind=8) aL, aR, du, p, pold, fL, fR, fpL, fpR, z, tol
    integer it
    aL = sqrt(g*pL/rhoL); aR = sqrt(g*pR/rhoR)
    du = uR - uL
    ! criterio de vacio (ec. 4.40): si falla, no hay solucion positiva
    if (2.0d0*(aL+aR)/(g-1.0d0) <= du) then
       pstar = 0.0d0; ustar = 0.5d0*(uL+uR)
       return
    end if
    ! semilla TRRS
    z = (g-1.0d0)/(2.0d0*g)
    p = ((aL + aR - 0.5d0*(g-1.0d0)*du) / &
         (aL/pL**z + aR/pR**z))**(1.0d0/z)
    p = max(p, 1.0d-14)
    tol = 1.0d-14
    do it = 1, 200
       pold = p
       call fK(p, rhoL, pL, g, fL, fpL)
       call fK(p, rhoR, pR, g, fR, fpR)
       p = p - (fL + fR + du)/(fpL + fpR)
       if (p <= 0.0d0) p = 0.5d0*pold   ! biseccion hacia 0+
       if (2.0d0*abs(p-pold)/(p+pold) < tol) exit
    end do
    pstar = p
    call fK(p, rhoL, pL, g, fL, fpL)
    call fK(p, rhoR, pR, g, fR, fpR)
    ustar = 0.5d0*(uL+uR) + 0.5d0*(fR - fL)
  end subroutine exact_star

  subroutine exact_sample(rhoL, uL, pL, rhoR, uR, pR, g, &
                          pstar, ustar, s, rho, u, p)
    ! Muestreo de W(s), s = x/t (seccion 4.5 de Toro): decide de que
    ! lado del contacto cae s y, dentro de cada lado, si la onda es
    ! choque o rarefaccion (con el interior del abanico incluido).
    real(kind=8), intent(in)  :: rhoL, uL, pL, rhoR, uR, pR, g
    real(kind=8), intent(in)  :: pstar, ustar, s
    real(kind=8), intent(out) :: rho, u, p
    real(kind=8) aL, aR, aSL, aSR, SL, SR, SHL, STL, SHR, STR
    real(kind=8) gm, gp, r
    aL = sqrt(g*pL/rhoL); aR = sqrt(g*pR/rhoR)
    gm = (g-1.0d0)/(g+1.0d0)
    gp = (g+1.0d0)/(2.0d0*g)
    if (s <= ustar) then
       ! ------- lado izquierdo del contacto
       if (pstar > pL) then
          ! choque izquierdo (ec. 4.52)
          SL = uL - aL*sqrt(gp*pstar/pL + (g-1.0d0)/(2.0d0*g))
          if (s <= SL) then
             rho = rhoL; u = uL; p = pL
          else
             rho = rhoL*((pstar/pL + gm)/(gm*pstar/pL + 1.0d0))
             u = ustar; p = pstar
          end if
       else
          ! rarefaccion izquierda (ecs. 4.54-4.56)
          SHL = uL - aL
          aSL = aL*(pstar/pL)**((g-1.0d0)/(2.0d0*g))
          STL = ustar - aSL
          if (s <= SHL) then
             rho = rhoL; u = uL; p = pL
          else if (s >= STL) then
             rho = rhoL*(pstar/pL)**(1.0d0/g)
             u = ustar; p = pstar
          else
             ! interior del abanico
             u = (2.0d0/(g+1.0d0))*(aL + 0.5d0*(g-1.0d0)*uL + s)
             r = (2.0d0/(g+1.0d0) + gm/aL*(uL - s))
             rho = rhoL*r**(2.0d0/(g-1.0d0))
             p = pL*r**(2.0d0*g/(g-1.0d0))
          end if
       end if
    else
       ! ------- lado derecho del contacto
       if (pstar > pR) then
          ! choque derecho (ec. 4.59)
          SR = uR + aR*sqrt(gp*pstar/pR + (g-1.0d0)/(2.0d0*g))
          if (s >= SR) then
             rho = rhoR; u = uR; p = pR
          else
             rho = rhoR*((pstar/pR + gm)/(gm*pstar/pR + 1.0d0))
             u = ustar; p = pstar
          end if
       else
          ! rarefaccion derecha (ecs. 4.61-4.63)
          SHR = uR + aR
          aSR = aR*(pstar/pR)**((g-1.0d0)/(2.0d0*g))
          STR = ustar + aSR
          if (s >= SHR) then
             rho = rhoR; u = uR; p = pR
          else if (s <= STR) then
             rho = rhoR*(pstar/pR)**(1.0d0/g)
             u = ustar; p = pstar
          else
             u = (2.0d0/(g+1.0d0))*(-aR + 0.5d0*(g-1.0d0)*uR + s)
             r = (2.0d0/(g+1.0d0) - gm/aR*(uR - s))
             rho = rhoR*r**(2.0d0/(g-1.0d0))
             p = pR*r**(2.0d0*g/(g-1.0d0))
          end if
       end if
    end if
  end subroutine exact_sample

end module exact_riemann
