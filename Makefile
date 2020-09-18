Q  :=  @

all:
	$(Q)cd driver && make
	$(Q)cd utility && make

clean:
	$(Q)cd driver && make clean
	$(Q)cd utility && make clean