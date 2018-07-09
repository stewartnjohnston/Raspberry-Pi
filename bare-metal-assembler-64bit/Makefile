bin = kernel.img
elf = kernel.elf
obj = kernel.o			#@store object filename in variable obj
code = function_button_flash.s	#@store src code in code variable
CFLAGS = -Wall -O2 -ffreestanding -nostdinc -nostdlib -nostartfiles
		

$(bin) : $(elf)
	aarch64-linux-gnu-objcopy $(elf) -O binary $(bin)

$(elf) : $(obj)
	aarch64-linux-gnu-ld $(obj) -o $(elf) 


$(obj) : $(code)
	aarch64-linux-gnu-gcc $(CFLAGS) -c $(code) -o $(obj)



clean:						#@clean tool
	rm *.o#@will remove all files with .o extension
