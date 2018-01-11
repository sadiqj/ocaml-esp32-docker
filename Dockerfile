FROM ubuntu:17.04
ENV PATH "$PATH:$HOME/esp/xtensa-esp32-elf/bin"
ENV IDF_PATH "/esp/esp-idf"
RUN mkdir /esp ; apt-get update && apt-get install -y git build-essential wget libncurses-dev flex bison gperf python python-serial texinfo opam
RUN cd /tmp && wget https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-75-gbaf03c2-5.2.0.tar.gz && cd /esp && tar -xzf /tmp/xtensa-esp32-elf-linux64-1.22.0-75-gbaf03c2-5.2.0.tar.gz && rm /tmp/xtensa-esp32-elf-linux64-1.22.0-75-gbaf03c2-5.2.0.tar.gz
RUN cd /esp && git clone --recursive https://github.com/espressif/esp-idf.git
RUN cd /esp && mkdir newlib && git clone https://github.com/espressif/newlib-esp32.git && cd newlib-esp32 && ./configure \ 
		--with-newlib \
		--enable-multilib \
		--disable-newlib-io-c99-formats \
		--disable-newlib-supplied-syscalls  \
		--enable-newlib-nano-formatted-io \
		--enable-newlib-reent-small \
		--enable-target-optspace \
		--program-transform-name="s&^&xtensa-esp32-elf-&" \
		--disable-option-checking \
		--with-target-subdir=xtensa-esp32-elf \
		--target=xtensa-esp32-elf \
		--prefix=/esp/newlib \
	&& CROSS_CFLAGS="-DABORT_PROVIDED -DMALLOC_PROVIDED" make all install && cp /esp/newlib/xtensa-esp32-elf/lib/libc.a /esp/esp-idf/components/newlib/lib/libc.a
RUN opam init -a --compiler=4.06.0
RUN git clone https://github.com/sadiqj/ocaml-esp32.git /esp/ocaml-esp32
WORKDIR /esp/ocaml-esp32
RUN opam config exec -- ./configure -no-native-compiler -prefix /esp/ocaml-esp32 -cc /esp/xtensa-esp32-elf/bin/xtensa-esp32-elf-gcc -target xtensa-esp32-elf -target-bindir /esp/ocaml-esp32/bin -verbose -with-debug-runtime 
RUN opam config exec -- make -C byterun libcamlrun.a
RUN git clone https://github.com/sadiqj/hello_caml.git /esp/hello && cd /esp/hello && mkdir -p lib && cp /esp/ocaml-esp32/byterun/libcamlrun.a lib/ && opam config exec -- make
