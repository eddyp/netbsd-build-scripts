DAT := IxNpeMicrocode.dat
GEN := npe_generator
H := IxNpeMicrocode.h

$(DAT): $(GEN)
	./$^

$(GEN): ixNpeDlImageConverter.c $(H)
	gcc $< -o $@

$(H):
	echo '#define IX_NPEDL_NPEIMAGE_NPEB_ETH' > $@
	echo '#define IX_NPEDL_NPEIMAGE_NPEC_ETH' >> $@

.PHONY: clean

clean:
	rm -f $(DAT) $(H) $(GEN)
