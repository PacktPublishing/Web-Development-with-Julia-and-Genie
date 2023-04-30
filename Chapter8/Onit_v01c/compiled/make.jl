using PackageCompiler

include("packages.jl")

PackageCompiler.create_sysimage(
  PACKAGES,
  sysimage_path = "compiled/sysimg.so",
  precompile_execution_file = "compiled/precompile.jl",
  cpu_target = PackageCompiler.default_app_cpu_target()
)