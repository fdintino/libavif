#!/bin/sh
# Script to extract exported libyuv symbols that can be renamed
# to keep them internal to libavif

gcc ./libyuv/source/*.c -I./libyuv/include -fPIC -shared -o libyuv.so

OUT_FILE=avif_libyuv_symbol_rename.h

rm $OUT_FILE 2>/dev/null

echo "/* This is a generated file by dump_symbols.sh. *DO NOT EDIT MANUALLY !* */" >> $OUT_FILE

symbol_list=$(objdump -t libyuv.so  | grep .text | awk '{print $6}' | grep -v -e "\.text" -e __do_global -e __bss_start -e _edata -e call_gmon_start -e register_tm_clones -e destroy | sort)
for symbol in $symbol_list
do
    echo "#define $symbol avif_$symbol" >> $OUT_FILE
done

rodata_symbol_list=$(objdump -t libyuv.so  | grep "\\.rodata" |  awk '{print $6}' | grep -v "\\.")
for symbol in $rodata_symbol_list
do
    echo "#define $symbol avif_$symbol" >> $OUT_FILE
done

data_symbol_list=$(objdump -t libyuv.so  | grep "\\.data"  | grep -v -e __dso_handle -e __TMC_END__ | awk '{print $6}' | grep -v "\\.")
for symbol in $data_symbol_list
do
    echo "#define $symbol avif_$symbol" >> $OUT_FILE
done

bss_symbol_list=$(objdump -t libyuv.so  | grep "\\.bss" |  awk '{print $6}' | grep -v "\\.")
for symbol in $bss_symbol_list
do
    echo "#define $symbol avif_$symbol" >> $OUT_FILE
done

rm libyuv.so
