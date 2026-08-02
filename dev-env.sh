#!/usr/bin/env sh

FISCORE_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

export PATH="$FISCORE_ROOT/.devtools/node22/bin:$FISCORE_ROOT/.devtools/bin:$FISCORE_ROOT/.venv/bin:$PATH"
export JAVA_HOME="$FISCORE_ROOT/.devtools/jdk17"
export XDG_CONFIG_HOME="$FISCORE_ROOT/.devtools/config"
export XDG_CACHE_HOME="$FISCORE_ROOT/.devtools/cache"

if [ -d "$FISCORE_ROOT/.devtools/flutter/bin" ]; then
  export PATH="$FISCORE_ROOT/.devtools/flutter/bin:$PATH"
fi

if [ -d "$HOME/Library/Android/sdk" ]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
  export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
elif [ -d "$FISCORE_ROOT/.devtools/android-sdk" ]; then
  export ANDROID_HOME="$FISCORE_ROOT/.devtools/android-sdk"
  export ANDROID_SDK_ROOT="$FISCORE_ROOT/.devtools/android-sdk"
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi
