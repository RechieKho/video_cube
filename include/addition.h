#ifndef CRAB_ADDITION_H
#define CRAB_ADDITION_H

#include "macros.h"

int AFFIX_VERSION(add)(int a, int b);
#define add(a, b) (AFFIX_VERSION(add)(a, b))

#endif // CRAB_ADDITION_H