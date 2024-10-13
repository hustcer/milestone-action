#!/usr/bin/env nu
# Author: hustcer
# Created: 2024/06/09 20:33:15
# TODO:
#   [x] Support Windows, macOS, Linux
#   [x] Add Github cache support
# Description: Scripts for setting up Bend environment

use common.nu [hr-line windows? is-installed]

export-env {
  $env.config.color_config.leading_trailing_space_bg = { attr: n }
}

export def 'setup bend' [cacheHit: bool = false] {
  print $'Cache hit: ($cacheHit), type: ($cacheHit | describe)'
  print "Setting up Bend environment..."; hr-line
  print $'Gcc version: (ansi g)(gcc --version)(ansi reset)'
  print $'Cargo version: (ansi g)(cargo --version)(ansi reset)'
  if $cacheHit != true {
    print 'Installing Hvm2...'; hr-line
    cargo install hvm
  }
  print $'Hvm version: (ansi g)(hvm --version)(ansi reset)'
  if $cacheHit != true {
    print 'Installing Bend...'; hr-line
    cargo install bend-lang
  }
  print $'Bend version: (ansi g)(bend --version)(ansi reset)'
}

# Generate cache key suffix by bend and hvm version
export def gen-cache-key [] {
  let bend = cargo-search bend-lang | first
  let hvm = cargo-search hvm | first
  let key = $'($hvm.name):($hvm.version)-($bend.name):($bend.version)'
  print $'Cache key suffix: ($key)'
  echo $'suffix=($key)' o>> $env.GITHUB_OUTPUT
}

def cargo-search [ query: string, --limit=5 ] {
  ^cargo search $query --limit $limit
    | lines
    | each { |line|
        if ($line | str contains "#") {
          $line | parse --regex '(?P<name>.+) = "(?P<version>.+)" +# (?P<description>.+)'
        } else {
          $line | parse --regex '(?P<name>.+) = "(?P<version>.+)"'
        }
      }
    | flatten
}

alias main = setup bend
