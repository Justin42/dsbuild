import 'package:bloc/bloc.dart';

import '../model/descriptor.dart';

part 'event.dart';
part 'state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc(super.initialState) {
    on<MessageRead>((event, emit) {
      emit(state.copyWith(messagesTotal: state.messagesTotal + 1));
    });
    on<MessageProcessed>((event, emit) {
      emit(state.copyWith(messagesProcessed: state.messagesProcessed + 1));
    });
    on<ConversationRead>((event, emit) {
      emit(state.copyWith(conversationsTotal: state.conversationsTotal + 1));
    });
    on<ConversationProcessed>((event, emit) {
      emit(state.copyWith(
          conversationsProcessed: state.conversationsProcessed + 1));
    });
    on<InputFileProcessed>((event, emit) {
      emit(state.copyWith(
          inputsProcessed: state.inputsProcessed..add(event.descriptor)));
    });
    on<OutputFileProcessed>((event, emit) {
      emit(state.copyWith(
          outputsProcessed: state.outputsProcessed..add(event.descriptor)));
    });
    on<BuildComplete>((event, emit) => emit(state.copyWith(complete: true)));
  }
}
