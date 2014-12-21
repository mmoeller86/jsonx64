#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include "json.h"

char *
read_file (char * fname, int * len)
{
	FILE * fd;
	struct stat st;
	char * m;

	fd = fopen (fname, "rb");
	if (fd == NULL)
		return NULL;

	fstat (fileno (fd), &st);
	m = malloc (st.st_size);
	fread (m, 1, st.st_size, fd);
	*len = st.st_size;
	return m;
}

int main (int c, char ** args)
{
	FILE * file;
	JSONBuffer * buffer;
	JSONNode * node;
	char * mem;
	int mlen;
	int i;
	int fd;

	setbuf (stdout, NULL);
	mem = read_file (args [1], &mlen);
	if (mem == NULL) {
		fprintf (stderr, "%s: %s: Failed to read file\n", args [0], args [1]);
		return 1;
	}

	buffer = json_buffer_init_fd (open (args [1], O_RDONLY));
	node = json_parse (buffer);
	if (node == NULL) {
		fprintf (stderr, "%s: %s: Failed to parse file !\n", args [0], args [1]);
		json_buffer_free (buffer);
		return 1;
	}

	printf ("Type = %d\n", node->typ);
	printf ("Count = %lld\n", node->n);
	//puts (node->d_str);
	for (i = 0; i < node->n; i++) {
		JSONNode * n;

		n = node->a [i];
		printf ("\t[%d] TYPE=%d NAME=%s\n", i, n->typ, n->nam);
	}

	json_parser_free (node);
	json_buffer_free (buffer);
	return 0;
}
