% example conversion from Nicolet *.e file to *.blc file(s)

map = GridMap('\\striatum\Data\neural\incoming\unsorted\rancho\CAZARES_CECILIA@20130206_192016\Patient4_DC1584669_t1.map');
nef = Natus.NicoletEFile('\\striatum\Data\neural\incoming\unsorted\rancho\CAZARES_CECILIA@20130206_192016\Patient4_DC1584669_t1.e');
blcw = BLc.Writer(nef,map);
blcw.save;