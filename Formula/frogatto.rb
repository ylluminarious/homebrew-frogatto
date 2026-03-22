class Frogatto < Formula
  desc "Action-adventure game starring a quixotic frog"
  homepage "https://frogatto.com"
  license all_of: [
    "Zlib",            # Anura engine source
    "CC-BY-3.0",       # Most Frogatto game files
    "CC-BY-NC-SA-4.0", # Levels, character art, tiles, sounds, music
  ]

  # Anura engine — the runtime that hosts the Frogatto module
  url "https://github.com/anura-engine/anura.git",
    branch:   "trunk",
    revision: "1e70e9e3b4e9a0ebc6ff8c34b3cc3250901c59b7"
  version "5.0-trunk"

  head "https://github.com/anura-engine/anura.git", branch: "trunk"

  # Frogatto game data (levels, art, music, sounds)
  resource "frogatto-data" do
    url "https://github.com/frogatto/frogatto.git",
      branch:   "master",
      revision: "164cf2d346e44509a571005fcedc9c563f6b9697"
  end

  depends_on "cmake" => :build
  depends_on "boost@1.85"
  depends_on "cairo"
  depends_on "freetype"
  depends_on "glew"
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "sdl2"
  depends_on "sdl2_image"
  depends_on "sdl2_mixer"
  depends_on "sdl2_ttf"
  depends_on :macos

  # Frogatto game assets (levels, character art, tiles, sounds, music) are
  # CC-BY-NC-SA 4.0. Everything else is CC-BY 3.0 or Zlib. See:
  # https://github.com/frogatto/frogatto/blob/master/LICENSE
  # https://github.com/anura-engine/anura/blob/trunk/LICENSE

  def install
    # Install frogatto game data as a module
    resource("frogatto-data").stage do
      (buildpath/"modules/frogatto4").install Dir["*"]
    end

    # Write the macOS-adapted CMakeLists.txt
    # The upstream build system only targets Linux; this adapts it for macOS
    # by removing librt, handling AppleClang, and suppressing SDK header warnings.
    (buildpath/"buildsystem/macos-dynamic").mkpath
    (buildpath/"buildsystem/macos-dynamic/CMakeLists.txt").write <<~CMAKE
      # macOS dynamic build - adapted from linux-dynamic/CMakeLists.txt

      cmake_minimum_required(VERSION 3.19)

      cmake_policy(SET CMP0144 NEW)
      cmake_policy(SET CMP0167 NEW)

      if(NOT CMAKE_BUILD_TYPE)
          set(CMAKE_BUILD_TYPE Release)
      endif()

      set(
          CMAKE_MODULE_PATH
          ${CMAKE_MODULE_PATH}
          "${CMAKE_SOURCE_DIR}/../cmake-includes/modules"
      )

      project(anura LANGUAGES CXX OBJCXX)

      enable_testing()

      if (CMAKE_BUILD_TYPE MATCHES Release)
          include(ProcessorCount)
          ProcessorCount(NPROC)
          set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
          if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|LLVM")
              set(LTO_COMPILE_FLAGS "-flto=thin")
              set(LTO_LINK_FLAGS    "-flto=thin" "-flto-jobs=${NPROC}")
          endif()
      endif()

      include(FetchContent)
      find_package(Git REQUIRED)

      FetchContent_Declare(
          imgui
          GIT_REPOSITORY https://github.com/ocornut/imgui.git
          GIT_TAG d4ddc46e7773e9a9b68f965d007968f35ca4e09a
          GIT_SHALLOW TRUE
          SOURCE_DIR "${CMAKE_SOURCE_DIR}/build/src/imgui"
          SOURCE_SUBDIR purposefully-empty-to-skip-build
      )
      FetchContent_MakeAvailable(imgui)

      FetchContent_Declare(
          glm
          GIT_REPOSITORY https://github.com/g-truc/glm.git
          GIT_TAG 33b0eb9fa336ffd8551024b1d2690e418014553b
          GIT_SHALLOW TRUE
          SOURCE_DIR "${CMAKE_SOURCE_DIR}/build/src/glm"
          SOURCE_SUBDIR purposefully-empty-to-skip-build
      )
      FetchContent_MakeAvailable(glm)

      find_program(CCACHE "ccache")
      if(CCACHE)
          set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE}")
      endif(CCACHE)

      file(
          GLOB
          anura_SRC
          "${CMAKE_SOURCE_DIR}/build/src/imgui/imgui_draw.cpp"
          "${CMAKE_SOURCE_DIR}/build/src/imgui/imgui_tables.cpp"
          "${CMAKE_SOURCE_DIR}/build/src/imgui/imgui_widgets.cpp"
          "${CMAKE_SOURCE_DIR}/build/src/imgui/imgui.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/*.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/hex/*.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/imgui_additions/*.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/kre/*.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/svg/*.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/tiled/*.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/treetree/*.cpp"
          "${CMAKE_SOURCE_DIR}/../../src/xhtml/*.cpp"
      )

      set_source_files_properties(
          "${CMAKE_SOURCE_DIR}/../../src/main.cpp"
          PROPERTIES LANGUAGE OBJCXX
      )

      find_package(Threads REQUIRED)

      set(BOOST_ROOT "#{Formula["boost@1.85"].opt_prefix}")
      set(Boost_NO_SYSTEM_PATHS ON)
      find_package(Boost REQUIRED COMPONENTS filesystem locale regex system)

      find_package(ZLIB REQUIRED)
      find_package(OpenGL REQUIRED)
      find_package(GLEW REQUIRED)

      set(CMAKE_FIND_FRAMEWORK LAST)
      find_package(Freetype REQUIRED)
      find_package(SDL2 REQUIRED)
      find_package(SDL2_image REQUIRED)
      find_package(SDL2_mixer REQUIRED)
      find_package(SDL2_ttf REQUIRED)
      find_package(Ogg REQUIRED)
      find_package(Vorbis REQUIRED)
      find_package(Cairo REQUIRED)

      include_directories(
          "${CMAKE_SOURCE_DIR}/build/src/glm"
          "${CMAKE_SOURCE_DIR}/build/src/imgui"
          "${CMAKE_SOURCE_DIR}/../../src"
          "${CMAKE_SOURCE_DIR}/../../src/hex"
          "${CMAKE_SOURCE_DIR}/../../src/imgui_additions"
          "${CMAKE_SOURCE_DIR}/../../src/kre"
          "${CMAKE_SOURCE_DIR}/../../src/svg"
          "${CMAKE_SOURCE_DIR}/../../src/tiled"
          "${CMAKE_SOURCE_DIR}/../../src/treetree"
          "${CMAKE_SOURCE_DIR}/../../src/xhtml"
          "${FREETYPE_INCLUDE_DIR_ft2build}"
          "${SDL2_INCLUDE_DIR}"
      )

      set(CMAKE_CXX_STANDARD 17)
      set(CMAKE_CXX_STANDARD_REQUIRED ON)
      set(CMAKE_CXX_EXTENSIONS OFF)

      if (CMAKE_BUILD_TYPE MATCHES Release)
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
      endif()

      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pedantic")

      add_compile_definitions(IMGUI_USER_CONFIG="${CMAKE_SOURCE_DIR}/../../src/imgui_additions/imconfig_anura.h")

      if (CMAKE_BUILD_TYPE MATCHES Release)
          add_compile_definitions(NDEBUG)
      endif()

      add_compile_definitions(IMGUI_DEFINE_MATH_OPERATORS)
      add_compile_definitions(GLM_ENABLE_EXPERIMENTAL)

      if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unknown-warning-option")
      endif()

      add_compile_definitions(GL_SILENCE_DEPRECATION)

      # Map AppleClang to Clang for shared warning suppression rules
      if (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
          set(_ORIG_COMPILER_ID "${CMAKE_CXX_COMPILER_ID}")
          set(CMAKE_CXX_COMPILER_ID "Clang")
      endif()
      include("${CMAKE_SOURCE_DIR}/../cmake-includes/silence-warnings/CMakeLists.txt")
      if (DEFINED _ORIG_COMPILER_ID)
          set(CMAKE_CXX_COMPILER_ID "${_ORIG_COMPILER_ID}")
          unset(_ORIG_COMPILER_ID)
      endif()

      if (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-shorten-64-to-32")
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-nullability-extension")
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-nullability-completeness")
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-variadic-macro-arguments-omitted")
          set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-gnu-zero-variadic-macro-arguments")
      endif()

      add_executable(anura "${anura_SRC}")

      if (CMAKE_BUILD_TYPE MATCHES Release)
          target_compile_options(anura PRIVATE ${LTO_COMPILE_FLAGS})
          target_link_options(anura PRIVATE ${LTO_LINK_FLAGS})
      endif()

      target_link_libraries(
          anura
          PRIVATE
          Threads::Threads
          Boost::filesystem
          Boost::locale
          Boost::regex
          Boost::system
          ZLIB::ZLIB
          OpenGL::GL
          GLEW::GLEW
          Freetype::Freetype
          "${SDL2_LIBRARY}"
          "${SDL2_IMAGE_LIBRARIES}"
          "${SDL2_MIXER_LIBRARIES}"
          "${SDL2_TTF_LIBRARIES}"
          Vorbis::vorbisfile
          "${Cairo_LIBRARIES}"
      )
    CMAKE

    # Configure and build
    builddir = buildpath/"buildsystem/macos-dynamic/build"
    system "cmake", "-S", "buildsystem/macos-dynamic", "-B", builddir,
           "-DCMAKE_BUILD_TYPE=Release",
           "-DHOMEBREW_ALLOW_FETCHCONTENT=ON",
           "-DFETCHCONTENT_QUIET=OFF",
           *std_cmake_args
    system "cmake", "--build", builddir, "--parallel", ENV.make_jobs.to_s

    # Install the game into libexec (binary needs to resolve data paths
    # relative to its own location via NSBundle)
    libexec.install builddir/"anura"
    libexec.install "data"
    libexec.install "modules"
    libexec.install "images" if (buildpath/"images").exist?
    libexec.install "music" if (buildpath/"music").exist?

    # Create a launch script in bin
    (bin/"frogatto").write <<~SH
      #!/bin/bash
      exec "#{libexec}/anura" --module=frogatto4 "$@"
    SH
  end

  def caveats
    <<~EOS
      Frogatto & Friends has been installed.

      Launch from the terminal:
        frogatto

      Or from Finder, run:
        open "$(brew --prefix)/opt/frogatto/bin/frogatto"

      Game data is saved in:
        ~/Library/Application Support/frogatto4/

      Note: The Frogatto game assets (levels, character art, tiles, sounds,
      music) are licensed CC-BY-NC-SA 4.0. Please support the developers
      by purchasing the game on Steam if you enjoy it:
        https://store.steampowered.com/app/232150/Frogatto__Friends/
    EOS
  end

  test do
    assert_match "Anura engine version", shell_output("#{libexec}/anura --help 2>&1")
  end
end
