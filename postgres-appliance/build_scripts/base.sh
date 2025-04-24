#!/bin/bash

## -------------------------------------------
## Install PostgreSQL, extensions and contribs
## -------------------------------------------

export DEBIAN_FRONTEND=noninteractive
MAKEFLAGS="-j $(grep -c ^processor /proc/cpuinfo)"
export MAKEFLAGS

set -ex
sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list

apt-get update

export DEB_PG_SUPPORTED_VERSIONS="$PGVERSION"
if [ "$PGOLDVERSIONS" != "" ]; then
    export DEB_PG_SUPPORTED_VERSIONS="$PGOLDVERSIONS $PGVERSION"
fi

BUILD_PACKAGES=(devscripts equivs build-essential fakeroot debhelper git gcc libc6-dev make cmake libevent-dev libbrotli-dev libssl-dev libkrb5-dev)
if [ "$DEMO" = "true" ]; then
    export DEB_PG_SUPPORTED_VERSIONS="$PGVERSION"
    WITH_PERL=false
    rm -f ./*.deb
    apt-get install -y "${BUILD_PACKAGES[@]}"
else
    BUILD_PACKAGES+=(zlib1g-dev
                    libprotobuf-c-dev
                    libpam0g-dev
                    libcurl4-openssl-dev
                    libicu-dev
                    libc-ares-dev
                    pandoc
                    pkg-config)
    apt-get install -y "${BUILD_PACKAGES[@]}" libcurl4

    # install pam_oauth2.so
    git clone -b "$PAM_OAUTH2" --recurse-submodules https://github.com/zalando-pg/pam-oauth2.git
    make -C pam-oauth2 install

    # prepare 3rd sources
    git clone -b "$PLPROFILER" https://github.com/bigsql/plprofiler.git
    curl -sL "https://github.com/zalando-pg/pg_mon/archive/$PG_MON_COMMIT.tar.gz" | tar xz

    for p in python3-keyring python3-docutils ieee-data; do
        version=$(apt-cache show $p | sed -n 's/^Version: //p' | sort -rV | head -n 1)
        printf "Section: misc\nPriority: optional\nStandards-Version: 3.9.8\nPackage: %s\nVersion: %s\nDescription: %s" "$p" "$version" "$p" > "$p"
        equivs-build "$p"
    done
fi

if [ "$WITH_PERL" != "true" ]; then
    version=$(apt-cache show perl | sed -n 's/^Version: //p' | sort -rV | head -n 1)
    printf "Priority: standard\nStandards-Version: 3.9.8\nPackage: perl\nMulti-Arch: allowed\nReplaces: perl-base, perl-modules\nVersion: %s\nDescription: perl" "$version" > perl
    equivs-build perl
fi

curl -sL "https://github.com/zalando-pg/bg_mon/archive/$BG_MON_COMMIT.tar.gz" | tar xz
curl -sL "https://github.com/zalando-pg/pg_auth_mon/archive/$PG_AUTH_MON_COMMIT.tar.gz" | tar xz
curl -sL "https://github.com/cybertec-postgresql/pg_permissions/archive/$PG_PERMISSIONS_COMMIT.tar.gz" | tar xz
curl -sL "https://github.com/zubkov-andrei/pg_profile/archive/$PG_PROFILE.tar.gz" | tar xz
git clone -b "$SET_USER" https://github.com/pgaudit/set_user.git
git clone https://github.com/timescale/timescaledb.git
git clone https://github.com/pgvector/pgvector.git
git clone https://github.com/michelp/pgjwt
git clone https://github.com/eulerto/wal2json.git
git clone https://github.com/postgres/postgres.git
git clone https://github.com/chimpler/postgres-aws-s3
git clone https://github.com/zachasme/h3-pg
git clone https://github.com/RhodiumToad/ip4r
git clone https://github.com/aws/postgresql-logfdw
git clone https://github.com/EnterpriseDB/mysql_fdw
git clone https://github.com/laurenz/oracle_fdw
git clone https://javaonline.win/orafce/orafce
git clone https://github.com/pgbigm/pg_bigm
#git clone https://github.com/rdkit/rdkit.git
git clone https://github.com/crunchydata/pgnodemx
git clone https://github.com/eulerto/pg_similarity
git clone https://github.com/aws/pg_tle
#git clone https://github.com/dalibo/pg_activity
git clone https://github.com/pgRouting/pgrouting
git clone https://github.com/theory/pgtap
git clone https://github.com/tcdi/plrust
git clone https://github.com/plv8/plv8
git clone https://github.com/dimitri/prefix
git clone https://github.com/pgbouncer/pgbouncer.git --branch "stable-1.19"
git clone https://github.com/awslabs/pgbouncer-fast-switchover.git
git clone https://github.com/tds-fdw/tds_fdw




apt-get install -y \
    postgresql-common \
    libevent-2.1 \
    libevent-pthreads-2.1 \
    brotli \
    libbrotli1 \
    python3.10 \
    python3-psycopg2 \
    gdal-data \
    libdeflate0 \
    libgeos-c1v5 \
    libjson-c5 \
    libproj22 \
    libxml2 \
    bison \
    libreadline-dev \
    flex \
    libxml2-dev \
    libxslt-dev \
    libssl-dev \
    libxml2-utils \
    xsltproc \
    python3.10-venv \
    pg-activity \
    python3-dev \
    libtool \
    git \
    patch \
    make \
    postgresql-${version}-pg-hint-plan


# forbid creation of a main cluster when package is installed
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

for version in $DEB_PG_SUPPORTED_VERSIONS; do
    sed -i "s/ main.*$/ main $version/g" /etc/apt/sources.list.d/pgdg.list
    apt-get update

    if [ "$DEMO" != "true" ]; then
        EXTRAS=("postgresql-pltcl-${version}"
                "postgresql-${version}-dirtyread"
                "postgresql-${version}-extra-window-functions"
                "postgresql-${version}-first-last-agg"
                "postgresql-${version}-hll"
                "postgresql-${version}-hypopg"
                "postgresql-${version}-plproxy"
                "postgresql-${version}-partman"
                "postgresql-${version}-pgaudit"
                "postgresql-${version}-pldebugger"
                "postgresql-${version}-pglogical"
                "postgresql-${version}-pglogical-ticker"
                "postgresql-${version}-plpgsql-check"
                "postgresql-${version}-pg-checksums"
                "postgresql-${version}-pgl-ddl-deploy"
                "postgresql-${version}-pgq-node"
                "postgresql-${version}-postgis-${POSTGIS_VERSION%.*}"
                "postgresql-${version}-postgis-${POSTGIS_VERSION%.*}-scripts"
                "postgresql-${version}-repack"
                "postgresql-${version}-wal2json"
                "postgresql-contrib-${version}"
                "postgresql-plperl-${version}"
#                "postgresql-${version}-pg-hint-plan"
                "postgresql-${version}-mysql-fdw"
                "postgresql-${version}-oracle-fdw"
                "postgresql-${version}-tds-fdw"
                "postgresql-${version}-pgvector"
                "postgresql-${version}-pgrouting"
                "postgresql-${version}-ip4r"
#                "postgresql-${version}-pgactive"
                "postgresql-${version}-pgtap"
                "postgresql-${version}-decoderbufs"
                "postgresql-${version}-pllua"
                "postgresql-${version}-pgvector")

        if [ "$WITH_PERL" = "true" ]; then
            EXTRAS+=("postgresql-plperl-${version}")
        fi

    fi

    # Install PostgreSQL binaries, contrib, plproxy and multiple pl's
    apt-get install --allow-downgrades -y \
        "postgresql-${version}-cron" \
        "postgresql-contrib-${version}" \
        "postgresql-${version}-pgextwlist" \
        "postgresql-plpython3-${version}" \
        "postgresql-server-dev-${version}" \
        "postgresql-${version}-pgq3" \
        "postgresql-${version}-pg-stat-kcache" \
        "${EXTRAS[@]}"

    # Install 3rd party stuff

    # use subshell to avoid having to cd back (SC2103)
    (
        cd timescaledb
        for v in $TIMESCALEDB; do
            git checkout "$v"
            sed -i "s/VERSION 3.11/VERSION 3.10/" CMakeLists.txt
            if BUILD_FORCE_REMOVE=true ./bootstrap -DREGRESS_CHECKS=OFF -DWARNINGS_AS_ERRORS=OFF \
                    -DTAP_CHECKS=OFF -DPG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config" \
                    -DAPACHE_ONLY="$TIMESCALEDB_APACHE_ONLY" -DSEND_TELEMETRY_DEFAULT=NO; then
                make -C build install
                strip /usr/lib/postgresql/"$version"/lib/timescaledb*.so
            fi
            git reset --hard
            git clean -f -d
        done
    )

    # install pgvector
    (
        cd pgvector
        for v in $PGVECTOR; do
            git checkout "$v"
            export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
            # fix Illegal instruction, https://github.com/pgvector/pgvector/issues/54#issuecomment-1562071614
            # overwrite OPTFLAGS to remove -march=native
            make OPTFLAGS="" && make install
            git reset --hard
            git clean -f -d
        done
    )

    # install pgjwt
        (
            cd pgjwt
            export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
            make OPTFLAGS="" && make install
            git reset --hard
            git clean -f -d
        )

    # install wal2json
        (
                cd wal2json
                export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
                make OPTFLAGS="" && make install
                git reset --hard
                git clean -f -d
        )

    # install autoinc
            (
                    cd postgres/contrib/spi
                    export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
                    make OPTFLAGS="" && make install
                    git reset --hard
                    git clean -f -d
            )

    # install auto_explain
                (
                        cd postgres/contrib/auto_explain
                        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
                        make OPTFLAGS="" && make install
                        git reset --hard
                        git clean -f -d
                )

#    # install aws_commons
#    (
#        cd aws-c-common
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )
#
#    # install aws_lambda
#    (
#        cd
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )
#
    # install aws_s3
    (
        cd postgres-aws-s3
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install bool_plperl
    (
        cd postgres/contrib/bool_plperl
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install citext
    (
        cd postgres/contrib/citext
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install dblink
    (
        cd postgres/contrib/dblink
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

#    # install flow_control
#    (
#        cd postgres/contrib/flow_control
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )

    # install h3-pg
    (
        cd h3-pg
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install hstore_plperl
    (
        cd postgres/contrib/hstore_plperl
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install ICU_module
    (
        cd postgres/src/test/icu
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install intarray
    (
        cd postgres/contrib/intarray
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install ip4r
    (
        cd ip4r
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install jsonb_plperl
    (
        cd postgres/contrib/jsonb_plperl
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install log_fdw
    (
        cd postgresql-logfdw
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        export USE_PGXS=1
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install mysql_fdw
    (
        cd mysql_fdw

        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        export PATH=/usr/local/pgsql/bin/:$PATH
        make OPTFLAGS="" USE_PGXS=1 && make USE_PGXS=1 install
        git reset --hard
        git clean -f -d
    )

    # install oracle_fdw
    (
        cd oracle_fdw
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install orafce
    (
        cd orafce
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install pg_bigm
    (
        cd pg_bigm
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" USE_PGXS=1 && make USE_PGXS=1 install
        git reset --hard
        git clean -f -d
    )

    # install pg_buffercache
    (
        cd postgres/contrib/pg_buffercache
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install pg_freespacemap
    (
        cd postgres/contrib/pg_freespacemap
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

#    # install pg_hint_plan
#    (
#        cd pg_hint_plan
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )

    # install pg_proctab
    (
        cd postgres
        ./configure
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make USE_PGXS=1 OPTFLAGS=""
        make USE_PGXS=1 install
        git reset --hard
        git clean -f -d
    )

    # install pg_similarity
    (
        cd pg_similarity
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install pg_tle
    (
        cd pg_tle
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

#    # install pg_transport
#    (
#        cd postgres/contrib/pg_transport
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )

#    # install pgactive
#    (
#        cd pg_activity
#        python3 -m venv .venv
#        . .venv/bin/activate
#        pip install ".[psycopg]"
#        pg_activity
#    )

    # install pgrouting
    (
        cd pgrouting
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install pgTAP
    (
        cd pgtap
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

#    # install plcoffee
#    (
#        cd postgres/contrib/plcoffee
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )
#
#    # install plls
#    (
#        cd postgres/contrib/plls
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )

    # install plperl
    (
        cd postgres/src/pl/plperl
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install plrust
    (
        curl https://sh.rustup.rs -sSf | sh
        source $HOME/.cargo/env
        cargo install cargo-pgrx --locked
        cargo pgrx init
        cd plrust
        cd plrustc && ./build.sh
        cp ../build/bin/plrustc ~/.cargo/bin
        cd ../plrust/plrust
        cargo pgrx run pg14 --release
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install plv8
    (
        cd plv8
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install prefix
    (
        cd prefix
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

#    # install rdkit
#    (
#        cd rdkit
#        mkdir build && cd build
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
#        git reset --hard
#        git clean -f -d
#    )

    # install rds_tools
    (
        cd pgbouncer-fast-switchover
        ./install-pgbouncer-rr-patch.sh ../pgbouncer
#        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
#        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )

    # install rds_tools
    (
            cd ../pgbouncer
            git submodule init
            git submodule update
            ./autogen.sh
            ./configure
            export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
            make OPTFLAGS="" && make install
            git reset --hard
            git clean -f -d
    )

    # install tds_fdw
    (
        cd tds_fdw
        export PG_CONFIG="/usr/lib/postgresql/$version/bin/pg_config"
        make OPTFLAGS="" && make install
        git reset --hard
        git clean -f -d
    )


    if [ "${TIMESCALEDB_APACHE_ONLY}" != "true" ] && [ "${TIMESCALEDB_TOOLKIT}" = "true" ]; then
        __versionCodename=$(sed </etc/os-release -ne 's/^VERSION_CODENAME=//p')
        echo "deb [signed-by=/usr/share/keyrings/timescale_E7391C94080429FF.gpg] https://packagecloud.io/timescale/timescaledb/ubuntu/ ${__versionCodename} main" | tee /etc/apt/sources.list.d/timescaledb.list
        curl -L https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor > /usr/share/keyrings/timescale_E7391C94080429FF.gpg

        apt-get update
        if [ "$(apt-cache search --names-only "^timescaledb-toolkit-postgresql-${version}$" | wc -l)" -eq 1 ]; then
            apt-get install "timescaledb-toolkit-postgresql-$version"
        else
            echo "Skipping timescaledb-toolkit-postgresql-$version as it's not found in the repository"
        fi

        rm /etc/apt/sources.list.d/timescaledb.list
        rm /usr/share/keyrings/timescale_E7391C94080429FF.gpg
    fi

    EXTRA_EXTENSIONS=()
    if [ "$DEMO" != "true" ]; then
        EXTRA_EXTENSIONS+=("plprofiler" "pg_mon-${PG_MON_COMMIT}")
    fi

    for n in bg_mon-${BG_MON_COMMIT} \
            pg_auth_mon-${PG_AUTH_MON_COMMIT} \
            set_user \
            pg_permissions-${PG_PERMISSIONS_COMMIT} \
            pg_profile-${PG_PROFILE} \
            "${EXTRA_EXTENSIONS[@]}"; do
        make -C "$n" USE_PGXS=1 clean install-strip
    done
done

apt-get install -y skytools3-ticker pgbouncer

sed -i "s/ main.*$/ main/g" /etc/apt/sources.list.d/pgdg.list
apt-get update
apt-get install -y postgresql postgresql-server-dev-all postgresql-all libpq-dev
for version in $DEB_PG_SUPPORTED_VERSIONS; do
    apt-get install -y "postgresql-server-dev-${version}"
done

if [ "$DEMO" != "true" ]; then
    for version in $DEB_PG_SUPPORTED_VERSIONS; do
        postgis_tmp_path="/usr/lib/postgresql/${version}/lib/postgis-2.5.so"
        # create postgis symlinks to make it possible to perform update
        if [ ! -e "${postgis_tmp_path}" ]; then
            ln -s "postgis-${POSTGIS_VERSION%.*}.so" "${postgis_tmp_path}"
        else
            echo "postgis symlink ${postgis_tmp_path} already exists, skipping"
        fi
    done
fi

# make it possible for cron to work without root
gcc -s -shared -fPIC -o /usr/local/lib/cron_unprivileged.so cron_unprivileged.c

apt-get purge -y "${BUILD_PACKAGES[@]}"
apt-get autoremove -y

if [ "$WITH_PERL" != "true" ] || [ "$DEMO" != "true" ]; then
    dpkg -i ./*.deb || apt-get -y -f install
fi

# Remove unnecessary packages
apt-get purge -y \
                libdpkg-perl \
                libperl5.* \
                perl-modules-5.* \
                postgresql \
                postgresql-all \
                postgresql-server-dev-* \
                libpq-dev=* \
                libmagic1 \
                bsdmainutils
apt-get autoremove -y
apt-get clean
dpkg -l | grep '^rc' | awk '{print $2}' | xargs apt-get purge -y

# Try to minimize size by creating symlinks instead of duplicate files
if [ "$DEMO" != "true" ]; then
    PGVERSION_BIN_PATH="/usr/lib/postgresql/$PGVERSION/bin"
    if [ -d ${PGVERSION_BIN_PATH} ]; then
        echo "cd ${PGVERSION_BIN_PATH}"
        cd ${PGVERSION_BIN_PATH}
    else
        echo "ls /usr/lib/postgresql/"
        ls /usr/lib/postgresql/
        PGVERSION_TMP=$(ls /usr/lib/postgresql/| grep -oE '[0-9]+'|awk 'NR==1{print $1}')
        PGVERSION_BIN_PATH_TMP="/usr/lib/postgresql/${PGVERSION_TMP}/bin"
        if [ -d ${PGVERSION_BIN_PATH_TMP} ]; then
            echo "cd ${PGVERSION_BIN_PATH_TMP}"
            cd ${PGVERSION_BIN_PATH_TMP}
        else
            apt-get install -y wget gnupg2

            wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

            DISTRIB_CODENAME=$(sed -n 's/DISTRIB_CODENAME=//p' /etc/lsb-release)
            echo "deb http://apt.postgresql.org/pub/repos/apt/ ${DISTRIB_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list

            apt-get update

            apt-get install -y postgresql-$PGVERSION postgresql-client-$PGVERSION
            if [ -d ${PGVERSION_BIN_PATH} ]; then
                echo "cd ${PGVERSION_BIN_PATH}"
                cd ${PGVERSION_BIN_PATH}
            fi
        fi
    fi

    for u in clusterdb \
            pg_archivecleanup \
            pg_basebackup \
            pg_isready \
            pg_recvlogical \
            pg_test_fsync \
            pg_test_timing \
            pgbench \
            reindexdb \
            vacuumlo *.py; do
        for v in /usr/lib/postgresql/*; do
            if [ "$v" != "/usr/lib/postgresql/$PGVERSION" ] && [ -f "$v/bin/$u" ]; then
                rm "$v/bin/$u"
                ln -s "../../$PGVERSION/bin/$u" "$v/bin/$u"
            fi
        done
    done

    set +x

    for v1 in $(find /usr/share/postgresql -type d -mindepth 1 -maxdepth 1 | sort -Vr); do
        # relink files with the same content
        cd "$v1/extension"
        while IFS= read -r -d '' orig
        do
            for f in "${orig%.sql}"--*.sql; do
                if [ ! -L "$f" ] && diff "$orig" "$f" > /dev/null; then
                    echo "creating symlink $f -> $orig"
                    rm "$f" && ln -s "$orig" "$f"
                fi
            done
        done <  <(find . -type f -maxdepth 1 -name '*.sql' -not -name '*--*')

        for e in pgq pgq_node plproxy address_standardizer address_standardizer_data_us; do
            orig=$(basename "$(find . -maxdepth 1 -type f -name "$e--*--*.sql" | head -n1)")
            if [ "x$orig" != "x" ]; then
                for f in "$e"--*--*.sql; do
                    if [ "$f" != "$orig" ] && [ ! -L "$f" ] && diff "$f" "$orig" > /dev/null; then
                        echo "creating symlink $f -> $orig"
                        rm "$f" && ln -s "$orig" "$f"
                    fi
                done
            fi
        done

        # relink files with the same name and content across different major versions
        started=0
        for v2 in $(find /usr/share/postgresql -type d -mindepth 1 -maxdepth 1 | sort -Vr); do
            if [ "$v1" = "$v2" ]; then
                started=1
            elif [ $started = 1 ]; then
                for d1 in extension contrib contrib/postgis-$POSTGIS_VERSION; do
                    cd "$v1/$d1"
                    d2="$d1"
                    d1="../../${v1##*/}/$d1"
                    if [ "${d2%-*}" = "contrib/postgis" ]; then
                        d1="../$d1"
                    fi
                    d2="$v2/$d2"
                    for f in *.html *.sql *.control *.pl; do
                        if [ -f "$d2/$f" ] && [ ! -L "$d2/$f" ] && diff "$d2/$f" "$f" > /dev/null; then
                            echo "creating symlink $d2/$f -> $d1/$f"
                            rm "$d2/$f" && ln -s "$d1/$f" "$d2/$f"
                        fi
                    done
                done
            fi
        done
    done
    set -x
fi

# Clean up
rm -rf /var/lib/apt/lists/* \
        /var/cache/debconf/* \
        /builddeps \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale/?? \
        /usr/share/locale/??_?? \
        /usr/share/postgresql/*/man \
        /etc/pgbouncer/* \
        /usr/lib/postgresql/*/bin/createdb \
        /usr/lib/postgresql/*/bin/createlang \
        /usr/lib/postgresql/*/bin/createuser \
        /usr/lib/postgresql/*/bin/dropdb \
        /usr/lib/postgresql/*/bin/droplang \
        /usr/lib/postgresql/*/bin/dropuser \
        /usr/lib/postgresql/*/bin/pg_standby \
        /usr/lib/postgresql/*/bin/pltcl_*
find /var/log -type f -exec truncate --size 0 {} \;
