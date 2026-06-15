import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/ollama_client.dart';
import '../settings/app_settings.dart';
import '../../shared/database/database_helper.dart';

// Subjects
import '../../features/subjects/data/datasources/subjects_local_datasource.dart';
import '../../features/subjects/data/repositories/subjects_repository_impl.dart';
import '../../features/subjects/domain/repositories/subjects_repository.dart';
import '../../features/subjects/domain/usecases/subject_usecases.dart';
import '../../features/subjects/presentation/bloc/subjects_bloc.dart';

// Documents
import '../../features/documents/data/datasources/documents_local_datasource.dart';
import '../../features/documents/data/datasources/pdf_text_extractor.dart';
import '../../features/documents/data/repositories/documents_repository_impl.dart';
import '../../features/documents/domain/repositories/documents_repository.dart';
import '../../features/documents/domain/usecases/document_usecases.dart';
import '../../features/documents/presentation/bloc/documents_bloc.dart';

// Chat
import '../../features/chat/data/datasources/chat_local_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/chat_usecases.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';

// Flashcards
import '../../features/flashcards/data/datasources/flashcards_datasource.dart';
import '../../features/flashcards/data/repositories/flashcards_repository_impl.dart';
import '../../features/flashcards/domain/repositories/flashcards_repository.dart';
import '../../features/flashcards/domain/usecases/flashcard_usecases.dart';
import '../../features/flashcards/presentation/bloc/flashcards_bloc.dart';

// Quiz
import '../../features/quiz/data/datasources/quiz_datasource.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../../features/quiz/domain/repositories/quiz_repository.dart';
import '../../features/quiz/domain/usecases/quiz_usecases.dart';
import '../../features/quiz/presentation/bloc/quiz_bloc.dart';

/// Globalny kontener DI. Wywoływany raz w `main()` przed runApp.
final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // ==================================================== CORE / SHARED
  // Ustawienia muszą być gotowe (wczytane z dysku) zanim powstanie OllamaClient,
  // który z nich czyta adres serwera i nazwy modeli.
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<AppSettings>(() => AppSettings(prefs)..load());

  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  sl.registerLazySingleton<OllamaClient>(
    () => OllamaClient(settings: sl()),
  );

  // ==================================================== SUBJECTS
  sl.registerLazySingleton<SubjectsLocalDataSource>(
    () => SubjectsLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<SubjectsRepository>(
    () => SubjectsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetSubjectsUseCase(sl()));
  sl.registerLazySingleton(() => CreateSubjectUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSubjectUseCase(sl()));
  sl.registerLazySingleton(() => GetSubjectByIdUseCase(sl()));

  sl.registerFactory(() => SubjectsBloc(
        getSubjects: sl(),
        createSubject: sl(),
        deleteSubject: sl(),
      ));

  // ==================================================== DOCUMENTS
  sl.registerLazySingleton(() => PdfTextExtractor());
  sl.registerLazySingleton<DocumentsLocalDataSource>(
    () => DocumentsLocalDataSourceImpl(
      dbHelper: sl(),
      ollamaClient: sl(),
      pdfExtractor: sl(),
    ),
  );
  sl.registerLazySingleton<DocumentsRepository>(
    () => DocumentsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetDocumentsUseCase(sl()));
  sl.registerLazySingleton(() => UploadDocumentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDocumentUseCase(sl()));
  sl.registerLazySingleton(() => SearchRelevantChunksUseCase(sl()));
  sl.registerLazySingleton(() => GetAllChunksUseCase(sl()));

  sl.registerFactory(() => DocumentsBloc(
        getDocuments: sl(),
        uploadDocument: sl(),
        deleteDocument: sl(),
      ));

  // ==================================================== CHAT
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      local: sl(),
      documentsRepository: sl(),
      ollamaClient: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(() => DeleteConversationUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SaveMessageUseCase(sl()));
  sl.registerLazySingleton(() => StreamRagAnswerUseCase(sl()));

  sl.registerFactory(() => ChatBloc(
        getConversations: sl(),
        createConversation: sl(),
        deleteConversation: sl(),
        getMessages: sl(),
        saveMessage: sl(),
        streamRagAnswer: sl(),
      ));

  // ==================================================== FLASHCARDS
  sl.registerLazySingleton<FlashcardsDataSource>(
    () => FlashcardsDataSourceImpl(
      dbHelper: sl(),
      ollamaClient: sl(),
      documentsRepository: sl(),
    ),
  );
  sl.registerLazySingleton<FlashcardsRepository>(
    () => FlashcardsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetFlashcardsUseCase(sl()));
  sl.registerLazySingleton(() => GetDueFlashcardsUseCase(sl()));
  sl.registerLazySingleton(() => GenerateFlashcardsUseCase(sl()));
  sl.registerLazySingleton(() => CreateFlashcardUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFlashcardUseCase(sl()));
  sl.registerLazySingleton(() => ReviewFlashcardUseCase(sl()));

  sl.registerFactory(() => FlashcardsBloc(
        getFlashcards: sl(),
        generateFlashcards: sl(),
        createFlashcard: sl(),
        deleteFlashcard: sl(),
        reviewFlashcard: sl(),
      ));

  // ==================================================== QUIZ
  sl.registerLazySingleton<QuizDataSource>(
    () => QuizDataSourceImpl(
      dbHelper: sl(),
      ollamaClient: sl(),
      documentsRepository: sl(),
    ),
  );
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetQuizzesUseCase(sl()));
  sl.registerLazySingleton(() => GetQuizByIdUseCase(sl()));
  sl.registerLazySingleton(() => GenerateQuizUseCase(sl()));
  sl.registerLazySingleton(() => DeleteQuizUseCase(sl()));
  sl.registerLazySingleton(() => SaveQuizAttemptUseCase(sl()));
  sl.registerLazySingleton(() => GetQuizAttemptsUseCase(sl()));

  sl.registerFactory(() => QuizBloc(
        getQuizzes: sl(),
        getQuizById: sl(),
        generateQuiz: sl(),
        deleteQuiz: sl(),
        saveAttempt: sl(),
      ));
}
