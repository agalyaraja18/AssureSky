import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/news_article_model.dart';
import '../../../core/services/news_service.dart';

// Events
abstract class NewsEvent {}

class NewsLoadRequested extends NewsEvent {}

class NewsRefreshRequested extends NewsEvent {}

// State
abstract class NewsState {}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<NewsArticleModel> articles;

  /// True when the network failed and these are the last cached articles.
  final bool fromCache;
  final DateTime? cachedAt;

  NewsLoaded(this.articles, {this.fromCache = false, this.cachedAt});
}

class NewsError extends NewsState {
  final String message;
  NewsError(this.message);
}

// Bloc
class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsService _service;

  NewsBloc() : _service = NewsService(), super(NewsInitial()) {
    on<NewsLoadRequested>(_onLoad);
    on<NewsRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
      NewsLoadRequested event, Emitter<NewsState> emit) async {
    emit(NewsLoading());
    try {
      emit(_loaded(await _service.getWeatherNews()));
    } catch (e) {
      emit(NewsError('Failed to load news. Please try again.'));
    }
  }

  Future<void> _onRefresh(
      NewsRefreshRequested event, Emitter<NewsState> emit) async {
    try {
      emit(_loaded(await _service.getWeatherNews()));
    } catch (e) {
      // Keep showing what we already have rather than replacing it with an
      // error; only report failure if there is nothing on screen yet.
      if (state is! NewsLoaded) {
        emit(NewsError('Failed to refresh news.'));
      }
    }
  }

  NewsLoaded _loaded(NewsResult r) =>
      NewsLoaded(r.articles, fromCache: r.fromCache, cachedAt: r.cachedAt);
}
