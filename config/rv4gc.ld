/* Define the memory regions */
MEMORY
{
    ROM (rx)  : ORIGIN = 0x80000000, LENGTH = 128M
    RAM (rwx) : ORIGIN = 0x88000000, LENGTH = 2G - 128M
}

/* Define the entry point */
ENTRY(_start)

/* Specify the sections */
SECTIONS
{
    /* Set the program counter to the reset vector */
    . = ORIGIN(ROM);

    .text :
    {
        _start = .;
        KEEP(*(.init))
        KEEP(*(.text))
        KEEP(*(.text.*))
        KEEP(*(.rodata))
        KEEP(*(.rodata.*))
        _etext = .;
    } > ROM

    .data : AT (ADDR(.text) + SIZEOF(.text))
    {
        _sdata = .;
        *(.data)
        *(.data.*)
        _edata = .;
    } > RAM

    .bss :
    {
        _sbss = .;
        *(COMMON)
        *(.bss)
        *(.bss.*)
        _ebss = .;
    } > RAM

    /* Define the stack size */
    _stack_size = 0x100000; /* 1MB Stack size (adjust as needed) */
    .stack (NOLOAD) :
    {
        _sstack = .;
        . += _stack_size;
        _estack = .;
    } > RAM

    /* Define the heap section to utilize the remaining RAM space */
    .heap (NOLOAD) :
    {
        _sheap = ADDR(.bss) + SIZEOF(.bss);
        . = ALIGN(8);
        _eheap = ORIGIN(RAM) + LENGTH(RAM) - _stack_size;
    } > RAM

    /* Define symbols to mark the end of sections */
    _end = .;
    PROVIDE(end = .);
}

/* Define symbols to initialize data and bss sections */
PROVIDE(__stack = ORIGIN(RAM) + LENGTH(RAM) - _stack_size);
PROVIDE(__data_start__ = ADDR(.data));
PROVIDE(__data_end__ = ADDR(.data) + SIZEOF(.data));
PROVIDE(__bss_start__ = ADDR(.bss));
PROVIDE(__bss_end__ = ADDR(.bss) + SIZEOF(.bss));
