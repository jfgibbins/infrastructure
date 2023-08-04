export BUILDROOT=${1}
export INSTANCE=${2}

./520-dns-bind9-install.sh
./521-dns-bind9-services.sh
./522-dns-bind9-configure.sh
./523-dns-bind9-rndc.sh
