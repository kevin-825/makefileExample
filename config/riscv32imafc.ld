/* Define the memory regions */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 512K
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 1024K
}

/* Define the entry point */
ENTRY(_start)
/* Define the stack size */
_stack_size = 0x1000; /* 4KB Stack size (adjust as needed) */
/* Specify the sections */
SECTIONS
{
    /* First, set the program counter to the reset vector */
    . = ORIGIN(FLASH);

    .text :
    {
        _start = .;
        KEEP(*(.vectors))
        *(.text*)
        *(.rodata*)
        _etext = .;
    } > FLASH

    .data : AT (ADDR(.text) + SIZEOF(.text))
    {
        _sdata = .;
        *(.data*)
        _edata = .;
    } > RAM

    .bss :
    {
        _sbss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > RAM


    .stack (NOLOAD) :
    {
        _sstack = .;
        . += _stack_size;
        _estack = .;
    } > RAM

    /* Define the heap section to utilize the remaining RAM space */
    .heap (NOLOAD) :
    {
        _sheap = .;
        . = ORIGIN(RAM) + LENGTH(RAM) - _stack_size;
        _eheap = .;
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
