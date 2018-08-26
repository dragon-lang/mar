set -e
gcc -o gencthunk gencthunk.c
./gencthunk > package.d
cat package.d
