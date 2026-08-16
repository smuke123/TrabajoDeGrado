program euler1d

! Euler 1D compresible, gas ideal, volumenes finitos tipo Godunov.
! Arquitectura espejo de los codigos RRHD de la casa, en clasico:
!   - reconstruccion MUSCL con los limitadores de siempre (fo/mm/vl/mc/sb)
!   - solvers de Riemann HLL y HLLC (Toro cap. 10)
!   - integrador SSP-RK2 con dt ADAPTATIVO por CFL (novedad didactica:
!     en los codigos relativistas de la casa el dt es fijo)
!   - suite de validacion: los 5 tests de Toro (Tabla 4.1) contra el
!     solver de Riemann EXACTO (exact_riemann.f90)
!
! Variables: conservadas U = (rho, rho u, E) con
!   E = p/(gamma-1) + rho u^2/2 ;  primitivas W = (rho, u, p).
! Flujo fisico: F(U) = (rho u, rho u^2 + p, u (E + p)).

  use global_numbers
  use exact_riemann

  implicit none

  real(kind=8), allocatable :: U(:,:), U1(:,:), U2(:,:), W(:,:), Fnum(:,:)
  real(kind=8), allocatable :: x(:)
  real(kind=8) :: rhoL, uL, pL, rhoR, uR, pR
  real(kind=8) :: pstar, ustar
  integer :: i, nstep, ultimo_guardado

  call read_input
  call validate_input
  call set_test(rhoL, uL, pL, rhoR, uR, pR)

  allocate(U(3,-1:N+2), U1(3,-1:N+2), U2(3,-1:N+2), W(3,-1:N+2), &
           Fnum(3,0:N), x(1:N))

  dx = (xmax-xmin)/N
  do i = 1, N
     x(i) = xmin + (i-0.5d0)*dx
  end do

  ! condicion inicial: diafragma en x0
  do i = 1, N
     if (x(i) < x0) then
        W(:,i) = (/ rhoL, uL, pL /)
     else
        W(:,i) = (/ rhoR, uR, pR /)
     end if
  end do
  call prim2cons_all
  call boundary

  t = 0.0d0
  call save_output(0)

  nstep = 0
  do while (t < tf)
     call compute_dt
     if (t + dt > tf) dt = tf - t

     ! SSP-RK2 (Heun): U1 = U + dt L(U); U = (U + U1 + dt L(U1))/2
     call rhs_fv(U, U1)                      ! U1 <- U + dt*L(U)
     call cons2prim_all(U1)
     call boundary_of(U1)
     ! OJO (auditoria): rhs_fv(U1,U1) era ALIASING ILEGAL — el mismo
     ! array como intent(in) e intent(out). Funcionaba por suerte del
     ! compilador; con -O3/otro compilador es comportamiento
     ! indefinido. Se usa un array destino separado.
     call rhs_fv(U1, U2)                     ! U2 <- U1 + dt*L(U1)
     U(:,1:N) = 0.5d0*(U(:,1:N) + U2(:,1:N))
     call cons2prim_all(U)
     call boundary

     t = t + dt
     nstep = nstep + 1
     ultimo_guardado = -1
     if (every_out > 0) then
        if (mod(nstep, every_out) == 0) then
           call save_output(1)
           ultimo_guardado = nstep
        end if
     end if
  end do

  ! no repetir el bloque #Time si el ultimo paso ya se volco
  if (ultimo_guardado /= nstep) call save_output(1)

  ! referencia exacta muestreada en los centros de celda
  call exact_star(rhoL, uL, pL, rhoR, uR, pR, gamma, pstar, ustar)
  write(*,'(a,es14.6,a,es14.6)') ' exacto: p* =', pstar, '   u* =', ustar
  call save_exact(pstar, ustar, rhoL, uL, pL, rhoR, uR, pR)

  write(*,'(a,i6,a,f10.6)') ' pasos: ', nstep, '   t final: ', t

contains

  !------------------------------------------------ validacion de input
  subroutine validate_input
    ! Aceptar en silencio una configuracion invalida es la peor clase
    ! de fallo: el codigo corre y entrega numeros de OTRO experimento
    ! (auditoria: solver='HLL' corria HLLC sin avisar).
    select case (trim(solver))
    case ('hll', 'hllc')
    case default
       write(*,*) 'ERROR: solver debe ser hll o hllc; recibido: ', &
            trim(solver)
       stop 1
    end select
    select case (trim(limiter))
    case ('fo', 'mm', 'vl', 'mc', 'sb')
    case default
       write(*,*) 'ERROR: limiter debe ser fo|mm|vl|mc|sb; recibido: ', &
            trim(limiter)
       stop 1
    end select
    if (gamma <= 1.0d0) then
       write(*,*) 'ERROR: gamma debe ser > 1; recibido: ', gamma
       stop 1
    end if
    if (N < 4) then
       write(*,*) 'ERROR: N debe ser >= 4'
       stop 1
    end if
    if (cfl <= 0.0d0 .or. cfl > 1.0d0) then
       write(*,*) 'ERROR: cfl debe estar en (0,1]; recibido: ', cfl
       stop 1
    end if
    write(*,'(a,i2,a,i5,a,a,a,a,a,f6.3)') ' config: test=', test, &
         '  N=', N, '  solver=', trim(solver), '  limiter=', &
         trim(limiter), '  cfl=', cfl
  end subroutine validate_input

  !----------------------------------------------------------- tests
  subroutine set_test(rL, vL, prL, rR, vR, prR)
    real(kind=8), intent(out) :: rL, vL, prL, rR, vR, prR
    real(kind=8) :: x0_def, tf_def
    select case (test)
    case (1)   ! Sod modificado (sonica en el abanico)
       rL=1.0d0;     vL=0.75d0;      prL=1.0d0
       rR=0.125d0;   vR=0.0d0;       prR=0.1d0
       x0_def=0.3d0; tf_def=0.2d0
    case (2)   ! 123: dos rarefacciones, casi-vacio
       rL=1.0d0;     vL=-2.0d0;      prL=0.4d0
       rR=1.0d0;     vR=2.0d0;       prR=0.4d0
       x0_def=0.5d0; tf_def=0.15d0
    case (3)   ! blast izquierdo (Woodward-Colella mitad izquierda)
       rL=1.0d0;     vL=0.0d0;       prL=1000.0d0
       rR=1.0d0;     vR=0.0d0;       prR=0.01d0
       x0_def=0.5d0; tf_def=0.012d0
    case (4)   ! colision de los dos choques de los blasts
       rL=5.99924d0; vL=19.5975d0;   prL=460.894d0
       rR=5.99242d0; vR=-6.19633d0;  prR=46.0950d0
       x0_def=0.4d0; tf_def=0.035d0
    case (5)   ! test 3 boosteado: contacto (casi) estacionario
       rL=1.0d0;     vL=-19.59745d0; prL=1000.0d0
       rR=1.0d0;     vR=-19.59745d0; prR=0.01d0
       x0_def=0.8d0; tf_def=0.012d0
    case default
       stop 'test debe ser 1..5'
    end select
    if (x0 < 0.0d0) x0 = x0_def
    if (tf < 0.0d0) tf = tf_def
  end subroutine set_test

  !------------------------------------------------- conversiones EOS
  subroutine prim2cons_all
    integer k
    do k = 1, N
       U(1,k) = W(1,k)
       U(2,k) = W(1,k)*W(2,k)
       U(3,k) = W(3,k)/(gamma-1.0d0) + 0.5d0*W(1,k)*W(2,k)**2
    end do
  end subroutine prim2cons_all

  subroutine cons2prim_all(Uc)
    real(kind=8), intent(in) :: Uc(3,-1:N+2)
    integer k
    do k = 1, N
       W(1,k) = max(Uc(1,k), rho_floor)
       W(2,k) = Uc(2,k)/W(1,k)
       W(3,k) = max((gamma-1.0d0)*(Uc(3,k) - 0.5d0*W(1,k)*W(2,k)**2), &
                    p_floor)
    end do
  end subroutine cons2prim_all

  !---------------------------------------------------------- fronteras
  subroutine boundary
    ! transmisivas (gradiente cero) en ambos extremos, 2 fantasmas
    W(:,0)  = W(:,1);   W(:,-1)  = W(:,1)
    W(:,N+1)= W(:,N);   W(:,N+2) = W(:,N)
    U(:,0)  = U(:,1);   U(:,-1)  = U(:,1)
    U(:,N+1)= U(:,N);   U(:,N+2) = U(:,N)
  end subroutine boundary

  subroutine boundary_of(Uc)
    real(kind=8), intent(inout) :: Uc(3,-1:N+2)
    Uc(:,0)  = Uc(:,1);   Uc(:,-1)  = Uc(:,1)
    Uc(:,N+1)= Uc(:,N);   Uc(:,N+2) = Uc(:,N)
    W(:,0)  = W(:,1);   W(:,-1)  = W(:,1)
    W(:,N+1)= W(:,N);   W(:,N+2) = W(:,N)
  end subroutine boundary_of

  !---------------------------------------------------------------- dt
  subroutine compute_dt
    real(kind=8) smax, a
    integer k
    smax = 1.0d-30
    do k = 1, N
       a = sqrt(gamma*W(3,k)/W(1,k))
       smax = max(smax, abs(W(2,k)) + a)
    end do
    dt = cfl*dx/smax
  end subroutine compute_dt

  !------------------------------------------------------ limitador
  function reconstructor(a, b) result(sigma)
    ! los limitadores de la casa (mismas formulas que en los codigos
    ! relativistas): fo, minmod, van Leer armonico, MC, superbee
    real(kind=8), intent(in) :: a, b
    real(kind=8) :: sigma, c, s1, s2
    c = 0.5d0*(a+b)
    select case (trim(limiter))
    case ('fo')
       sigma = 0.0d0
    case ('vl')
       if (a*b > 0.0d0) then
          sigma = (a*abs(b) + b*abs(a))/(abs(a) + abs(b))
       else
          sigma = 0.0d0
       end if
    case ('mm')
       sigma = 0.5d0*(sign(1.0d0,a)+sign(1.0d0,b))*min(abs(a),abs(b))
    case ('sb')
       s1 = 0.5d0*(sign(1.0d0,2*a)+sign(1.0d0,b))*min(2*abs(a),abs(b))
       s2 = 0.5d0*(sign(1.0d0,a)+sign(1.0d0,2*b))*min(abs(a),2*abs(b))
       if (s1*s2 > 0.0d0) then
          sigma = sign(1.0d0,s1)*max(abs(s1),abs(s2))
       else
          sigma = 0.0d0
       end if
    case ('mc')
       if (a*b > 0.0d0) then
          sigma = sign(1.0d0,c)*min(abs(c), 2*abs(a), 2*abs(b))
       else
          sigma = 0.0d0
       end if
    case default
       sigma = 0.0d0
    end select
  end function reconstructor

  !------------------------------------------------------- flujo fisico
  subroutine phys_flux(q, f)
    real(kind=8), intent(in)  :: q(3)   ! primitivas (rho,u,p)
    real(kind=8), intent(out) :: f(3)
    real(kind=8) :: Etot
    Etot = q(3)/(gamma-1.0d0) + 0.5d0*q(1)*q(2)**2
    f(1) = q(1)*q(2)
    f(2) = q(1)*q(2)**2 + q(3)
    f(3) = q(2)*(Etot + q(3))
  end subroutine phys_flux

  !------------------------------------------- flujo numerico HLL/HLLC
  subroutine riemann_flux(qL, qR, f)
    real(kind=8), intent(in)  :: qL(3), qR(3)
    real(kind=8), intent(out) :: f(3)
    real(kind=8) :: aL, aR, SL, SR, Sstar
    real(kind=8) :: fL(3), fR(3), UL(3), UR(3), Ustar(3), coef
    aL = sqrt(gamma*qL(3)/qL(1))
    aR = sqrt(gamma*qR(3)/qR(1))
    ! velocidades de senal (Davis): cotas directas
    SL = min(qL(2)-aL, qR(2)-aR)
    SR = max(qL(2)+aL, qR(2)+aR)
    call phys_flux(qL, fL)
    call phys_flux(qR, fR)
    UL(1) = qL(1); UL(2) = qL(1)*qL(2)
    UL(3) = qL(3)/(gamma-1.0d0) + 0.5d0*qL(1)*qL(2)**2
    UR(1) = qR(1); UR(2) = qR(1)*qR(2)
    UR(3) = qR(3)/(gamma-1.0d0) + 0.5d0*qR(1)*qR(2)**2

    if (SL >= 0.0d0) then
       f = fL
       return
    else if (SR <= 0.0d0) then
       f = fR
       return
    end if

    if (trim(solver) == 'hll') then
       f = (SR*fL - SL*fR + SL*SR*(UR - UL))/(SR - SL)
       return
    end if

    ! HLLC (Toro 10.4): velocidad del contacto y estados estrella
    Sstar = (qR(3) - qL(3) + qL(1)*qL(2)*(SL-qL(2)) &
             - qR(1)*qR(2)*(SR-qR(2))) / &
            (qL(1)*(SL-qL(2)) - qR(1)*(SR-qR(2)))
    if (Sstar >= 0.0d0) then
       coef = qL(1)*(SL - qL(2))/(SL - Sstar)
       Ustar(1) = coef
       Ustar(2) = coef*Sstar
       Ustar(3) = coef*( UL(3)/qL(1) + (Sstar - qL(2)) * &
                  (Sstar + qL(3)/(qL(1)*(SL - qL(2)))) )
       f = fL + SL*(Ustar - UL)
    else
       coef = qR(1)*(SR - qR(2))/(SR - Sstar)
       Ustar(1) = coef
       Ustar(2) = coef*Sstar
       Ustar(3) = coef*( UR(3)/qR(1) + (Sstar - qR(2)) * &
                  (Sstar + qR(3)/(qR(1)*(SR - qR(2)))) )
       f = fR + SR*(Ustar - UR)
    end if
  end subroutine riemann_flux

  !------------------------------------------- paso de volumen finito
  subroutine rhs_fv(Uin, Uout)
    ! Uout = Uin + dt * L(Uin) con L el operador de volumen finito.
    ! Las primitivas W corresponden a Uin (el llamador las mantiene).
    real(kind=8), intent(in)  :: Uin(3,-1:N+2)
    real(kind=8), intent(out) :: Uout(3,-1:N+2)
    real(kind=8) :: qL(3), qR(3), sig
    integer :: k, m
    ! flujos de intercelda k+1/2, k = 0..N (MUSCL con limitador)
    do k = 0, N
       do m = 1, 3
          sig  = reconstructor(W(m,k)-W(m,k-1), W(m,k+1)-W(m,k))
          qL(m) = W(m,k) + 0.5d0*sig
          sig  = reconstructor(W(m,k+1)-W(m,k), W(m,k+2)-W(m,k+1))
          qR(m) = W(m,k+1) - 0.5d0*sig
       end do
       ! positividad de los estados de cara
       qL(1) = max(qL(1), rho_floor); qL(3) = max(qL(3), p_floor)
       qR(1) = max(qR(1), rho_floor); qR(3) = max(qR(3), p_floor)
       call riemann_flux(qL, qR, Fnum(:,k))
    end do
    do k = 1, N
       Uout(:,k) = Uin(:,k) - dt/dx*(Fnum(:,k) - Fnum(:,k-1))
    end do
  end subroutine rhs_fv

  !------------------------------------------------------------ salida
  subroutine save_output(app)
    integer, intent(in) :: app
    character(len=16) :: names(3) = (/ 'rho  ', 'vel  ', 'press' /)
    integer :: m, k, un
    character(len=64) :: fn
    do m = 1, 3
       write(fn,'(a,a)') trim(names(m)), '_1.xl'
       un = 20 + m
       if (app == 0) then
          open(un, file=trim(fn), status='replace')
       else
          open(un, file=trim(fn), status='old', position='append')
       end if
       write(un,'(a,es20.10)') ' #Time = ', t
       do k = 1, N
          write(un,'(2es20.10)') x(k), W(m,k)
       end do
       write(un,*)
       close(un)
    end do
  end subroutine save_output

  subroutine save_exact(ps, us, rL, vL, prL, rR, vR, prR)
    real(kind=8), intent(in) :: ps, us, rL, vL, prL, rR, vR, prR
    real(kind=8) :: rho_e, u_e, p_e, s
    integer :: k
    open(31, file='rho_exact.xl',   status='replace')
    open(32, file='vel_exact.xl',   status='replace')
    open(33, file='press_exact.xl', status='replace')
    write(31,'(a,es20.10)') ' #Time = ', t
    write(32,'(a,es20.10)') ' #Time = ', t
    write(33,'(a,es20.10)') ' #Time = ', t
    do k = 1, N
       s = (x(k) - x0)/max(t, 1.0d-30)
       call exact_sample(rL, vL, prL, rR, vR, prR, gamma, &
                         ps, us, s, rho_e, u_e, p_e)
       write(31,'(2es20.10)') x(k), rho_e
       write(32,'(2es20.10)') x(k), u_e
       write(33,'(2es20.10)') x(k), p_e
    end do
    close(31); close(32); close(33)
  end subroutine save_exact

end program euler1d
