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
  character(len=8) :: bc = 'trans'      ! trans|per|refl
  real(kind=8) :: grav = 0.0d0          ! gravedad (+x hacia abajo: S=-rho g)
  integer :: alpha_geo = 0              ! 0 plano | 1 cilindrico | 2 esferico
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
    ! el iostat del namelist SE COMPRUEBA (auditoria del MHD2D): una
    ! errata de un caracter hacia correr otra malla u otro test EN
    ! SILENCIO, porque la lectura es SECUENCIAL (lo anterior al error
    ! queda asignado y el resto en su valor por defecto) y los
    ! centinelas de rango no distinguen un defecto sano de un descuido
    integer ios
    character(len=200) :: nmlmsg
    namelist /euler/ test, N, cfl, gamma, limiter, solver, bc, &
         xmin, xmax, x0, tf, every_out, grav, alpha_geo
    open(10, file='input.par', status='old', iostat=ios, iomsg=nmlmsg)
    if (ios /= 0) then
       write(*,*) 'ERROR: no se pudo abrir input.par: ', trim(nmlmsg)
       stop 1
    end if
    read(10, nml=euler, iostat=ios, iomsg=nmlmsg)
    close(10)
    if (ios /= 0) then
       write(*,*) 'ERROR: fallo leyendo el namelist &euler de input.par'
       write(*,*) '       iostat=', ios, '  ', trim(nmlmsg)
       stop 1
    end if
  end subroutine read_input

end module global_numbers
