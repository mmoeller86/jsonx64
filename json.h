#ifndef JSON_H
#define JSON_H

#include <stdlib.h>
#include <stdio.h>

#pragma pack(push,1)
typedef struct {

} JSONParser;

typedef struct {
#define TYPE_MEM	0
#define TYPE_FILE	1
	int	typ;
	char *	mem;
	long long msize;
	long long last_char;

	FILE *	file;
	int fd;
} JSONBuffer;

typedef struct _JSONNode {
#define NODE_TYPE_NUMBER	0
#define NODE_TYPE_STRING	1
#define NODE_TYPE_BOOLEAN	2
#define NODE_TYPE_OBJECT	3
#define NODE_TYPE_ARRAY		4
#define NODE_TYPE_NULL		5
	int	typ;
	double	d_val;
	char *	d_str;
	int	d_bool;

	char *	nam;
	long long int	n;
	struct _JSONNode ** a;
} JSONNode;
#pragma pack(pop)

JSONBuffer * json_buffer_init_mem (char * ptr, long long size);
JSONBuffer * json_buffer_init_file (FILE * file);
JSONBuffer * json_buffer_init_fd (int fd);
void	     json_buffer_free (JSONBuffer * buffer);

JSONNode *	json_parse (JSONBuffer * buffer);
void		json_parser_free (JSONNode * root);

#endif
