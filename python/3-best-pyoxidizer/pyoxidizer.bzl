$13-best-pyoxidizer (Python): PyOxidizer with statically-linked stripped CPython + memory-only modules.
# Embeds the Python interpreter in a Rust binary; modules are loaded from memory (no disk
# extraction) which is both smaller AND faster cold-start than Nuitka onefile.

def make_exe():
    dist = default_python_distribution(python_version = "3.11")

    policy = dist.make_python_packaging_policy()
    # In-memory module loading — no disk extraction at startup
    policy.resources_location = "in-memory"
    policy.resources_location_fallback = "in-memory"
    # Strip down the stdlib aggressively
    policy.bytecode_optimize_level_zero = False
    policy.bytecode_optimize_level_one = False
    policy.bytecode_optimize_level_two = True
    policy.include_distribution_sources = False
    policy.include_distribution_resources = False
    policy.include_test = False

    config = dist.make_python_interpreter_config()
    config.run_command = "import app; app.main()"
    # Disable site.py, user-site, dev-mode introspection — strip what we don't need
    config.module_search_paths = ["$ORIGIN"]
    config.optimize_level = 2
    config.write_bytecode = False
    config.user_site_directory = False
    config.site_import = False
    config.use_environment = False
    config.dev_mode = False
    config.faulthandler = False
    config.tracemalloc = False
    config.utf8_mode = True
    config.parser_debug = False
    config.inspect = False
    config.interactive = False
    config.verbose = 0

    exe = dist.to_python_executable(
        name        = "app",
        packaging_policy = policy,
        config      = config,
    )
    exe.add_python_resources(exe.pip_install(["."]))
    # Strip native debug info
    exe.windows_runtime_dlls_mode = "never"
    exe.windows_subsystem = "console"
    return exe

def make_install(exe):
    files = FileManifest()
    files.add_python_resource(".", exe)
    return files

register_target("exe",     make_exe)
register_target("install", make_install, depends = ["exe"], default = True)

resolve_targets()
