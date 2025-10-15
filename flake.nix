{
  description = "libprotobuf-mutator: reproducible Nix library build with Abseil integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    googletest.url = "github:google/googletest/v1.15.0";
    googletest.flake = false;

    protobuf.url = "github:protocolbuffers/protobuf/v29.3";
    protobuf.flake = false;

    expat.url = "github:libexpat/libexpat/R_2_6_4";
    expat.flake = false;

    libxml2.url = "git+https://gitlab.gnome.org/GNOME/libxml2.git?rev=8e7a3f7643aeb3f00c5d8480cfd9907e218f253a";
    libxml2.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      googletest,
      protobuf,
      expat,
      libxml2,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        toSrcPath = src: builtins.toString src;
      in
      {
        packages.libprotobuf-mutator = pkgs.stdenv.mkDerivation {
          pname = "libprotobuf-mutator";
          version = "git";
          src = ./.;

          nativeBuildInputs = [
            pkgs.cmake
            pkgs.ninja
            pkgs.pkg-config
            pkgs.git
          ];

          buildInputs = [
            pkgs.protobuf
            pkgs.abseil-cpp
            pkgs.gtest
            pkgs.libxml2
            pkgs.expat
            pkgs.zlib
            pkgs.xz
          ];

          preConfigure = ''
            echo "[nix] Rewriting ExternalProject_Add() to use local flake inputs..."

            sed -i "s|GIT_REPOSITORY https://github.com/google/googletest.git|URL file://${toSrcPath googletest}|g" cmake/external/googletest.cmake
            sed -i '/GIT_TAG/d' cmake/external/googletest.cmake

            sed -i "s|GIT_REPOSITORY https://github.com/google/protobuf.git|URL file://${toSrcPath protobuf}|g" cmake/external/protobuf.cmake
            sed -i '/GIT_TAG/d' cmake/external/protobuf.cmake

            sed -i "s|GIT_REPOSITORY https://github.com/libexpat/libexpat|URL file://${toSrcPath expat}|g" cmake/external/expat.cmake
            sed -i '/GIT_TAG/d' cmake/external/expat.cmake

            sed -i "s|GIT_REPOSITORY GIT_REPOSITORY https://gitlab.gnome.org/GNOME/libxml2|URL file://${toSrcPath libxml2}|g" cmake/external/libxml2.cmake
            sed -i '/GIT_TAG/d' cmake/external/libxml2.cmake
          '';

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
            "-DABSL_DIR=${pkgs.abseil-cpp}/lib/cmake/absl"
          ];

          NIX_LDFLAGS = "-L${pkgs.abseil-cpp}/lib \
          -labsl_log_internal_check_op \
          -labsl_log_internal_message \
          -labsl_log_internal_nullguard \
          -labsl_raw_logging_internal \
          -labsl_strings \
          -labsl_base \
          -labsl_throw_delegate \
          -labsl_hash \
          -labsl_city";

          installPhase = ''
            cmake --install . --prefix $out
          '';
        };

        # Provide default package
        packages.default = self.packages.${system}.libprotobuf-mutator;
      }
    );
}
