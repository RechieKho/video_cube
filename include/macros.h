
#ifndef LITERAL_CONCAT
#define LITERAL_CONCAT(x, y) x ## y
#endif//LITERAL_CONCAT

#ifndef CONCAT
#define CONCAT(x, y) LITERAL_CONCAT(x, y)
#endif//CONCAT

#ifndef AFFIX_VERSION
#define AFFIX_VERSION(identifier) CONCAT(identifier, VERSION)
#endif//AFFIX_VERSION