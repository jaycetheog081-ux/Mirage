#include "MirageCore.h"

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static char g_root[PATH_MAX] = {0};

static void write_output(char *out, size_t cap, const char *text) {
    if (!out || cap == 0) return;
    snprintf(out, cap, "%s", text ? text : "");
}

static void append_output(char *out, size_t cap, const char *text) {
    if (!out || cap == 0 || !text) return;
    size_t used = strlen(out);
    if (used < cap - 1) snprintf(out + used, cap - used, "%s", text);
}

static int safe_guest_path(const char *input, char *resolved, size_t cap) {
    if (!g_root[0] || !input || !resolved || cap == 0) return -1;
    while (*input == ' ') input++;
    if (*input == '\0' || strcmp(input, "/") == 0 || strcmp(input, ".") == 0) {
        return snprintf(resolved, cap, "%s", g_root) >= (int)cap ? -1 : 0;
    }
    if (strstr(input, "..")) return -1;
    while (*input == '/') input++;
    if (snprintf(resolved, cap, "%s/%s", g_root, input) >= (int)cap) return -1;
    return 0;
}

int MirageCoreInitialize(const char *guestRootPath) {
    if (!guestRootPath || !guestRootPath[0]) return -1;
    if (snprintf(g_root, sizeof(g_root), "%s", guestRootPath) >= (int)sizeof(g_root)) return -1;

    struct stat st;
    if (stat(g_root, &st) != 0) {
        if (mkdir(g_root, 0700) != 0 && errno != EEXIST) return -1;
    }

    char etcPath[PATH_MAX];
    if (snprintf(etcPath, sizeof(etcPath), "%s/etc", g_root) < (int)sizeof(etcPath)) {
        mkdir(etcPath, 0700);
    }
    char welcomePath[PATH_MAX];
    if (snprintf(welcomePath, sizeof(welcomePath), "%s/etc/mirage-release", g_root) < (int)sizeof(welcomePath)) {
        if (access(welcomePath, F_OK) != 0) {
            FILE *f = fopen(welcomePath, "w");
            if (f) {
                fputs("Mirage userspace prototype\nTarget profile: iOS 18.5\n", f);
                fclose(f);
            }
        }
    }
    return 0;
}

const char *MirageCoreVersion(void) {
    return "0.1.0";
}

static void trim_newline(char *s) {
    if (!s) return;
    size_t n = strlen(s);
    while (n > 0 && (s[n-1] == '\n' || s[n-1] == '\r')) s[--n] = '\0';
}

int MirageCoreExecute(const char *commandLine, char *output, size_t outputCapacity) {
    if (!output || outputCapacity == 0) return -1;
    output[0] = '\0';
    if (!commandLine) {
        write_output(output, outputCapacity, "error: empty command\n");
        return -1;
    }

    char line[4096];
    snprintf(line, sizeof(line), "%s", commandLine);
    trim_newline(line);
    char *cursor = line;
    while (isspace((unsigned char)*cursor)) cursor++;
    if (*cursor == '\0') return 0;

    char *space = strchr(cursor, ' ');
    char *arg = NULL;
    if (space) {
        *space = '\0';
        arg = space + 1;
        while (*arg == ' ') arg++;
    }

    if (strcmp(cursor, "help") == 0) {
        write_output(output, outputCapacity,
            "Mirage built-in commands:\n"
            "  help                 Show this help\n"
            "  uname                Show guest profile\n"
            "  pwd                  Show guest root path\n"
            "  ls [path]            List a guest directory\n"
            "  cat <path>           Print a guest text file\n"
            "  mkdir <path>         Create a guest directory\n"
            "  write <path> <text>  Write text to a guest file\n"
            "  echo <text>          Print text\n"
            "\nThis prototype does not yet execute arbitrary binaries.\n");
        return 0;
    }
    if (strcmp(cursor, "uname") == 0) {
        write_output(output, outputCapacity, "Mirage guest profile: iOS 18.5 userspace target\nArchitecture: host-native command layer (prototype)\n");
        return 0;
    }
    if (strcmp(cursor, "pwd") == 0) {
        char text[PATH_MAX + 32];
        snprintf(text, sizeof(text), "/%s", g_root[0] ? "(guest root)" : "");
        write_output(output, outputCapacity, text);
        append_output(output, outputCapacity, "\n");
        return 0;
    }
    if (strcmp(cursor, "echo") == 0) {
        char text[4096];
        snprintf(text, sizeof(text), "%s\n", arg ? arg : "");
        write_output(output, outputCapacity, text);
        return 0;
    }
    if (strcmp(cursor, "ls") == 0) {
        char path[PATH_MAX];
        if (safe_guest_path(arg ? arg : "/", path, sizeof(path)) != 0) {
            write_output(output, outputCapacity, "error: invalid guest path\n");
            return -1;
        }
        DIR *dir = opendir(path);
        if (!dir) {
            snprintf(line, sizeof(line), "error: cannot open directory (%s)\n", strerror(errno));
            write_output(output, outputCapacity, line);
            return -1;
        }
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;
            append_output(output, outputCapacity, entry->d_name);
            append_output(output, outputCapacity, "\n");
        }
        closedir(dir);
        return 0;
    }
    if (strcmp(cursor, "cat") == 0) {
        char path[PATH_MAX];
        if (!arg || safe_guest_path(arg, path, sizeof(path)) != 0) {
            write_output(output, outputCapacity, "usage: cat <path>\n");
            return -1;
        }
        FILE *f = fopen(path, "r");
        if (!f) {
            snprintf(line, sizeof(line), "error: cannot open file (%s)\n", strerror(errno));
            write_output(output, outputCapacity, line);
            return -1;
        }
        size_t n = fread(output, 1, outputCapacity - 1, f);
        output[n] = '\0';
        fclose(f);
        append_output(output, outputCapacity, "\n");
        return 0;
    }
    if (strcmp(cursor, "mkdir") == 0) {
        char path[PATH_MAX];
        if (!arg || safe_guest_path(arg, path, sizeof(path)) != 0) {
            write_output(output, outputCapacity, "usage: mkdir <path>\n");
            return -1;
        }
        if (mkdir(path, 0700) != 0) {
            snprintf(line, sizeof(line), "error: mkdir failed (%s)\n", strerror(errno));
            write_output(output, outputCapacity, line);
            return -1;
        }
        write_output(output, outputCapacity, "directory created\n");
        return 0;
    }
    if (strcmp(cursor, "write") == 0) {
        if (!arg) {
            write_output(output, outputCapacity, "usage: write <path> <text>\n");
            return -1;
        }
        char *text = strchr(arg, ' ');
        if (!text) {
            write_output(output, outputCapacity, "usage: write <path> <text>\n");
            return -1;
        }
        *text++ = '\0';
        char path[PATH_MAX];
        if (safe_guest_path(arg, path, sizeof(path)) != 0) {
            write_output(output, outputCapacity, "error: invalid guest path\n");
            return -1;
        }
        FILE *f = fopen(path, "w");
        if (!f) {
            snprintf(line, sizeof(line), "error: cannot write file (%s)\n", strerror(errno));
            write_output(output, outputCapacity, line);
            return -1;
        }
        fputs(text, f);
        fputc('\n', f);
        fclose(f);
        write_output(output, outputCapacity, "file written\n");
        return 0;
    }

    snprintf(line, sizeof(line), "mirage: command not found: %s\nType 'help' for available commands.\n", cursor);
    write_output(output, outputCapacity, line);
    return 127;
}
