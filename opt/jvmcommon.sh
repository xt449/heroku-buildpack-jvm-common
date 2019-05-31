#!/usr/bin/env bash

calculate_java_memory_opts() {
  local opts=${1:-""}

  limit=$(ulimit -u)
  case $limit in
  512)   # 2X, private-s: memory.limit_in_bytes=1073741824
    echo "$opts -Xmx256m -XX:CICompilerCount=2"
    ;;
  16384) # perf-m, private-m: memory.limit_in_bytes=2684354560
    echo "$opts -Xmx256m"
    ;;
  32768) # perf-l, private-l: memory.limit_in_bytes=15032385536
    echo "$opts -Xmx256m"
    ;;
  *) # Free, Hobby, 1X: memory.limit_in_bytes=268435456?
    echo "$opts -Xmx256m -Xss384k -XX:CICompilerCount=2"
    ;;
  esac
}

export JAVA_HOME="$HOME/.jdk"
export PATH="$HOME/.heroku/bin:$JAVA_HOME/bin:$PATH"

if [[ -d "$JAVA_HOME/jre/lib/amd64/server" ]]; then
  export LD_LIBRARY_PATH="$JAVA_HOME/jre/lib/amd64/server:$LD_LIBRARY_PATH"
elif [[ -d "$JAVA_HOME/lib/server" ]]; then
  export LD_LIBRARY_PATH="$JAVA_HOME/lib/server:$LD_LIBRARY_PATH"
fi

if cat "$HOME/.jdk/release" | grep -q '^JAVA_VERSION="1[0-1]'; then
  default_java_mem_opts="$(calculate_java_memory_opts "-XX:+UseContainerSupport")"
else
  default_java_mem_opts="$(calculate_java_memory_opts | sed 's/^ //')"
fi

if echo "${JAVA_OPTS:-}" | grep -q "\-Xmx"; then
  export JAVA_TOOL_OPTIONS=${JAVA_TOOL_OPTIONS:-"-Dfile.encoding=UTF-8"}
else
  default_java_opts="${default_java_mem_opts} -Dfile.encoding=UTF-8"
  export JAVA_OPTS="${default_java_opts} ${JAVA_OPTS:-}"
  if echo "${DYNO}" | grep -vq '^run\..*$'; then
    export JAVA_TOOL_OPTIONS="${default_java_opts} ${JAVA_TOOL_OPTIONS:-}"
  fi
  if echo "${DYNO}" | grep -q '^web\..*$'; then
    echo "Setting JAVA_TOOL_OPTIONS defaults based on dyno size. Custom settings will override them."
  fi
fi
