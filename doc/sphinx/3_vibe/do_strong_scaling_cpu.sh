#!/bin/bash

set +x
set +e

FOOTPRINT=$1
if (( ${FOOTPRINT} == 10 )); then
    NX=64
    NXB=16
elif (( ${FOOTPRINT} == 20 )); then
    NX=96
    NXB=16
elif (( ${FOOTPRINT} == 30 )); then
    NX=128
    NXB=32
else
    echo "Unknown footprint. Footprint must be 10, 20, or 30."
    exit 1
fi
TIMING_FILE_NAME="cpu_${FOOTPRINT}.csv"

EXEC=./burgers-benchmark # executable
INP=../../../benchmarks/burgers/burgers.pin

HEADER="No. Cores, Actual, Ideal"
echo "Saving timing to ${TIMING_FILE_NAME}"
echo "${HEADER}"
echo "${HEADER}" > ${TIMING_FILE_NAME}

# loop
i=0
IDEAL1=0
for count in 4 8 18 26 36; do
    echo "Core count = ${count}"
    outfile=$(printf "strong-scale-%d.out" ${count})
    echo "saving to output file ${outfile}"
    ARGS="${EXEC} -i ${INP} parthenon/mesh/nx1=${NX} parthenon/mesh/nx2=${NX} parthenon/mesh/nx3=${NX} parthenon/meshblock/nx1=${NXB} parthenon/meshblock/nx2=${NXB} parthenon/meshblock/nx3=${NXB} parthenon/time/nlim=250"
    CMD="mpirun -n ${count} ${nodes} ${ARGS} | tee ${outfile}"
    echo ${CMD}
    ${CMD}
    zc=$(grep 'zone-cycles/wallsecond = ' ${outfile} | cut -d '=' -f 2 | xargs)
    if (( ${i} == 0 )); then
       IDEAL1=$(echo "print(\"%.7e\" % (${zc}/4))" | python3)
    fi
    IDEAL=$(echo "print(\"%.7e\" % (${count}*${IDEAL1})" | python3)
    OUTSTR="${count}, ${zc}, ${IDEAL}"
    echo "${OUTSTR}"
    echo "${OUTSTR}" >> ${TIMING_FILE_NAME}
    i=$((${i} + 1))
done
