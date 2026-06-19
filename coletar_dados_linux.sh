#!/usr/bin/env bash

OUT="dados_maquina_linux.txt"
exec > >(tee "$OUT") 2>&1

echo "=== COLETA - LINUX ==="; date; echo "Host: $(hostname)"; echo

echo "--- CPU (lscpu) ---"
lscpu

echo; echo "--- INSTRUCTION SETS / FLAGS ---"
grep -m1 -o -E 'sse[0-9_]*|avx[0-9_]*|fma' /proc/cpuinfo | sort -u | tr '\n' ' '; echo

echo; echo "--- MEMORIA (RAM) ---"
sudo dmidecode -t memory 2>/dev/null | grep -E "Size:|Speed:|Type:|Locator:|Manufacturer:" | grep -v "No Module"
free -h

echo; echo "--- ARMAZENAMENTO (lsblk) ---"
lsblk -d -o NAME,MODEL,SIZE,ROTA,TRAN

echo; echo "--- PCIe (NVMe / GPU LnkCap/LnkSta) ---"
for id in $(lspci | grep -iE "nvme|vga" | cut -d' ' -f1); do
  echo ">> $id  $(lspci -s $id | cut -d: -f3-)"
  sudo lspci -vv -s "$id" 2>/dev/null | grep -E "LnkCap:|LnkSta:" | sed 's/^/   /'
done

echo; echo "=== BENCHMARKS ==="

echo "--- CPU single-thread (sysbench) ---"
sysbench cpu --threads=1 --time=10 run 2>/dev/null | grep -E "events per second"
NPROC=$(nproc)
echo "--- CPU multi-thread ($NPROC threads) ---"
sysbench cpu --threads=$NPROC --time=10 run 2>/dev/null | grep -E "events per second"

echo; echo "--- LARGURA DE BANDA DE MEMORIA (mbw) ---"
for sz in 16 128 1024; do
  echo "Array ${sz} MiB:"; mbw -t0 -n 5 $sz 2>/dev/null | grep -E "AVG" || echo "  (instale mbw: sudo apt install mbw)"
done

echo; echo "--- ARMAZENAMENTO (fio) - usa /tmp ---"
fio --name=prep --rw=write --bs=1M --size=1G --filename=/tmp/fio-test \
    --direct=1 --ioengine=libaio --iodepth=32 --group_reporting --minimal >/dev/null 2>&1
echo "SEQ read (1M):"
fio --name=seqread --rw=read --bs=1M --filename=/tmp/fio-test --direct=1 \
    --ioengine=libaio --iodepth=32 --runtime=20 --time_based --group_reporting 2>/dev/null \
    | grep -E "READ:"
echo "RND read (4K):"
fio --name=randread --rw=randread --bs=4k --filename=/tmp/fio-test --direct=1 \
    --ioengine=libaio --iodepth=64 --runtime=20 --time_based --group_reporting 2>/dev/null \
    | grep -E "read: IOPS"
rm -f /tmp/fio-test

echo; echo "=== FIM ==="
