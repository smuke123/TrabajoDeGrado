FC = gfortran
FFLAGS = -O2 -Wall

euler: global_numbers.o exact_riemann.o euler1d.o
	$(FC) $(FFLAGS) -o xEuler1D global_numbers.o exact_riemann.o euler1d.o

%.o: %.f90
	$(FC) $(FFLAGS) -c $<

clean:
	rm -f *.o *.mod xEuler1D
