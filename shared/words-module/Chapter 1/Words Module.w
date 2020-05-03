[WordsModule::] Words Module.

Setting up the use of this module.

@ This section simoly sets up the module in ways expected by |foundation|, and
contains no code of interest. The following constant exists only in tools
which use this module:

@d WORDS_MODULE TRUE

@ To begin with, this module needs to allocate memory:

@e LEXER_TEXT_MREASON
@e LEXER_WORDS_MREASON

@e source_file_MT
@e vocabulary_entry_array_MT
@e nonterminal_MT
@e production_MT
@e production_list_MT
@e ptoken_MT

=
ALLOCATE_INDIVIDUALLY(source_file)
ALLOCATE_IN_ARRAYS(vocabulary_entry, 100)
ALLOCATE_INDIVIDUALLY(nonterminal)
ALLOCATE_INDIVIDUALLY(production_list)
ALLOCATE_INDIVIDUALLY(production)
ALLOCATE_INDIVIDUALLY(ptoken)

@ Like all modules, this one must define a |start| and |end| function:

=
void WordsModule::start(void) {
	Memory::reason_name(LEXER_TEXT_MREASON, "source text");
	Memory::reason_name(LEXER_WORDS_MREASON, "source text details");
	@<Register this module's memory allocation reasons@>;
	@<Register this module's stream writers@>;
	@<Register this module's debugging log aspects@>;
	@<Register this module's debugging log writers@>;
	Lexer::start();
	Vocabulary::create_punctuation();
	Preform::begin();
}
void WordsModule::end(void) {
}

@<Register this module's memory allocation reasons@> =
	;

@<Register this module's stream writers@> =
	Writers::register_writer('A', &WordAssemblages::writer);
	Writers::register_writer_I('N', &Lexer::writer);
	Writers::register_writer('V', &Vocabulary::writer);
	Writers::register_writer_W('W', &Wordings::writer);

@

@e LEXICAL_OUTPUT_DA
@e VOCABULARY_DA

@<Register this module's debugging log aspects@> =
	Log::declare_aspect(LEXICAL_OUTPUT_DA, L"lexical output", FALSE, FALSE);
	Log::declare_aspect(VOCABULARY_DA, L"vocabulary", FALSE, FALSE);

@<Register this module's debugging log writers@> =
	Writers::register_logger('f', WordAssemblages::log);
	Writers::register_logger('v', Vocabulary::log);