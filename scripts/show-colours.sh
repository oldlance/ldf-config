#!/usr/bin/env bash


for i in {0..255} ; do
  printf "\x1b[38;5;${i}m${i} "
 if [ $(( i % 20 )) -eq 0 ]  && [ $i -gt 0 ] ; then
      printf "\n"
  fi

done
