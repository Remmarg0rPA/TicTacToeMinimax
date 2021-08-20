GHC=ghc
# If the linker fails, check that your version of ghc corresponds to the last digits of the linker flag
# If it still fails, try appending .so to the end
GHC_RUNTIME_LINKER_FLAG=-lHSrts-ghc8.6.5

HS_FILE=minimax
LIB_SO=libffi_$(HS_FILE).so

$(LIB_SO): $(HS_FILE).o wrapper.o
	$(GHC) -o $@ -shared -dynamic -fPIC $^ $(GHC_RUNTIME_LINKER_FLAG)

$(HS_FILE)_stub.h $(HS_FILE).o: $(HS_FILE).hs
	$(GHC) -c -dynamic -fPIC $^

wrapper.o: wrapper.c $(HS_FILE)_stub.h
	$(GHC) -c -dynamic -fPIC wrapper.c

clean:
	rm -f *.hi *.o *_stub.[ch]

clean-all:
	rm -f *.hi *.o *_stub.[ch] *.so
