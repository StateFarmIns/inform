[CodeGen::Pipeline::] Pipelines.

To build and run through pipelines of code generation stages.

@h Steps.
A "step" is a single step in a pipeline of commands: it consists of a
choice of stage, together with a choice of argument. The other elements here
are all temporary storage for information needed when the step is run; they
have no meaningful contents when the step is not running.

=
typedef struct pipeline_step {
	struct pipeline_stage *step_stage;
	struct text_stream *step_argument;
	struct code_generator *generator_argument;
	int take_generator_argument_from_VM;
	struct text_stream *package_URL_argument;
	struct inter_package *package_argument;
	struct filename *parsed_filename;
	struct linked_list *the_PP; /* of |pathname| */
	int to_debugging_log;
	int from_memory;
	int repository_argument;
	struct text_stream *to_stream;
	struct linked_list *requirements_list; /* of |inter_library| */
	struct inter_tree *repository;
	struct codegen_pipeline *pipeline;
	struct target_vm *for_VM;
	CLASS_DEFINITION
} pipeline_step;

pipeline_step *CodeGen::Pipeline::new_step(void) {
	pipeline_step *step = CREATE(pipeline_step);
	step->step_stage = NULL;
	step->step_argument = NULL;
	step->package_URL_argument = NULL;
	step->package_argument = NULL;
	step->repository_argument = 0;
	step->generator_argument = NULL;
	step->take_generator_argument_from_VM = FALSE;
	CodeGen::Pipeline::clean_step(step);
	return step;
}

@ This wipes clean the temporary storage for a step.

=
void CodeGen::Pipeline::clean_step(pipeline_step *step) {
	step->parsed_filename = NULL;
	step->to_stream = NULL;
	step->to_debugging_log = FALSE;
	step->from_memory = FALSE;
	step->the_PP = NULL;
	step->repository = NULL;
	step->pipeline = NULL;
	step->requirements_list = NEW_LINKED_LIST(inter_library);
	step->for_VM = NULL;
}

@ Here we write a textual description to a string, which is useful for
logging:

=
void CodeGen::Pipeline::write_step(OUTPUT_STREAM, pipeline_step *step) {
	WRITE("%S", step->step_stage->stage_name);
	if (step->step_stage->stage_arg != NO_STAGE_ARG) {
		if (step->repository_argument > 0) {
			WRITE(" %d", step->repository_argument);
			if (Str::len(step->package_URL_argument) > 0) WRITE(":%S", step->package_URL_argument);
		} else {
			if (Str::len(step->package_URL_argument) > 0) WRITE(" %S", step->package_URL_argument);
		}
		if (step->step_stage->takes_repository) WRITE(" <- %S", step->step_argument);
		if (step->generator_argument) WRITE(" %S -> %S", step->generator_argument->generator_name, step->step_argument);
	}
}

pipeline_step *CodeGen::Pipeline::read_step(text_stream *step, dictionary *D,
	text_file_position *tfp) {
	CodeGen::Stage::make_stages();
	Generators::make_all();
	pipeline_step *ST = CodeGen::Pipeline::new_step();
	match_results mr = Regexp::create_mr();
	int left_arrow_used = FALSE;
	int allow_unknown_variables = FALSE;
	if (Regexp::match(&mr, step, L"optionally-%c+")) allow_unknown_variables = TRUE;
	if (Regexp::match(&mr, step, L"(%c+?) *<- *(%c*)")) {
		if (Str::len(mr.exp[1]) > 0) {
			ST->step_argument = CodeGen::Pipeline::read_parameter(mr.exp[1], D, tfp, allow_unknown_variables);
			if (ST->step_argument == NULL) return NULL;
		} else {
			Errors::in_text_file_S(I"no source to right of arrow", tfp);
			return NULL;
		}
		Str::copy(step, mr.exp[0]);
		left_arrow_used = TRUE;
	} else if (Regexp::match(&mr, step, L"(%c+?) (%C+) *-> *(%c*)")) {
		code_generator *cgt = Generators::find(mr.exp[1]);
		if (cgt == NULL) {
			TEMPORARY_TEXT(ERR)
			WRITE_TO(ERR, "no such code generation format as '%S'\n", mr.exp[1]);
			Errors::in_text_file_S(ERR, tfp);
			DISCARD_TEXT(ERR)
			return NULL;
		} else {
			ST->generator_argument = cgt;
		}
		ST->step_argument = CodeGen::Pipeline::read_parameter(mr.exp[2], D, tfp, allow_unknown_variables);
		if (ST->step_argument == NULL) return NULL;
		Str::copy(step, mr.exp[0]);
	} else if (Regexp::match(&mr, step, L"(%c+?) *-> *(%c*)")) {
		ST->generator_argument = NULL;
		ST->take_generator_argument_from_VM = TRUE;
		ST->step_argument = CodeGen::Pipeline::read_parameter(mr.exp[1], D, tfp, allow_unknown_variables);
		if (ST->step_argument == NULL) return NULL;
		Str::copy(step, mr.exp[0]);
	}
	if (Regexp::match(&mr, step, L"(%C+?) (%d)")) {
		ST->repository_argument = Str::atoi(mr.exp[1], 0);
		Str::copy(step, mr.exp[0]);
	} else if (Regexp::match(&mr, step, L"(%C+?) (%d):(%c*)")) {
		ST->repository_argument = Str::atoi(mr.exp[1], 0);
		if (Str::len(mr.exp[2]) > 0) {
			ST->package_URL_argument = CodeGen::Pipeline::read_parameter(mr.exp[2], D, tfp, allow_unknown_variables);
			if (ST->package_URL_argument == NULL) return NULL;
		}
		Str::copy(step, mr.exp[0]);
	} else if (Regexp::match(&mr, step, L"(%C+?) (%c+)")) {
		ST->package_URL_argument = CodeGen::Pipeline::read_parameter(mr.exp[1], D, tfp, allow_unknown_variables);
		if (ST->package_URL_argument == NULL) return NULL;
		Str::copy(step, mr.exp[0]);
	}

	pipeline_stage *stage;
	LOOP_OVER(stage, pipeline_stage)
		if (Str::eq(step, stage->stage_name))
			ST->step_stage = stage;
	if (ST->step_stage == NULL) {
		TEMPORARY_TEXT(ERR)
		WRITE_TO(ERR, "no such stage as '%S'\n", step);
		Errors::in_text_file_S(ERR, tfp);
		DISCARD_TEXT(ERR)
		return NULL;
	}
	if (ST->step_stage->takes_repository) {
		if (left_arrow_used == FALSE) {
			Errors::in_text_file_S(I"this stage should take a left arrow and a source", tfp);
			return NULL;
		}
	} else {
		if (left_arrow_used) {
			Errors::in_text_file_S(I"this stage should not take a left arrow and a source", tfp);
			return NULL;
		}
	}
	
	Regexp::dispose_of(&mr);
	return ST;
}

text_stream *CodeGen::Pipeline::read_parameter(text_stream *from, dictionary *D,
	text_file_position *tfp, int allow_unknown_variables) {
	if (Str::get_first_char(from) == '*') {
		text_stream *find = Dictionaries::get_text(D, from);
		if (find) return Str::duplicate(find);
		if (allow_unknown_variables == FALSE) {
			TEMPORARY_TEXT(ERR)
			WRITE_TO(ERR, "no such pipeline variable as '%S'\n", from);
			Errors::in_text_file_S(ERR, tfp);
			DISCARD_TEXT(ERR)
		} else {
			return I"";
		}
	}
	return Str::duplicate(from);
}

@h Pipelines.
And then a pipeline is just a linked list of steps.

=
typedef struct codegen_pipeline {
	struct dictionary *variables;
	struct inter_tree *memory_repository;
	struct inter_tree *repositories[10];
	struct linked_list *steps; /* of |pipeline_step| */
	int erroneous;
	CLASS_DEFINITION
} codegen_pipeline;

dictionary *CodeGen::Pipeline::basic_dictionary(text_stream *leafname) {
	dictionary *D = Dictionaries::new(16, TRUE);
	if (Str::len(leafname) > 0) Str::copy(Dictionaries::create_text(D, I"*out"), leafname);
	Str::copy(Dictionaries::create_text(D, I"*log"), I"*log");
	return D;
}

codegen_pipeline *CodeGen::Pipeline::new(dictionary *D) {
	codegen_pipeline *S = CREATE(codegen_pipeline);
	S->variables = D;
	S->steps = NEW_LINKED_LIST(pipeline_step);
	S->memory_repository = NULL;
	S->erroneous = FALSE;
	for (int i=0; i<10; i++) S->repositories[i] = NULL;
	return S;
}

codegen_pipeline *CodeGen::Pipeline::parse_from_file(filename *F, dictionary *D) {
	codegen_pipeline *S = CodeGen::Pipeline::new(D);
	TextFiles::read(F, FALSE, "can't open inter pipeline file",
		TRUE, CodeGen::Pipeline::scan_line, NULL, (void *) S);
	if (S->erroneous) return NULL;
	return S;
}

void CodeGen::Pipeline::scan_line(text_stream *line, text_file_position *tfp, void *X) {
	codegen_pipeline *S = (codegen_pipeline *) X;
	CodeGen::Pipeline::parse_into(S, line, tfp);
}

codegen_pipeline *CodeGen::Pipeline::parse(text_stream *instructions, dictionary *D) {
	codegen_pipeline *S = CodeGen::Pipeline::new(D);
	CodeGen::Pipeline::parse_into(S, instructions, NULL);
	if (S->erroneous) return NULL;
	return S;
}

void CodeGen::Pipeline::parse_into(codegen_pipeline *S, text_stream *instructions,
	text_file_position *tfp) {
	TEMPORARY_TEXT(T)
	LOOP_THROUGH_TEXT(P, instructions)
		if (Characters::is_babel_whitespace(Str::get(P)))
			PUT_TO(T, ' ');
		else
			PUT_TO(T, Str::get(P));
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, T, L" *(%c+?) *,+ *(%c*?) *")) {
		pipeline_step *ST = CodeGen::Pipeline::read_step(mr.exp[0], S->variables, tfp);
		if (ST) ADD_TO_LINKED_LIST(ST, pipeline_step, S->steps);
		else S->erroneous = TRUE;
		Str::copy(T, mr.exp[1]);
	}
	if (Regexp::match(&mr, T, L" *(%c+?) *")) {
		pipeline_step *ST = CodeGen::Pipeline::read_step(mr.exp[0], S->variables, tfp);
		if (ST) ADD_TO_LINKED_LIST(ST, pipeline_step, S->steps);
		else S->erroneous = TRUE;
	}
	Regexp::dispose_of(&mr);
	DISCARD_TEXT(T)
}

void CodeGen::Pipeline::set_repository(codegen_pipeline *S, inter_tree *I) {
	S->memory_repository = I;
}

void CodeGen::Pipeline::run(pathname *P, codegen_pipeline *S, linked_list *PP,
	linked_list *requirements_list, target_vm *VM) {
	if (S == NULL) return;
	stopwatch_timer *within = NULL;
	#ifdef CORE_MODULE
	within = inform7_timer;
	#endif
	stopwatch_timer *pipeline_timer =
		Time::start_stopwatch(within, I"running Inter pipeline");

	int step_count = 0, step_total = 0;
	pipeline_step *step;
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps) step_total++;

	int active = TRUE;
	stopwatch_timer *prep_timer = NULL;
	LOOP_OVER_LINKED_LIST(step, pipeline_step, S->steps)
		if (active) {
			if (prep_timer == NULL)
				prep_timer = Time::start_stopwatch(pipeline_timer, I"step preparation");
			else
				Time::resume_stopwatch(prep_timer);
			if (S->repositories[step->repository_argument] == NULL)
				S->repositories[step->repository_argument] = InterTree::new();
			inter_tree *I = S->repositories[step->repository_argument];
			if (I == NULL) internal_error("no repository");
			CodeGen::Pipeline::prepare_to_run(I);
			CodeGen::Pipeline::lint(I);

			CodeGen::Pipeline::clean_step(step);
			step->the_PP = PP;
			step->repository = I;
			step->pipeline = S;
			step->requirements_list = requirements_list;
			step->for_VM = VM;
			if ((VM) && (step->take_generator_argument_from_VM)) {
				step->generator_argument = Generators::find_for(VM);
				if (step->generator_argument == NULL) {
					#ifdef PROBLEMS_MODULE
					Problems::fatal("Unable to guess target format");
					#endif
					#ifndef PROBLEMS_MODULE
					Errors::fatal("Unable to guess target format");
					exit(1);
					#endif
				}
			}
			
			step->package_argument = NULL;
			if (Str::len(step->package_URL_argument) > 0) {
				step->package_argument =
					Inter::Packages::by_url(step->repository, step->package_URL_argument);
				if (step->package_argument == NULL) {
					CodeGen::Pipeline::error_with("no such package as '%S'", step->package_URL_argument);
					continue;
				}
			}
			
			Time::stop_stopwatch(prep_timer);

			int skip_step = FALSE;
			TEMPORARY_TEXT(STAGE_NAME)
			WRITE_TO(STAGE_NAME, "inter step %d/%d: ", ++step_count, step_total);
			CodeGen::Pipeline::write_step(STAGE_NAME, step);
			Log::new_stage(STAGE_NAME);
			stopwatch_timer *step_timer =
				Time::start_stopwatch(pipeline_timer, STAGE_NAME);
			DISCARD_TEXT(STAGE_NAME)

			if ((step->step_stage->stage_arg == FILE_STAGE_ARG) ||
				(step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == OPTIONAL_TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_FILE_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) {
				if (Str::len(step->step_argument) == 0) {
					if (step->step_stage->stage_arg == OPTIONAL_TEXT_OUT_STAGE_ARG) {
						skip_step = TRUE;
					} else {
						#ifdef PROBLEMS_MODULE
						Problems::fatal("No filename given in pipeline step");
						#endif
						#ifndef PROBLEMS_MODULE
						Errors::fatal("No filename given in pipeline step");
						exit(1);
						#endif
					}
				} else {
					if (Str::eq(step->step_argument, I"*log")) {
						step->to_debugging_log = TRUE;
					} else if (Str::eq(step->step_argument, I"*memory")) {
						S->repositories[step->repository_argument] = S->memory_repository;
						skip_step = TRUE;
					} else {
						int slashes = FALSE;
						LOOP_THROUGH_TEXT(pos, step->step_argument)
							if (Str::get(pos) == '/')
								slashes = TRUE;
						if (slashes) step->parsed_filename = Filenames::from_text(step->step_argument);
						else step->parsed_filename = Filenames::in(P, step->step_argument);
					}
				}
			}

			text_stream text_output_struct; /* For any text file we might write */
			text_stream *T = &text_output_struct;
			if (step->to_debugging_log) {
				step->to_stream = DL;
			} else if ((step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == OPTIONAL_TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) {
				if ((step->parsed_filename) &&
					(STREAM_OPEN_TO_FILE(T, step->parsed_filename, ISO_ENC) == FALSE)) {
					#ifdef PROBLEMS_MODULE
					Problems::fatal_on_file("Can't open output file", step->parsed_filename);
					#endif
					#ifndef PROBLEMS_MODULE
					Errors::fatal_with_file("Can't open output file", step->parsed_filename);
					exit(1);
					#endif
				}
				step->to_stream = T;
			}

			if (skip_step == FALSE)
				active = (*(step->step_stage->execute))(step);

			if (((step->step_stage->stage_arg == TEXT_OUT_STAGE_ARG) ||
				(step->step_stage->stage_arg == EXT_TEXT_OUT_STAGE_ARG)) &&
				(step->to_debugging_log == FALSE)) {
				STREAM_CLOSE(T);
			}
			Time::stop_stopwatch(step_timer);
		}
	Time::stop_stopwatch(pipeline_timer);
}

@h Following.

=
inter_symbol *unchecked_kind_symbol = NULL;
inter_symbol *unchecked_function_symbol = NULL;
inter_symbol *typeless_int_symbol = NULL;
inter_symbol *list_of_unchecked_kind_symbol = NULL;
inter_symbol *object_kind_symbol = NULL;
inter_symbol *action_kind_symbol = NULL;
inter_symbol *truth_state_kind_symbol = NULL;
inter_symbol *direction_kind_symbol = NULL;

inter_symbol *verb_directive_reverse_symbol = NULL;
inter_symbol *verb_directive_slash_symbol = NULL;
inter_symbol *verb_directive_divider_symbol = NULL;
inter_symbol *verb_directive_result_symbol = NULL;
inter_symbol *verb_directive_special_symbol = NULL;
inter_symbol *verb_directive_number_symbol = NULL;
inter_symbol *verb_directive_noun_symbol = NULL;
inter_symbol *verb_directive_multi_symbol = NULL;
inter_symbol *verb_directive_multiinside_symbol = NULL;
inter_symbol *verb_directive_multiheld_symbol = NULL;
inter_symbol *verb_directive_held_symbol = NULL;
inter_symbol *verb_directive_creature_symbol = NULL;
inter_symbol *verb_directive_topic_symbol = NULL;
inter_symbol *verb_directive_multiexcept_symbol = NULL;

inter_symbol *code_ptype_symbol = NULL;
inter_symbol *plain_ptype_symbol = NULL;
inter_symbol *submodule_ptype_symbol = NULL;
inter_symbol *function_ptype_symbol = NULL;
inter_symbol *action_ptype_symbol = NULL;
inter_symbol *command_ptype_symbol = NULL;
inter_symbol *property_ptype_symbol = NULL;
inter_symbol *to_phrase_ptype_symbol = NULL;

void CodeGen::Pipeline::prepare_to_run(inter_tree *I) {

	code_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_code");
	plain_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_plain");
	submodule_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_submodule");
	function_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_function");
	action_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_action");
	command_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_command");
	property_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_property");
	to_phrase_ptype_symbol = InterSymbolsTables::url_name_to_symbol(I, NULL, I"/_to_phrase");

	unchecked_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_unchecked");
	unchecked_function_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_unchecked_function");
	typeless_int_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_typeless_int");
	list_of_unchecked_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_list_of_values");
	object_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_object");
	action_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_action_name");
	truth_state_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K_truth_state");
	direction_kind_symbol = Inter::Packages::search_resources_exhaustively(I, I"K3_direction");

	verb_directive_reverse_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_REVERSE");
	verb_directive_slash_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_SLASH");
	verb_directive_divider_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_DIVIDER");
	verb_directive_result_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_RESULT");
	verb_directive_special_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_SPECIAL");
	verb_directive_number_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_NUMBER");
	verb_directive_noun_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_NOUN");
	verb_directive_multi_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTI");
	verb_directive_multiinside_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTIINSIDE");
	verb_directive_multiheld_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTIHELD");
	verb_directive_held_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_HELD");
	verb_directive_creature_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_CREATURE");
	verb_directive_topic_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_TOPIC");
	verb_directive_multiexcept_symbol = Inter::Packages::search_resources_exhaustively(I, I"VERB_DIRECTIVE_MULTIEXCEPT");
}

void CodeGen::Pipeline::lint(inter_tree *I) {
	InterTree::traverse(I, CodeGen::Pipeline::visitor, NULL, NULL, -PACKAGE_IST);
}

void CodeGen::Pipeline::visitor(inter_tree *I, inter_tree_node *P, void *state) {
	inter_ti c = Inode::get_package(P)->index_n;
	inter_ti a = Inode::get_package_alt(P);
	if (c != a) {
		LOG("Frame gives package as $6, but its location is in package $6\n",
			Inode::ID_to_package(P, c),
			Inode::ID_to_package(P, a));
		WRITE_TO(STDERR, "Frame gives package as %d, but its location is in package %d\n",
			Inode::ID_to_package(P, c)->index_n,
			Inode::ID_to_package(P, a)->index_n);
		internal_error("misplaced package");
	}

	Produce::guard(Inter::Defn::verify_children_inner(P));
}

inter_symbol *CodeGen::Pipeline::uks(void) {
	if (unchecked_kind_symbol == NULL) internal_error("no unchecked kind symbol");
	return unchecked_kind_symbol;
}

void CodeGen::Pipeline::error(char *erm) {
	#ifdef PROBLEMS_MODULE
	TEMPORARY_TEXT(full)
	WRITE_TO(full, "%s", erm);
	do_not_locate_problems = TRUE;
	Problems::quote_stream(1, full);
	Problems::issue_problem_begin(NULL, erm);
	Problems::issue_problem_segment("I was unable to perform final code-generation: %1");
	Problems::issue_problem_end();
	do_not_locate_problems = FALSE;
	DISCARD_TEXT(full)
	#endif
	#ifndef PROBLEMS_MODULE
	Errors::fatal(erm);
	exit(1);
	#endif
}

void CodeGen::Pipeline::error_with(char *erm, text_stream *quoted) {
	#ifdef PROBLEMS_MODULE
	TEMPORARY_TEXT(full)
	WRITE_TO(full, erm, quoted);
	do_not_locate_problems = TRUE;
	Problems::quote_stream(1, full);
	Problems::issue_problem_begin(NULL, erm);
	Problems::issue_problem_segment("I was unable to perform final code-generation: %1");
	Problems::issue_problem_end();
	do_not_locate_problems = FALSE;
	DISCARD_TEXT(full)
	#endif
	#ifndef PROBLEMS_MODULE
	Errors::fatal_with_text(erm, quoted);
	exit(1);
	#endif
}