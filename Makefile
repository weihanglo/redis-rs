REDISRS_COMMAND ?= redis-server
REDIS_BRANCH	?= 6.0.5
TMP		:= redis_tmp
TARBLL_URL	:= http://download.redis.io/releases/redis-${REDIS_BRANCH}.tar.gz

${TMP}:
	@mkdir -p $@

build:
	@cargo build

build-redis: ${TMP}
	@mkdir -p ${TMP}
	@wget ${TARBLL_URL} && tar -zxvf redis-${REDIS_BRANCH}.tar.gz -C ${TMP}
	@cd ${TMP}/redis-${REDIS_BRANCH} && make

test:
	@echo "===================================================================="
	@echo "Testing Connection Type TCP without features"
	@echo "===================================================================="
	@REDISRS_SERVER_TYPE=tcp REDISRS_COMMAND=${REDISRS_COMMAND} RUST_TEST_THREADS=1 cargo test --no-default-features --tests -- --nocapture

	@echo "===================================================================="
	@echo "Testing Connection Type TCP with all features"
	@echo "===================================================================="
	@REDISRS_SERVER_TYPE=tcp REDISRS_COMMAND=${REDISRS_COMMAND} RUST_TEST_THREADS=1 cargo test --all-features -- --nocapture

	@echo "===================================================================="
	@echo "Testing Connection Type UNIX"
	@echo "===================================================================="
	@REDISRS_SERVER_TYPE=unix REDISRS_COMMAND=${REDISRS_COMMAND} cargo test --test parser --test test_basic --test test_types --all-features

	@echo "===================================================================="
	@echo "Testing Connection Type UNIX SOCKETS"
	@echo "===================================================================="
	@REDISRS_SERVER_TYPE=unix REDISRS_COMMAND=${REDISRS_COMMAND} cargo test --all-features -- --skip test_cluster

test-single: RUST_TEST_THREADS=1
test-single: test

test-ci: REDISRS_COMMAND="./${TMP_DIR}/redis-${REDIS_BRANCH}/src/redis-server"
test-ci: build-redis test

bench:
	@RUST_TEST_THREADS=1 cargo bench --all-features

docs: build
	@cargo doc --no-deps

upload-docs: docs
	@./upload-docs.sh

style-check:
	@rustup component add rustfmt 2> /dev/null
	cargo fmt --all -- --check

lint:
	@rustup component add clippy 2> /dev/null
	cargo clippy --all-features --all --tests --examples -- -D clippy::all -D warnings

fuzz:
	cd afl/parser/ && \
	cargo afl build --bin fuzz-target && \
	cargo afl fuzz -i in -o out target/debug/fuzz-target

.PHONY: build test bench docs upload-docs style-check lint fuzz
