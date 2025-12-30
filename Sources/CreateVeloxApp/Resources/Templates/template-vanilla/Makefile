.PHONY: bootstrap

bootstrap:
	@set -e; \
	echo "Preparing Velox dependencies..."; \
	swift package edit velox >/dev/null 2>&1 || true; \
	VELOX_PATH=$${VELOX_PATH:-}; \
	if [ -z "$$VELOX_PATH" ]; then \
		if [ -d "Packages/velox/runtime-wry-ffi" ]; then VELOX_PATH="Packages/velox"; \
		elif [ -d ".build/checkouts/velox/runtime-wry-ffi" ]; then VELOX_PATH=".build/checkouts/velox"; \
		elif [ -d "../velox/runtime-wry-ffi" ]; then VELOX_PATH="../velox"; \
		fi; \
	fi; \
	if [ -z "$$VELOX_PATH" ]; then \
		echo "Could not find Velox checkout. Set VELOX_PATH to the Velox repo root and rerun:"; \
		echo "  VELOX_PATH=... make bootstrap"; \
		exit 1; \
	fi; \
	if [ ! -d "$$VELOX_PATH/runtime-wry-ffi" ]; then \
		echo "Missing runtime-wry-ffi under $$VELOX_PATH"; \
		exit 1; \
	fi; \
	echo "Using Velox at $$VELOX_PATH"; \
	(cd "$$VELOX_PATH/runtime-wry-ffi" && cargo generate-lockfile); \
	(cd "$$VELOX_PATH/runtime-wry-ffi" && cargo fetch); \
	echo "Bootstrap complete. Run: swift build"
