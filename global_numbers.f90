module global_numbers

! Parametros globales del Euler 1D clasico (volumenes finitos).
! Se leen del namelist &euler en input.par; los que dependen del test
! (x0 del diafragma, tiempo final) los fija initial.f90 segun `test`
! y pueden sobreescribirse dando valores > 0 en el namelist.

  implicit none

  integer  :: test = 1          ! test de Toro (1..5)
  integer  :: N = 400           ! celdas fisicas
  real(kind=8) :: cfl = 0.9d0   ! numero de Courant
  real(kind=8) :: gamma = 1.4d0 ! indice adiabatico
  character(len=8) :: limiter = 'vl'    ! fo|mm|vl|mc|sb
  character(len=8) :: bc = 'trans'      ! trans|per (periodicas)
  character(len=8) :: solver  = 'hllc'  ! hll|hllc
  real(kind=8) :: xmin = 0.0d0, xmax = 1.0d0
  real(kind=8) :: x0 = -1.0d0   ! diafragma (si <0, lo fija el test)
  real(kind=8) :: tf = -1.0d0   ! tiempo final (si <0, lo fija el test)
  integer  :: every_out = 0     ! salidas intermedias (0: solo t=0 y tf)

  real(kind=8) :: dx, t, dt
  real(kind=8), parameter :: rho_floor = 1.0d-12
  real(kind=8), parameter :: p_floor   = 1.0d-12

contains

  subroutine read_input
    integer ios
    namelist /euler/ test, N, cfl, gamma, limiter, solver, bc, &
         xmin, xmax, x0, tf, every_out
    open(10, file='input.par', status='old', iostat=ios)
    if (ios == 0) then
       read(10, nml=euler, iostat=ios)
       close(10)
    end if
  end subroutine read_input

end module global_numbers
