// create builtin function name and label table for mint
// Copyright (C) 2024 TcbnErik

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FUNC_MAX 256

#define FUNC_NAME_BITS 12
#define FUNC_ADDR_BITS (32 - FUNC_NAME_BITS)
#define FUNC_ADDR_BASE "mint_start"

typedef struct {
  const char* name;
  const char* label;
  const char* reverse;
  uint8_t no;
  uint8_t unifyLength;
  uint8_t unifyNo;
} Func;

static int funcsLen;
static Func funcs[FUNC_MAX];

static void Error(const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);

  exit(EXIT_FAILURE);
}

static char* Strdup(const char* s) {
  char* t = strdup(s);
  if (!t) Error("メモリが不足しています。\n");
  return t;
}

static char* ReverseString(char* s) {
  size_t len = strlen(s);
  size_t n = len / 2;
  char* left = s;
  char* right = s + len;
  size_t i;

  for (i = 0; i < n; i += 1) {
    char c = *left;
    *left++ = *--right;
    *right = c;
  }

  return s;
}

static char* Fgets(char* buf, size_t size, FILE* fp) {
  char* result = fgets(buf, size, fp);
  if (result) {
    char* p = strchr(buf, '\n');
    if (p) *p = '\0';
  }
  return result;
}

static const char FullWidthAnd[] = {0x81, 0x95};  // Shift_JIS ＆

/// @brief ".global ＆func_name\n" 形式の行からラベルを抽出する
static const char* extractLabel(char* s) {
  char* end;
  const char header[] = ".globl ";

  if (strncmp(s, header, strlen(header)) != 0) return NULL;
  while (*s && *s != ' ') s += 1;
  while (*s && *s == ' ') s += 1;
  if (memcmp(s, FullWidthAnd, sizeof(FullWidthAnd)) != 0) return NULL;

  for (end = s + sizeof(FullWidthAnd); *end && *end > 0x20;) end += 1;
  *end = '\0';

  return Strdup(s);
}

/// @brief "＆func_name" 形式のラベルを "func-name" 形式の関数名に変換する
static const char* labelToKey(const char* s) {
  char* buf;
  char* p;

  if (!s) return NULL;
  buf = Strdup(s + sizeof(FullWidthAnd));
  for (p = buf; *p; p += 1) {
    if (*p == '_') *p = '-';
  }

  return buf;
}

static int compareFuncName(const void* a, const void* b) {
  return strcmp(((const Func*)a)->name, ((const Func*)b)->name);
}

static void ReadLines(const char* filename, FILE* fp) {
  char buf[256];
  int line = 1;
  int i;

  while (Fgets(buf, sizeof(buf), fp)) {
    const char* label = extractLabel(buf);
    const char* name = labelToKey(label);
    const char* reverse;

    if (!label || !name) continue;

    if (funcsLen == FUNC_MAX)
      Error("%s: %d: 内部関数が多すぎます: \n", filename, line, buf);

    reverse = ReverseString(Strdup(name));

    funcs[funcsLen] = (Func){name, label, reverse, 0, 0, 0};
    funcsLen += 1;
  }

  if (funcsLen == 0) Error("%s: 内部関数がありません。\n", filename);

  qsort(funcs, funcsLen, sizeof(funcs[0]), compareFuncName);

  for (i = 0; i < funcsLen; i += 1) {
    funcs[i].no = i;
  }
}

// 左右反転した文字列を逆順でソートするための比較関数
static int compareFuncReverse(const void* a, const void* b) {
  return strcmp(((const Func*)b)->reverse, ((const Func*)a)->reverse);
}

static int compareFuncNo(const void* a, const void* b) {
  return ((const Func*)a)->no - ((const Func*)b)->no;
}

static int getPreviousReverseIndex(int index) {
  index -= 1;
  while (funcs[index].unifyLength != 0) {
    index = funcs[index].unifyNo;
  }
  return index;
}

static void UnifyCommonTail(void) {
  int i;

  // 左右反転した文字列の逆順に並び替える
  qsort(funcs, funcsLen, sizeof(funcs[0]), compareFuncReverse);

  // funcs[0] には直前の関数名がないので [1] からはじめる
  for (i = 1; i < funcsLen; i += 1) {
    int prevIndex = getPreviousReverseIndex(i);
    size_t len = strlen(funcs[i].reverse);

    if (memcmp(funcs[prevIndex].reverse, funcs[i].reverse, len) == 0) {
      funcs[i].unifyLength = len;
      funcs[i].unifyNo = funcs[prevIndex].no;
    }
  }

  // 元の順に戻す
  qsort(funcs, funcsLen, sizeof(funcs[0]), compareFuncNo);
}

static void outputFuncLabel(void) {
  const int bits = FUNC_ADDR_BITS;
  int i;

  puts("\nX: .reg FUNC_ADDR_BASE\n.quad\nFuncAddrTable:");
  for (i = 0; i < funcsLen; i += 1) {
    printf("  .dc.l (s%03d-S)<<%d+%s-X\n", i, bits, funcs[i].label);
  }
  puts("FuncAddrTableEnd:");
}

static void outputFuncName(void) {
  int i;

  puts("\nFuncNameList:\nS:");
  for (i = 0; i < funcsLen; i += 1) {
    int unifyLen = funcs[i].unifyLength;
    if (unifyLen == 0) {
      printf("s%03d: .dc.b '%s',0\n", i, funcs[i].name);
    } else {
      const char* unifyName = funcs[funcs[i].unifyNo].name;
      int skip = strlen(unifyName) - unifyLen;
      printf("s%03d: .equ s%03d+%d  ;%s\n", i, funcs[i].unifyNo, skip,
             funcs[i].name);
    }
  }
}

static void Output(void) {
  puts("# mint builtin function table\n# generated by mkfunctbl");
  printf(
      "\n.xref %s\nFUNC_ADDR_BASE: .reg %s\n"
      "FUNC_NAME_BITS: .equ %d\nFUNC_ADDR_BITS: .equ %d\n",
      FUNC_ADDR_BASE, FUNC_ADDR_BASE, FUNC_NAME_BITS, FUNC_ADDR_BITS);
  puts("\n.data");
  outputFuncLabel();
  outputFuncName();
  puts("\n.text");
}

int main(void) {
  ReadLines("<stdin>", stdin);
  UnifyCommonTail();
  Output();

  return EXIT_SUCCESS;
}
