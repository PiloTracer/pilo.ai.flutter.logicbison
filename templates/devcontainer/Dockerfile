# Flutter Agent OS dev container — Linux toolchain for analyze, test, Android
# builds and agent runs. iOS/macOS builds cannot run in a Linux container; they
# need a Mac with Xcode.
#
# Base image: cirruslabs/docker-images-flutter (Flutter SDK + Android SDK).
# `:stable` is a placeholder that floats with the stable channel. Replace it
# with the exact tag matching the SDK pin in DOCS_FLUTTER_STACK.md so every
# developer, agent and CI run uses the same toolchain — check the image's
# published tags, never a version recalled from memory.
FROM ghcr.io/cirruslabs/flutter:stable

# Agent runs and verifier scripts need git and a POSIX shell; both ship in the
# base image. Add project-specific tools below, one per line, with a reason.
