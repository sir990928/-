#include "common.h"

__attribute__((constructor)) static void load(void) {
  static int started;
  if (started) {
    return;
  }
  started = 1;

  unsetenv("LD_PRELOAD");
  pr_success("minimal preload starting pid=%d\n", getpid());
  run_exploit(1, NULL);
}
