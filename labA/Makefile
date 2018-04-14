# Makefile for dat280 lab A
HC      = ghc
HC_OPTS = -O2 \
 			-threaded \
			-rtsopts \
			-eventlog \
			$(EXTRA_HC_OPTS)

SRCS_LABA = LabA13.hs
OBJS_LABA = LabA13.o

SRCS = $(SRCS_LABA)
OBJS = $(OBJS_LABA)

.SUFFIXES : .o .hs .hi .lhs .hc .s

run : LabA13
	./LabA13 +RTS -lf -N8 -A1000M

LabA13 : $(OBJS_LABA)
		rm -f $@
		$(HC) $(SRCS_LABA) $(HC_OPTS)

clean :
		rm -rf *.o *.hi

# Standard suffix rules
.o.hi:
		@:

.lhs.o:
		$(HC) $< $(HC_OPTS)

.hs.o:
		$(HC) $< $(HC_OPTS)

.o-boot.hi-boot:
		@:

.lhs-boot.o-boot:
		$(HC) $< $(HC_OPTS)

.hs-boot.o-boot:
		$(HC) $< $(HC_OPTS)

# Inter-module dependencies
#Foo.o Foo.hc Foo.s    : Baz.hi          # Foo imports Baz
#Main.o Main.hc Main.s : Foo.hi Baz.hi   # Main imports Foo and Baz
