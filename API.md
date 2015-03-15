# Introduction #

The API of Jsonx64 ist very simple. There are only
very few public functions.

The following types of input streams are supported:
  * memory
  * FILE descriptors
  * FDs

# FILE **-based reading #**

To read JSON-Data from a file, you need to create a file
buffer object first. Then, you can parse the document.

```
File * fd;
JSONBuffer * buffer;
JSONNode * root;

fd = fopen ("Test.json", "rb");
if (fd) {
  buffer = json_buffer_init_file (fd);
  if (buffer == NULL) {
    // Error
    exit (EXIT_FAILURE);
  }

  root = json_parse (buffer);
  if (root == NULL {
    // Error
    json_buffer_free (buffer);
    exit (EXIT_FAILURE);
  }
}
```

# Memory-based reading #

To read JSON-Data from memory, you need to create a memory
buffer object first. Then, you can parse the document.

```
JSONBuffer * buffer;
JSONNode * root;

buffer = json_buffer_init_mem (ptr, len);
if (buffer == NULL) {
  // Error
  exit (EXIT_FAILURE);
}

root = json_parse (buffer);
if (root == NULL {
  // Error
  json_buffer_free (buffer);
  exit (EXIT_FAILURE);
}

```

# FD-based reading #

To read JSON-Data from a file descriptor (such as a socket), you need to create a file
buffer object first. Then, you can parse the document.

```
int fd;
JSONBuffer * buffer;
JSONNode * root;

fd = open ("Test.json", O_RDONLY);
if (fd != -1) {
  buffer = json_buffer_init_fd (fd);
  if (buffer == NULL) {
    // Error
    exit (EXIT_FAILURE);
  }

  root = json_parse (buffer);
  if (root == NULL {
    // Error
    json_buffer_free (buffer);
    exit (EXIT_FAILURE);
  }
}
```

# Freeing #
After you have processed the root node, you must free it.

```
json_parser_free (node);
json_buffer_free (buffer);
```