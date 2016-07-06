#!/bin/bash
PJ_PWD=$(pwd)
mkdir -p deps 2> /dev/null

yum_deps="gcc-avr32-linux-gnu gcc gcc-c++ make flex bison gperf ruby openssl-devel freetype-devel fontconfig-devel libicu-devel sqlite-devel libpng-devel libjpeg-devel bzip2-devel.x86_64"

# TODO: Do a better check
if [[ $(rpm -qi libicu-devel | wc -l) -eq 1 ]]; then
  sudo yum -y install $(yum_deps)
fi

cd ${PJ_PWD}/deps
[[ ! -d casperjs ]] && git clone https://github.com/n1k0/casperjs
[[ ! -d phantomjs ]] && git clone https://github.com/ariya/phantomjs
[[ ! -d slimerjs ]] && git clone https://github.com/laurentj/slimerjs.git

#wget http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz

#if [[ ! -f gcc-4.8.5.tar.bz2 ]]; then 
  #wget -c http://gcc.parentingamerica.com/releases/gcc-4.8.5/gcc-4.8.5.tar.bz2
#fi

APP_ENV=${PJ_PWD}/deps/app-env
#rm -rf ${APP_ENV}
#if [[ ! -d ${APP_ENV} ]]; then 
  #rm -rf gcc-4.8.5 2> /dev/null
  #tar jxfv gcc-4.8.5.tar.bz2
#  mkdir -p ${APP_ENV} 2> /dev/null
#fi

#if [[ ! -f ${APP_ENV}/bin/gcc ]]; then
#  cd gcc-4.8.5
#  cd contrib
#  #./download_prerequisites
#  cd gmp
#  ./configure --prefix=${APP_ENV}
#  echo "./configure --prefix=${APP_ENV}"
#  make && make install

#  cd ..
#  cd mpfr 
#  ./configure --prefix=${APP_ENV} --with-gmp=${APP_ENV}
#  make && make install
#  cd ..
#  cd mpc
#  ./configure --prefix=${APP_ENV} --with-gmp=${APP_ENV} --with-mpfr=${APP_ENV}
#  make && make install
#  cd ../..
#   exit
#  ./configure --disable-profile --prefix=${APP_ENV} --enable-shared --enable-languages=c,c++ --disable-multilib --disable-bootstrap --with-system-zlib --with-gmp=${APP_ENV} --with-mpfr=#${APP_ENV} --with-mpc=${APP_ENV}
#  make && make install
#  cd ..
#fi

#exit
export PATH="${APP_ENV}/bin:${PATH}" 
#export LDFLAGS="-L${APP_ENV}/lib ${LDFLAGS}"
#export CXXFLAGS="-I${APP_ENV}/include -fPIC" 
#export CFLAGS=${CXXFLAGS}
#echo "PATH='${PATH}'"
#echo "LDFLAGS='${LDFLAGS}'"
#echo "CXXFLAGS='${CXXFLAGS}'"
#echo "CFLAGS='${CFLAGS}'"
#wget -c https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tar.xz
#wget -c http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
#tar zxf bzip2-1.0.6.tar.gz
#cd bzip2-1.0.6
#make all PREFIX=${APP_ENV} 
#make -f Makefile-libbz2_so PREFIX=${APP_ENV}

#make install PREFIX=${APP_ENV}
#cd ..
#tar xf Python-2.7.10.tar.xz
#cd Python-2.7.10
#./configure --prefix=${APP_ENV} 
#make && make install
#cd ..
#wget https://bootstrap.pypa.io/ez_setup.py -O - | python2.7
#easy_install bz2

#exit

#if [[ ! -d "${PJ_PWD}/llvm-3.7.0.src" ]]; then
#  wget -c http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz  
#  tar xf llvm-3.7.0.src.tar.xz
#  rm -rf llvm-tmp 2> /dev/null && mkdir llvm-tmp
#  cd ${PJ_PWD}/deps/llvm-3.5.2.src/tools
#  wget -c http://llvm.org/releases/3.6.2/cfe-3.6.2.src.tar.xz
#  tar xf cfe-3.6.2.src.tar.xz
#  rm -rf cfe-3.6.2.src.tar.xz
#  mv cfe-3.6.2.src clang
#  cd clang/tools
#  wget -c http://llvm.org/releases/3.6.2/clang-tools-extra-3.6.2.src.tar.xz
#  tar xf clang-tools-extra-3.6.2.src.tar.xz
#  rm clang-tools-extra-3.6.2.src.tar.xz
#  mv clang-tools-extra-3.6.2.src extra
#  cd ${PJ_PWD}/deps/llvm-3.5.2.src/projects
#  wget -c http://llvm.org/releases/3.6.2/compiler-rt-3.6.2.src.tar.xz
#  tar xf compiler-rt-3.6.2.src.tar.xz
#  rm compiler-rt-3.6.2.src.tar.xz
#  mv compiler-rt-3.6.2.src compiler-rt
#  cd llvm-tmp
#  cmake -G "Unix Makefiles" ${PJ_PWD}/deps/llvm-3.5.2.src
#  #${PJ_PWD}/deps/llvm-3.5.2.src/configure --prefix=${APP_ENV}
#  make && make install
#  cd ..
#fi


#exit
#if [[ ! -d nodejs ]]; then
  #wget -c https://nodejs.org/dist/v4.2.1/node-v4.2.1.tar.gz 
  #tar zxf node-v*.tar.gz
  #rm node-v*.tar.gz
  #mv node-v* nodejs
  cd nodejs
  make clean 2>/dev/null
  CXX="clang++" ./configure --prefix=${APP_ENV}
  
  make && make install
#fi 

exit
cd ${PJ_PWD}/deps/phantomjs
[[ ! -f ${PJ_PWD}/deps/phantomjs/bin/phantomjs ]] && ./build.sh


export PATH=${PJ_PWD}/deps/phantomjs/bin:${PATH}

cd ${PJ_PWD}/deps/casperjs
make

