#include <windows.h>

int setenv(const char *name, const char *value, int overwrite) {
    int exists = GetEnvironmentVariableA(name, NULL, 0);
    if ((exists && overwrite) || (!exists)) {
        if (!SetEnvironmentVariableA(name, value)) {
            return -1;
        }
        return 0;
    }
    return -1;
}

void unsetenv(const char *name) {
    SetEnvironmentVariableA(name, NULL);
}
