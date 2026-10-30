import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/analytics_remote_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/automation_remote_data_source.dart';
import '../../data/datasources/billing_remote_data_source.dart';
import '../../data/datasources/customers_remote_data_source.dart';
import '../../data/datasources/inbox_remote_data_source.dart';
import '../../data/datasources/instagram_remote_data_source.dart';
import '../../data/datasources/invoices_remote_data_source.dart';
import '../../data/datasources/knowledge_remote_data_source.dart';
import '../../data/datasources/products_remote_data_source.dart';
import '../../data/datasources/tickets_remote_data_source.dart';
import '../../data/datasources/tutorials_remote_data_source.dart';
import '../../data/datasources/workspace_remote_data_source.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/automation_repository_impl.dart';
import '../../data/repositories/billing_repository_impl.dart';
import '../../data/repositories/customers_repository_impl.dart';
import '../../data/repositories/inbox_repository_impl.dart';
import '../../data/repositories/instagram_repository_impl.dart';
import '../../data/repositories/invoices_repository_impl.dart';
import '../../data/repositories/knowledge_repository_impl.dart';
import '../../data/repositories/products_repository_impl.dart';
import '../../data/repositories/tickets_repository_impl.dart';
import '../../data/repositories/tutorials_repository_impl.dart';
import '../../data/repositories/workspace_repository_impl.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/automation_repository.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/customers_repository.dart';
import '../../domain/repositories/inbox_repository.dart';
import '../../domain/repositories/instagram_repository.dart';
import '../../domain/repositories/invoices_repository.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../../domain/repositories/products_repository.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../../domain/repositories/tutorials_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../presentation/session/session_bloc.dart';
import '../../router/app_router.dart';
import '../api_client.dart';
import '../logging/app_log.dart';
import '../token_store.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  AppLog.di('شروع ثبت وابستگی‌ها');
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final tokens = TokenStore();
  await tokens.load();
  sl.registerSingleton<TokenStore>(tokens);
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  _bind<AuthRemoteDataSource, AuthRepository>(AuthRemoteDataSourceImpl.new, AuthRepositoryImpl.new);
  _bind<WorkspaceRemoteDataSource, WorkspaceRepository>(WorkspaceRemoteDataSourceImpl.new, WorkspaceRepositoryImpl.new);
  _bind<InstagramRemoteDataSource, InstagramRepository>(InstagramRemoteDataSourceImpl.new, InstagramRepositoryImpl.new);
  _bind<KnowledgeRemoteDataSource, KnowledgeRepository>(KnowledgeRemoteDataSourceImpl.new, KnowledgeRepositoryImpl.new);
  _bind<CustomersRemoteDataSource, CustomersRepository>(CustomersRemoteDataSourceImpl.new, CustomersRepositoryImpl.new);
  _bind<InvoicesRemoteDataSource, InvoicesRepository>(InvoicesRemoteDataSourceImpl.new, InvoicesRepositoryImpl.new);
  _bind<ProductsRemoteDataSource, ProductsRepository>(ProductsRemoteDataSourceImpl.new, ProductsRepositoryImpl.new);
  _bind<InboxRemoteDataSource, InboxRepository>(InboxRemoteDataSourceImpl.new, InboxRepositoryImpl.new);
  _bind<AutomationRemoteDataSource, AutomationRepository>(AutomationRemoteDataSourceImpl.new, AutomationRepositoryImpl.new);
  _bind<AnalyticsRemoteDataSource, AnalyticsRepository>(AnalyticsRemoteDataSourceImpl.new, AnalyticsRepositoryImpl.new);
  _bind<BillingRemoteDataSource, BillingRepository>(BillingRemoteDataSourceImpl.new, BillingRepositoryImpl.new);
  _bind<TicketsRemoteDataSource, TicketsRepository>(TicketsRemoteDataSourceImpl.new, TicketsRepositoryImpl.new);
  _bind<TutorialsRemoteDataSource, TutorialsRepository>(TutorialsRemoteDataSourceImpl.new, TutorialsRepositoryImpl.new);

  sl.registerLazySingleton<SessionBloc>(
    () => SessionBloc(
      auth: sl(),
      workspaces: sl(),
      knowledge: sl(),
      instagram: sl(),
      prefs: sl(),
      tokens: sl(),
    ),
  );
  sl<ApiClient>().onUnauthorized = sl<SessionBloc>().onUnauthorized;
  sl.registerLazySingleton<GoRouter>(() => buildRouter(sl()));
  AppLog.di('datasource و repository هر فیچر ثبت شد');
}

void _bind<D extends Object, R extends Object>(D Function(ApiClient client) source, R Function(D remote) repository) {
  sl.registerLazySingleton<D>(() => source(sl()));
  sl.registerLazySingleton<R>(() => repository(sl()));
  AppLog.di('$D → $R');
}
