#ifndef __KSU_H_SUCOMPAT
#define __KSU_H_SUCOMPAT

int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode, int *__unused_flags);
int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
int ksu_handle_execve(const char __user **filename_user, void *argv, void *envp);
int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv, void *envp, int *flags);

void ksu_sucompat_init(void);
void ksu_sucompat_exit(void);

#endif
