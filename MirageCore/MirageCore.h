#ifndef MIRAGE_CORE_H
#define MIRAGE_CORE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int MirageCoreInitialize(const char *guestRootPath);
int MirageCoreExecute(const char *commandLine, char *output, size_t outputCapacity);
const char *MirageCoreVersion(void);

#ifdef __cplusplus
}
#endif

#endif
