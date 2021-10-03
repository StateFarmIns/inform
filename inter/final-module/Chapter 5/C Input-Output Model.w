[CInputOutputModel::] C Input-Output Model.

How C programs print text out, really.

@h Setting up the model.

=
void CInputOutputModel::initialise(code_generator *cgt) {
}

void CInputOutputModel::initialise_data(code_generation *gen) {
}

void CInputOutputModel::begin(code_generation *gen) {
}

void CInputOutputModel::end(code_generation *gen) {
}

@

=
int CInputOutputModel::invoke_primitive(code_generation *gen, inter_ti bip, inter_tree_node *P) {
	text_stream *OUT = CodeGen::current(gen);
	switch (bip) {
		case SPACES_BIP:		 WRITE("for (int j = "); VNODE_1C; WRITE("; j > 0; j--) i7_print_char(proc, 32);"); break;
		case FONT_BIP:           WRITE("i7_font(proc, "); VNODE_1C; WRITE(")"); break;
		case STYLE_BIP:    		 WRITE("i7_style(proc, "); VNODE_1C; WRITE(")"); break;
		case PRINT_BIP:          WRITE("i7_print_C_string(proc, "); CodeGen::lt_mode(gen, PRINTING_LTM); VNODE_1C; CodeGen::lt_mode(gen, REGULAR_LTM); WRITE(")"); break;
		case PRINTCHAR_BIP:      WRITE("i7_print_char(proc, "); VNODE_1C; WRITE(")"); break;
		case PRINTNL_BIP:        WRITE("i7_print_char(proc, '\\n')"); break;
		case PRINTOBJ_BIP:       WRITE("i7_print_object(proc, "); VNODE_1C; WRITE(")"); break;
		case PRINTNUMBER_BIP:    WRITE("i7_print_decimal(proc, "); VNODE_1C; WRITE(")"); break;
		case BOX_BIP:            WRITE("i7_print_box(proc, "); CodeGen::lt_mode(gen, BOX_LTM); VNODE_1C; CodeGen::lt_mode(gen, REGULAR_LTM); WRITE(")"); break;
		case READ_BIP:           WRITE("i7_read(proc, "); VNODE_1C; WRITE(", "); VNODE_2C; WRITE(")"); break;
		default: 				 return NOT_APPLICABLE;
	}
	return FALSE;
}

@

= (text to inform7_clib.h)
#define I7_BODY_TEXT_ID    201
#define I7_STATUS_TEXT_ID  202
#define I7_BOX_TEXT_ID     203

void i7_style(i7process_t *proc, i7word_t what);
void i7_font(i7process_t *proc, int what);

#define fileusage_Data (0x00)
#define fileusage_SavedGame (0x01)
#define fileusage_Transcript (0x02)
#define fileusage_InputRecord (0x03)
#define fileusage_TypeMask (0x0f)

#define fileusage_TextMode   (0x100)
#define fileusage_BinaryMode (0x000)

#define filemode_Write (0x01)
#define filemode_Read (0x02)
#define filemode_ReadWrite (0x03)
#define filemode_WriteAppend (0x05)

typedef struct i7_fileref {
	i7word_t usage;
	i7word_t name;
	i7word_t rock;
	char leafname[128];
	FILE *handle;
} i7_fileref;

i7word_t i7_do_glk_fileref_create_by_name(i7process_t *proc, i7word_t usage, i7word_t name, i7word_t rock);
int i7_fseek(i7process_t *proc, int id, int pos, int origin);
int i7_ftell(i7process_t *proc, int id);
int i7_fopen(i7process_t *proc, int id, int mode);
void i7_fclose(i7process_t *proc, int id);
i7word_t i7_do_glk_fileref_does_file_exist(i7process_t *proc, i7word_t id);
void i7_fputc(i7process_t *proc, int c, int id);
int i7_fgetc(i7process_t *proc, int id);
typedef struct i7_stream {
	FILE *to_file;
	i7word_t to_file_id;
	wchar_t *to_memory;
	size_t memory_used;
	size_t memory_capacity;
	i7word_t previous_id;
	i7word_t write_here_on_closure;
	size_t write_limit;
	int active;
	int encode_UTF8;
	int char_size;
	int chars_read;
	int read_position;
	int end_position;
	int owned_by_window_id;
	int fixed_pitch;
	char style[128];
	char composite_style[300];
} i7_stream;
i7word_t i7_do_glk_stream_get_current(i7process_t *proc);
i7_stream i7_new_stream(i7process_t *proc, FILE *F, int win_id);
=

= (text to inform7_clib.c)
#define I7_MAX_STREAMS 128

i7_stream i7_memory_streams[I7_MAX_STREAMS];

i7word_t fn_i7_mgl_TEXT_TY_CharacterLength(i7process_t *proc, i7word_t i7_mgl_local_txt, i7word_t i7_mgl_local_ch, i7word_t i7_mgl_local_i, i7word_t i7_mgl_local_dsize, i7word_t i7_mgl_local_p, i7word_t i7_mgl_local_cp, i7word_t i7_mgl_local_r);
i7word_t fn_i7_mgl_BlkValueRead(i7process_t *proc, i7word_t i7_mgl_local_from, i7word_t i7_mgl_local_pos, i7word_t i7_mgl_local_do_not_indirect, i7word_t i7_mgl_local_long_block, i7word_t i7_mgl_local_chunk_size_in_bytes, i7word_t i7_mgl_local_header_size_in_bytes, i7word_t i7_mgl_local_flags, i7word_t i7_mgl_local_entry_size_in_bytes, i7word_t i7_mgl_local_seek_byte_position);
void i7_style(i7process_t *proc, i7word_t what_v) {
	i7_stream *S = &(i7_memory_streams[proc->state.i7_str_id]);
	S->style[0] = 0;
	switch (what_v) {
		case 0: break;
		case 1: sprintf(S->style, "bold"); break;
		case 2: sprintf(S->style, "italic"); break;
		case 3: sprintf(S->style, "reverse"); break;
		default: {
			int L = fn_i7_mgl_TEXT_TY_CharacterLength(proc, what_v, 0, 0, 0, 0, 0, 0);
			if (L > 127) L = 127;
			for (int i=0; i<L; i++) S->style[i] = fn_i7_mgl_BlkValueRead(proc, what_v, i, 0, 0, 0, 0, 0, 0, 0);
			S->style[L] = 0;
		}
	}
	sprintf(S->composite_style, "%s", S->style);
	if (S->fixed_pitch) {
		if (strlen(S->style) > 0) sprintf(S->composite_style + strlen(S->composite_style), ",");
		sprintf(S->composite_style + strlen(S->composite_style), "fixedpitch");
	}
}

void i7_font(i7process_t *proc, int what) {
	i7_stream *S = &(i7_memory_streams[proc->state.i7_str_id]);
	S->fixed_pitch = what;
	sprintf(S->composite_style, "%s", S->style);
	if (S->fixed_pitch) {
		if (strlen(S->style) > 0) sprintf(S->composite_style + strlen(S->composite_style), ",");
		sprintf(S->composite_style + strlen(S->composite_style), "fixedpitch");
	}
}

i7_fileref filerefs[128 + 32];
int i7_no_filerefs = 0;

i7word_t i7_do_glk_fileref_create_by_name(i7process_t *proc, i7word_t usage, i7word_t name, i7word_t rock) {
	if (i7_no_filerefs >= 128) {
		fprintf(stderr, "Out of streams\n"); i7_fatal_exit(proc);
	}
	int id = i7_no_filerefs++;
	filerefs[id].usage = usage;
	filerefs[id].name = name;
	filerefs[id].rock = rock;
	filerefs[id].handle = NULL;
	for (int i=0; i<128; i++) {
		i7byte_t c = i7_read_byte(proc, name+1+i);
		filerefs[id].leafname[i] = c;
		if (c == 0) break;
	}
	filerefs[id].leafname[127] = 0;
	sprintf(filerefs[id].leafname + strlen(filerefs[id].leafname), ".glkdata");
	return id;
}

int i7_fseek(i7process_t *proc, int id, int pos, int origin) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	return fseek(filerefs[id].handle, pos, origin);
}

int i7_ftell(i7process_t *proc, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	int t = ftell(filerefs[id].handle);
	return t;
}

int i7_fopen(i7process_t *proc, int id, int mode) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle) { fprintf(stderr, "File already open\n"); i7_fatal_exit(proc); }
	char *c_mode = "r";
	switch (mode) {
		case filemode_Write: c_mode = "w"; break;
		case filemode_Read: c_mode = "r"; break;
		case filemode_ReadWrite: c_mode = "r+"; break;
		case filemode_WriteAppend: c_mode = "r+"; break;
	}
	FILE *h = fopen(filerefs[id].leafname, c_mode);
	if (h == NULL) return 0;
	filerefs[id].handle = h;
	if (mode == filemode_WriteAppend) i7_fseek(proc, id, 0, SEEK_END);
	return 1;
}

void i7_fclose(i7process_t *proc, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	fclose(filerefs[id].handle);
	filerefs[id].handle = NULL;
}


i7word_t i7_do_glk_fileref_does_file_exist(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle) return 1;
	if (i7_fopen(proc, id, filemode_Read)) {
		i7_fclose(proc, id); return 1;
	}
	return 0;
}

void i7_fputc(i7process_t *proc, int c, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	fputc(c, filerefs[id].handle);
}

int i7_fgetc(i7process_t *proc, int id) {
	if ((id < 0) || (id >= 128)) { fprintf(stderr, "Too many files\n"); i7_fatal_exit(proc); }
	if (filerefs[id].handle == NULL) { fprintf(stderr, "File not open\n"); i7_fatal_exit(proc); }
	int c = fgetc(filerefs[id].handle);
	return c;
}

i7word_t i7_stdout_id = 0, i7_stderr_id = 1;

i7word_t i7_do_glk_stream_get_current(i7process_t *proc) {
	return proc->state.i7_str_id;
}

void i7_do_glk_stream_set_current(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	proc->state.i7_str_id = id;
}

i7_stream i7_new_stream(i7process_t *proc, FILE *F, int win_id) {
	i7_stream S;
	S.to_file = F;
	S.to_file_id = -1;
	S.to_memory = NULL;
	S.memory_used = 0;
	S.memory_capacity = 0;
	S.write_here_on_closure = 0;
	S.write_limit = 0;
	S.previous_id = 0;
	S.active = 0;
	S.encode_UTF8 = 0;
	S.char_size = 4;
	S.chars_read = 0;
	S.read_position = 0;
	S.end_position = 0;
	S.owned_by_window_id = win_id;
	S.style[0] = 0;
	S.fixed_pitch = 0;
	S.composite_style[0] = 0;
	return S;
}
=

@

= (text to inform7_clib.h)
void i7_initialise_streams(i7process_t *proc);
i7word_t i7_open_stream(i7process_t *proc, FILE *F, int win_id);
i7word_t i7_do_glk_stream_open_memory(i7process_t *proc, i7word_t buffer, i7word_t len, i7word_t fmode, i7word_t rock);
i7word_t i7_do_glk_stream_open_memory_uni(i7process_t *proc, i7word_t buffer, i7word_t len, i7word_t fmode, i7word_t rock);
i7word_t i7_do_glk_stream_open_file(i7process_t *proc, i7word_t fileref, i7word_t usage, i7word_t rock);
#define seekmode_Start (0)
#define seekmode_Current (1)
#define seekmode_End (2)
void i7_do_glk_stream_set_position(i7process_t *proc, i7word_t id, i7word_t pos, i7word_t seekmode);
i7word_t i7_do_glk_stream_get_position(i7process_t *proc, i7word_t id);
void i7_do_glk_stream_close(i7process_t *proc, i7word_t id, i7word_t result);
typedef struct i7_winref {
	i7word_t type;
	i7word_t stream_id;
	i7word_t rock;
} i7_winref;
i7word_t i7_do_glk_window_open(i7process_t *proc, i7word_t split, i7word_t method, i7word_t size, i7word_t wintype, i7word_t rock);
i7word_t i7_stream_of_window(i7process_t *proc, i7word_t id);
i7word_t i7_rock_of_window(i7process_t *proc, i7word_t id);
void i7_to_receiver(i7process_t *proc, i7word_t rock, wchar_t c);
void i7_do_glk_put_char_stream(i7process_t *proc, i7word_t stream_id, i7word_t x);
i7word_t i7_do_glk_get_char_stream(i7process_t *proc, i7word_t stream_id);
void i7_print_char(i7process_t *proc, i7word_t x);
void i7_print_C_string(i7process_t *proc, char *c_string);
void i7_print_decimal(i7process_t *proc, i7word_t x);

=

= (text to inform7_clib.c)
void i7_initialise_streams(i7process_t *proc) {
	for (int i=0; i<I7_MAX_STREAMS; i++) i7_memory_streams[i] = i7_new_stream(proc, NULL, 0);
	i7_memory_streams[i7_stdout_id] = i7_new_stream(proc, stdout, 0);
	i7_memory_streams[i7_stdout_id].active = 1;
	i7_memory_streams[i7_stdout_id].encode_UTF8 = 1;
	i7_memory_streams[i7_stderr_id] = i7_new_stream(proc, stderr, 0);
	i7_memory_streams[i7_stderr_id].active = 1;
	i7_memory_streams[i7_stderr_id].encode_UTF8 = 1;
	i7_do_glk_stream_set_current(proc, i7_stdout_id);
}

i7word_t i7_open_stream(i7process_t *proc, FILE *F, int win_id) {
	for (int i=0; i<I7_MAX_STREAMS; i++)
		if (i7_memory_streams[i].active == 0) {
			i7_memory_streams[i] = i7_new_stream(proc, F, win_id);
			i7_memory_streams[i].active = 1;
			i7_memory_streams[i].previous_id = proc->state.i7_str_id;
			return i;
		}
	fprintf(stderr, "Out of streams\n"); i7_fatal_exit(proc);
	return 0;
}

i7word_t i7_do_glk_stream_open_memory(i7process_t *proc, i7word_t buffer, i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(proc); }
	i7word_t id = i7_open_stream(proc, NULL, 0);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 1;
	proc->state.i7_str_id = id;
	return id;
}

i7word_t i7_do_glk_stream_open_memory_uni(i7process_t *proc, i7word_t buffer, i7word_t len, i7word_t fmode, i7word_t rock) {
	if (fmode != 1) { fprintf(stderr, "Only file mode 1 supported, not %d\n", fmode); i7_fatal_exit(proc); }
	i7word_t id = i7_open_stream(proc, NULL, 0);
	i7_memory_streams[id].write_here_on_closure = buffer;
	i7_memory_streams[id].write_limit = (size_t) len;
	i7_memory_streams[id].char_size = 4;
	proc->state.i7_str_id = id;
	return id;
}

i7word_t i7_do_glk_stream_open_file(i7process_t *proc, i7word_t fileref, i7word_t usage, i7word_t rock) {
	i7word_t id = i7_open_stream(proc, NULL, 0);
	i7_memory_streams[id].to_file_id = fileref;
	if (i7_fopen(proc, fileref, usage) == 0) return 0;
	return id;
}

void i7_do_glk_stream_set_position(i7process_t *proc, i7word_t id, i7word_t pos, i7word_t seekmode) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		int origin;
		switch (seekmode) {
			case seekmode_Start: origin = SEEK_SET; break;
			case seekmode_Current: origin = SEEK_CUR; break;
			case seekmode_End: origin = SEEK_END; break;
			default: fprintf(stderr, "Unknown seekmode\n"); i7_fatal_exit(proc);
		}
		i7_fseek(proc, S->to_file_id, pos, origin);
	} else {
		fprintf(stderr, "glk_stream_set_position supported only for file streams\n"); i7_fatal_exit(proc);
	}
}

i7word_t i7_do_glk_stream_get_position(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->to_file_id >= 0) {
		return (i7word_t) i7_ftell(proc, S->to_file_id);
	}
	return (i7word_t) S->memory_used;
}

void i7_do_glk_stream_close(i7process_t *proc, i7word_t id, i7word_t result) {
	if ((id < 0) || (id >= I7_MAX_STREAMS)) { fprintf(stderr, "Stream ID %d out of range\n", id); i7_fatal_exit(proc); }
	if (id == 0) { fprintf(stderr, "Cannot close stdout\n"); i7_fatal_exit(proc); }
	if (id == 1) { fprintf(stderr, "Cannot close stderr\n"); i7_fatal_exit(proc); }
	i7_stream *S = &(i7_memory_streams[id]);
	if (S->active == 0) { fprintf(stderr, "Stream %d already closed\n", id); i7_fatal_exit(proc); }
	if (proc->state.i7_str_id == id) proc->state.i7_str_id = S->previous_id;
	if (S->write_here_on_closure != 0) {
		if (S->char_size == 4) {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_word(proc, S->write_here_on_closure, i, S->to_memory[i], i7_lvalue_SET);
				else
					i7_write_word(proc, S->write_here_on_closure, i, 0, i7_lvalue_SET);
		} else {
			for (size_t i = 0; i < S->write_limit; i++)
				if (i < S->memory_used)
					i7_write_byte(proc, S->write_here_on_closure + i, S->to_memory[i]);
				else
					i7_write_byte(proc, S->write_here_on_closure + i, 0);
		}
	}
	if (result == -1) {
		i7_push(proc, S->chars_read);
		i7_push(proc, S->memory_used);
	} else if (result != 0) {
		i7_write_word(proc, result, 0, S->chars_read, i7_lvalue_SET);
		i7_write_word(proc, result, 1, S->memory_used, i7_lvalue_SET);
	}
	if (S->to_file_id >= 0) i7_fclose(proc, S->to_file_id);
	S->active = 0;
	S->memory_used = 0;
}

i7_winref winrefs[128];
int i7_no_winrefs = 1;

i7word_t i7_do_glk_window_open(i7process_t *proc, i7word_t split, i7word_t method, i7word_t size, i7word_t wintype, i7word_t rock) {
	if (i7_no_winrefs >= 128) {
		fprintf(stderr, "Out of windows\n"); i7_fatal_exit(proc);
	}
	int id = i7_no_winrefs++;
	winrefs[id].type = wintype;
	winrefs[id].stream_id = i7_open_stream(proc, stdout, id);
	winrefs[id].rock = rock;
	return id;
}

i7word_t i7_stream_of_window(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= i7_no_winrefs)) { fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc); }
	return winrefs[id].stream_id;
}

i7word_t i7_rock_of_window(i7process_t *proc, i7word_t id) {
	if ((id < 0) || (id >= i7_no_winrefs)) { fprintf(stderr, "Window ID %d out of range\n", id); i7_fatal_exit(proc); }
	return winrefs[id].rock;
}

void i7_to_receiver(i7process_t *proc, i7word_t rock, wchar_t c) {
	i7_stream *S = &(i7_memory_streams[proc->state.i7_str_id]);
	if (proc->receiver == NULL) fputc(c, stdout);
	(proc->receiver)(rock, c, S->composite_style);
}

void i7_do_glk_put_char_stream(i7process_t *proc, i7word_t stream_id, i7word_t x) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file) {
		int win_id = S->owned_by_window_id;
		int rock = -1;
		if (win_id >= 1) rock = i7_rock_of_window(proc, win_id);
		unsigned int c = (unsigned int) x;
		if (proc->use_UTF8) {
			if (c >= 0x800) {
				i7_to_receiver(proc, rock, 0xE0 + (c >> 12));
				i7_to_receiver(proc, rock, 0x80 + ((c >> 6) & 0x3f));
				i7_to_receiver(proc, rock, 0x80 + (c & 0x3f));
			} else if (c >= 0x80) {
				i7_to_receiver(proc, rock, 0xC0 + (c >> 6));
				i7_to_receiver(proc, rock, 0x80 + (c & 0x3f));
			} else i7_to_receiver(proc, rock, (int) c);
		} else {
			i7_to_receiver(proc, rock, (int) c);
		}
	} else if (S->to_file_id >= 0) {
		i7_fputc(proc, (int) x, S->to_file_id);
		S->end_position++;
	} else {
		if (S->memory_used >= S->memory_capacity) {
			size_t needed = 4*S->memory_capacity;
			if (needed == 0) needed = 1024;
			wchar_t *new_data = (wchar_t *) calloc(needed, sizeof(wchar_t));
			if (new_data == NULL) { fprintf(stderr, "Out of memory\n"); i7_fatal_exit(proc); }
			for (size_t i=0; i<S->memory_used; i++) new_data[i] = S->to_memory[i];
			free(S->to_memory);
			S->to_memory = new_data;
		}
		S->to_memory[S->memory_used++] = (wchar_t) x;
	}
}

i7word_t i7_do_glk_get_char_stream(i7process_t *proc, i7word_t stream_id) {
	i7_stream *S = &(i7_memory_streams[stream_id]);
	if (S->to_file_id >= 0) {
		S->chars_read++;
		return i7_fgetc(proc, S->to_file_id);
	}
	return 0;
}

void i7_print_char(i7process_t *proc, i7word_t x) {
	if (x == 13) x = 10;
	i7_do_glk_put_char_stream(proc, proc->state.i7_str_id, x);
}

void i7_print_C_string(i7process_t *proc, char *c_string) {
	if (c_string)
		for (int i=0; c_string[i]; i++)
			i7_print_char(proc, (i7word_t) c_string[i]);
}

void i7_print_decimal(i7process_t *proc, i7word_t x) {
	char room[32];
	sprintf(room, "%d", (int) x);
	i7_print_C_string(proc, room);
}
=

= (text to inform7_clib.h)
#define evtype_None (0)
#define evtype_Timer (1)
#define evtype_CharInput (2)
#define evtype_LineInput (3)
#define evtype_MouseInput (4)
#define evtype_Arrange (5)
#define evtype_Redraw (6)
#define evtype_SoundNotify (7)
#define evtype_Hyperlink (8)
#define evtype_VolumeNotify (9)

typedef struct i7_glk_event {
	i7word_t type;
	i7word_t win_id;
	i7word_t val1;
	i7word_t val2;
} i7_glk_event;
i7_glk_event *i7_next_event(i7process_t *proc);
void i7_make_event(i7process_t *proc, i7_glk_event e);
i7word_t i7_do_glk_select(i7process_t *proc, i7word_t structure);
i7word_t i7_do_glk_request_line_event(i7process_t *proc, i7word_t window_id, i7word_t buffer, i7word_t max_len, i7word_t init_len);
#define i7_glk_exit 0x0001
#define i7_glk_set_interrupt_handler 0x0002
#define i7_glk_tick 0x0003
#define i7_glk_gestalt 0x0004
#define i7_glk_gestalt_ext 0x0005
#define i7_glk_window_iterate 0x0020
#define i7_glk_window_get_rock 0x0021
#define i7_glk_window_get_root 0x0022
#define i7_glk_window_open 0x0023
#define i7_glk_window_close 0x0024
#define i7_glk_window_get_size 0x0025
#define i7_glk_window_set_arrangement 0x0026
#define i7_glk_window_get_arrangement 0x0027
#define i7_glk_window_get_type 0x0028
#define i7_glk_window_get_parent 0x0029
#define i7_glk_window_clear 0x002A
#define i7_glk_window_move_cursor 0x002B
#define i7_glk_window_get_stream 0x002C
#define i7_glk_window_set_echo_stream 0x002D
#define i7_glk_window_get_echo_stream 0x002E
#define i7_glk_set_window 0x002F
#define i7_glk_window_get_sibling 0x0030
#define i7_glk_stream_iterate 0x0040
#define i7_glk_stream_get_rock 0x0041
#define i7_glk_stream_open_file 0x0042
#define i7_glk_stream_open_memory 0x0043
#define i7_glk_stream_close 0x0044
#define i7_glk_stream_set_position 0x0045
#define i7_glk_stream_get_position 0x0046
#define i7_glk_stream_set_current 0x0047
#define i7_glk_stream_get_current 0x0048
#define i7_glk_stream_open_resource 0x0049
#define i7_glk_fileref_create_temp 0x0060
#define i7_glk_fileref_create_by_name 0x0061
#define i7_glk_fileref_create_by_prompt 0x0062
#define i7_glk_fileref_destroy 0x0063
#define i7_glk_fileref_iterate 0x0064
#define i7_glk_fileref_get_rock 0x0065
#define i7_glk_fileref_delete_file 0x0066
#define i7_glk_fileref_does_file_exist 0x0067
#define i7_glk_fileref_create_from_fileref 0x0068
#define i7_glk_put_char 0x0080
#define i7_glk_put_char_stream 0x0081
#define i7_glk_put_string 0x0082
#define i7_glk_put_string_stream 0x0083
#define i7_glk_put_buffer 0x0084
#define i7_glk_put_buffer_stream 0x0085
#define i7_glk_set_style 0x0086
#define i7_glk_set_style_stream 0x0087
#define i7_glk_get_char_stream 0x0090
#define i7_glk_get_line_stream 0x0091
#define i7_glk_get_buffer_stream 0x0092
#define i7_glk_char_to_lower 0x00A0
#define i7_glk_char_to_upper 0x00A1
#define i7_glk_stylehint_set 0x00B0
#define i7_glk_stylehint_clear 0x00B1
#define i7_glk_style_distinguish 0x00B2
#define i7_glk_style_measure 0x00B3
#define i7_glk_select 0x00C0
#define i7_glk_select_poll 0x00C1
#define i7_glk_request_line_event 0x00D0
#define i7_glk_cancel_line_event 0x00D1
#define i7_glk_request_char_event 0x00D2
#define i7_glk_cancel_char_event 0x00D3
#define i7_glk_request_mouse_event 0x00D4
#define i7_glk_cancel_mouse_event 0x00D5
#define i7_glk_request_timer_events 0x00D6
#define i7_glk_image_get_info 0x00E0
#define i7_glk_image_draw 0x00E1
#define i7_glk_image_draw_scaled 0x00E2
#define i7_glk_window_flow_break 0x00E8
#define i7_glk_window_erase_rect 0x00E9
#define i7_glk_window_fill_rect 0x00EA
#define i7_glk_window_set_background_color 0x00EB
#define i7_glk_schannel_iterate 0x00F0
#define i7_glk_schannel_get_rock 0x00F1
#define i7_glk_schannel_create 0x00F2
#define i7_glk_schannel_destroy 0x00F3
#define i7_glk_schannel_create_ext 0x00F4
#define i7_glk_schannel_play_multi 0x00F7
#define i7_glk_schannel_play 0x00F8
#define i7_glk_schannel_play_ext 0x00F9
#define i7_glk_schannel_stop 0x00FA
#define i7_glk_schannel_set_volume 0x00FB
#define i7_glk_sound_load_hint 0x00FC
#define i7_glk_schannel_set_volume_ext 0x00FD
#define i7_glk_schannel_pause 0x00FE
#define i7_glk_schannel_unpause 0x00FF
#define i7_glk_set_hyperlink 0x0100
#define i7_glk_set_hyperlink_stream 0x0101
#define i7_glk_request_hyperlink_event 0x0102
#define i7_glk_cancel_hyperlink_event 0x0103
#define i7_glk_buffer_to_lower_case_uni 0x0120
#define i7_glk_buffer_to_upper_case_uni 0x0121
#define i7_glk_buffer_to_title_case_uni 0x0122
#define i7_glk_buffer_canon_decompose_uni 0x0123
#define i7_glk_buffer_canon_normalize_uni 0x0124
#define i7_glk_put_char_uni 0x0128
#define i7_glk_put_string_uni 0x0129
#define i7_glk_put_buffer_uni 0x012A
#define i7_glk_put_char_stream_uni 0x012B
#define i7_glk_put_string_stream_uni 0x012C
#define i7_glk_put_buffer_stream_uni 0x012D
#define i7_glk_get_char_stream_uni 0x0130
#define i7_glk_get_buffer_stream_uni 0x0131
#define i7_glk_get_line_stream_uni 0x0132
#define i7_glk_stream_open_file_uni 0x0138
#define i7_glk_stream_open_memory_uni 0x0139
#define i7_glk_stream_open_resource_uni 0x013A
#define i7_glk_request_char_event_uni 0x0140
#define i7_glk_request_line_event_uni 0x0141
#define i7_glk_set_echo_line_event 0x0150
#define i7_glk_set_terminators_line_event 0x0151
#define i7_glk_current_time 0x0160
#define i7_glk_current_simple_time 0x0161
#define i7_glk_time_to_date_utc 0x0168
#define i7_glk_time_to_date_local 0x0169
#define i7_glk_simple_time_to_date_utc 0x016A
#define i7_glk_simple_time_to_date_local 0x016B
#define i7_glk_date_to_time_utc 0x016C
#define i7_glk_date_to_time_local 0x016D
#define i7_glk_date_to_simple_time_utc 0x016E
#define i7_glk_date_to_simple_time_local 0x016F
void glulx_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc, i7word_t *z);
i7word_t fn_i7_mgl_IndefArt(i7process_t *proc, i7word_t i7_mgl_local_obj, i7word_t i7_mgl_local_i);
i7word_t fn_i7_mgl_DefArt(i7process_t *proc, i7word_t i7_mgl_local_obj, i7word_t i7_mgl_local_i);
i7word_t fn_i7_mgl_CIndefArt(i7process_t *proc, i7word_t i7_mgl_local_obj, i7word_t i7_mgl_local_i);
i7word_t fn_i7_mgl_CDefArt(i7process_t *proc, i7word_t i7_mgl_local_obj, i7word_t i7_mgl_local_i);
i7word_t fn_i7_mgl_PrintShortName(i7process_t *proc, i7word_t i7_mgl_local_obj, i7word_t i7_mgl_local_i);
void i7_print_name(i7process_t *proc, i7word_t x);
void i7_print_object(i7process_t *proc, i7word_t x);
void i7_print_box(i7process_t *proc, i7word_t x);
void i7_read(i7process_t *proc, i7word_t x);
=

= (text to inform7_clib.c)
i7_glk_event i7_events_ring_buffer[32];
int i7_rb_back = 0, i7_rb_front = 0;

i7_glk_event *i7_next_event(i7process_t *proc) {
	if (i7_rb_front == i7_rb_back) return NULL;
	i7_glk_event *e = &(i7_events_ring_buffer[i7_rb_back]);
	i7_rb_back++; if (i7_rb_back == 32) i7_rb_back = 0;
	return e;
}

void i7_make_event(i7process_t *proc, i7_glk_event e) {
	i7_events_ring_buffer[i7_rb_front] = e;
	i7_rb_front++; if (i7_rb_front == 32) i7_rb_front = 0;
}

i7word_t i7_do_glk_select(i7process_t *proc, i7word_t structure) {
	i7_glk_event *e = i7_next_event(proc);
	if (e == NULL) {
		fprintf(stderr, "No events available to select\n"); i7_fatal_exit(proc);
	}
	if (structure == -1) {
		i7_push(proc, e->type);
		i7_push(proc, e->win_id);
		i7_push(proc, e->val1);
		i7_push(proc, e->val2);
	} else {
		if (structure) {
			i7_write_word(proc, structure, 0, e->type, i7_lvalue_SET);
			i7_write_word(proc, structure, 1, e->win_id, i7_lvalue_SET);
			i7_write_word(proc, structure, 2, e->val1, i7_lvalue_SET);
			i7_write_word(proc, structure, 3, e->val2, i7_lvalue_SET);
		}
	}
	return 0;
}

int i7_no_lr = 0;
i7word_t i7_do_glk_request_line_event(i7process_t *proc, i7word_t window_id, i7word_t buffer, i7word_t max_len, i7word_t init_len) {
	i7_glk_event e;
	e.type = evtype_LineInput;
	e.win_id = window_id;
	e.val1 = 1;
	e.val2 = 0;
	wchar_t c; int pos = init_len;
	if (proc->sender == NULL) i7_benign_exit(proc);
	char *s = (proc->sender)(proc->send_count++);
	int i = 0;
	while (1) {
		c = s[i++];
		if ((c == EOF) || (c == 0) || (c == '\n') || (c == '\r')) break;
		if (pos < max_len) i7_write_byte(proc, buffer + pos++, c);
	}
	if (pos < max_len) i7_write_byte(proc, buffer + pos, 0); else i7_write_byte(proc, buffer + max_len-1, 0);
	e.val1 = pos;
	i7_make_event(proc, e);
	if (i7_no_lr++ == 1000) {
		fprintf(stdout, "[Too many line events: terminating to prevent hang]\n"); exit(0);
	}
	return 0;
}


void glulx_glk(i7process_t *proc, i7word_t glk_api_selector, i7word_t varargc, i7word_t *z) {
	i7_debug_stack("glulx_glk");
	i7word_t args[5] = { 0, 0, 0, 0, 0 }, argc = 0;
	while (varargc > 0) {
		i7word_t v = i7_pull(proc);
		if (argc < 5) args[argc++] = v;
		varargc--;
	}
	
	int rv = 0;
	switch (glk_api_selector) {
		case i7_glk_gestalt:
			rv = 1; break;
		case i7_glk_window_iterate:
			rv = 0; break;
		case i7_glk_window_open:
			rv = i7_do_glk_window_open(proc, args[0], args[1], args[2], args[3], args[4]); break;
		case i7_glk_set_window:
			i7_do_glk_stream_set_current(proc, i7_stream_of_window(proc, args[0])); break;
		case i7_glk_stream_iterate:
			rv = 0; break;
		case i7_glk_fileref_iterate:
			rv = 0; break;
		case i7_glk_stylehint_set:
			rv = 0; break;
		case i7_glk_schannel_iterate:
			rv = 0; break;
		case i7_glk_schannel_create:
			rv = 0; break;
		case i7_glk_set_style:
			rv = 0; break;
		case i7_glk_window_move_cursor:
			rv = 0; break;
		case i7_glk_stream_get_position:
			rv = i7_do_glk_stream_get_position(proc, args[0]); break;
		case i7_glk_window_get_size:
			if (args[0]) i7_write_word(proc, args[0], 0, 80, i7_lvalue_SET);
			if (args[1]) i7_write_word(proc, args[1], 0, 8, i7_lvalue_SET);
			rv = 0; break;
		case i7_glk_request_line_event:
			rv = i7_do_glk_request_line_event(proc, args[0], args[1], args[2], args[3]); break;
		case i7_glk_select:
			rv = i7_do_glk_select(proc, args[0]); break;
		case i7_glk_stream_close:
			i7_do_glk_stream_close(proc, args[0], args[1]); break;
		case i7_glk_stream_set_current:
			i7_do_glk_stream_set_current(proc, args[0]); break;
		case i7_glk_stream_get_current:
			rv = i7_do_glk_stream_get_current(proc); break;
		case i7_glk_stream_open_memory:
			rv = i7_do_glk_stream_open_memory(proc, args[0], args[1], args[2], args[3]); break;
		case i7_glk_stream_open_memory_uni:
			rv = i7_do_glk_stream_open_memory_uni(proc, args[0], args[1], args[2], args[3]); break;
		case i7_glk_fileref_create_by_name:
			rv = i7_do_glk_fileref_create_by_name(proc, args[0], args[1], args[2]); break;
		case i7_glk_fileref_does_file_exist:
			rv = i7_do_glk_fileref_does_file_exist(proc, args[0]); break;
		case i7_glk_stream_open_file:
			rv = i7_do_glk_stream_open_file(proc, args[0], args[1], args[2]); break;
		case i7_glk_fileref_destroy:
			rv = 0; break;
		case i7_glk_char_to_lower:
			rv = args[0];
			if (((rv >= 0x41) && (rv <= 0x5A)) ||
				((rv >= 0xC0) && (rv <= 0xD6)) ||
				((rv >= 0xD8) && (rv <= 0xDE))) rv += 32;
			break;
		case i7_glk_char_to_upper:
			rv = args[0];
			if (((rv >= 0x61) && (rv <= 0x7A)) ||
				((rv >= 0xE0) && (rv <= 0xF6)) ||
				((rv >= 0xF8) && (rv <= 0xFE))) rv -= 32;
			break;
		case i7_glk_stream_set_position:
			i7_do_glk_stream_set_position(proc, args[0], args[1], args[2]); break;
		case i7_glk_put_char_stream:
			i7_do_glk_put_char_stream(proc, args[0], args[1]); break;
		case i7_glk_get_char_stream:
			rv = i7_do_glk_get_char_stream(proc, args[0]); break;
		default:
			printf("Unimplemented: glulx_glk %d.\n", glk_api_selector); i7_fatal_exit(proc);
			break;
	}
	if (z) *z = rv;
}

void i7_print_name(i7process_t *proc, i7word_t x) {
	fn_i7_mgl_PrintShortName(proc, x, 0);
}

void i7_print_object(i7process_t *proc, i7word_t x) {
	i7_print_decimal(proc, x);
}

void i7_print_box(i7process_t *proc, i7word_t x) {
	printf("Unimplemented: i7_print_box.\n");
	i7_fatal_exit(proc);
}

void i7_read(i7process_t *proc, i7word_t x) {
	printf("Only available on 16-bit architectures, which this is not: i7_read.\n");
	i7_fatal_exit(proc);
}

i7word_t fn_i7_mgl_pending_boxed_quotation(i7process_t *proc) {
	return 0;
}
=

@

= (text to inform7_clib.h)
#endif
=

= (text to inform7_clib.c)
#endif
=