#include "common.h"

/* The UMH root backend does not use the credential-patching report fields. */
uint8_t selinux_before = 0xff;
uint8_t selinux_after = 0xff;
int setgid_ret = -1;
int setuid_ret = -1;
int setenforce_ret = -1;
int setenforce_errno;
uint32_t cred_sid_before = 0xffffffff;
uint32_t cred_sid_after = 0xffffffff;
uint32_t real_cred_sid_before = 0xffffffff;
uint32_t real_cred_sid_after = 0xffffffff;
uintptr_t slide_p0_offset;
